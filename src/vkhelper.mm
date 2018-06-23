#include <QtCore/QByteArray>
#include <QtCore/QDateTime>
#include <QtCore/QStringList>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QRegExp>
#include <QtCore/QDebug>

#include "vkhelper.h"

const QString VKHelper::DEFAULT_PHOTO_URL        ("https://vk.com/images/camera_100.png");
const QString VKHelper::DATA_NOTE_TITLE          ("VKGeo Data");
const QString VKHelper::TRUSTED_FRIENDS_LIST_NAME("VKGeo Trusted Friends");
const QString VKHelper::TRACKED_FRIENDS_LIST_NAME("VKGeo Tracked Friends");

static NSArray *AUTH_SCOPE = @[ @"friends", @"notes", @"messages", @"groups", @"offline" ];

VKHelper *VKHelper::Instance = NULL;

@interface VKDelegate : NSObject<VKSdkDelegate, VKSdkUIDelegate>

- (id)init;
- (void)dealloc;

@end

@implementation VKDelegate

- (id)init
{
    self = [super init];

    if (self) {
        [[VKSdk instance] registerDelegate:self];
        [[VKSdk instance] setUiDelegate:self];

        [VKSdk wakeUpSession:AUTH_SCOPE completeBlock:^(VKAuthorizationState state, NSError *error) {
            if (error != nil) {
                qWarning() << QString::fromNSString([error localizedDescription]);

                VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
            } else if (state == VKAuthorizationAuthorized) {
                VKHelper::setAuthState(VKAuthState::StateAuthorized);
            } else {
                VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
            }
        }];
    }

    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result
{
    if (result.error != nil) {
        qWarning() << QString::fromNSString([result.error localizedDescription]);

        VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
    } else if (result.token != nil) {
        VKHelper::setAuthState(VKAuthState::StateAuthorized);
    } else {
        VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
    }
}

- (void)vkSdkUserAuthorizationFailed
{
    VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
}

- (void)vkSdkAuthorizationStateUpdatedWithResult:(VKAuthorizationResult *)result
{
    if (result.error != nil) {
        qWarning() << QString::fromNSString([result.error localizedDescription]);

        VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
    } else if (result.token != nil) {
        VKHelper::setAuthState(VKAuthState::StateAuthorized);
    } else {
        VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
    }
}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken
{
    Q_UNUSED(expiredToken)

    VKHelper::setAuthState(VKAuthState::StateNotAuthorized);
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{
    UIViewController * __block root_view_controller = nil;

    [[[UIApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
        root_view_controller = [window rootViewController];

        *stop = (root_view_controller != nil);
    }];

    if (root_view_controller != nil) {
        [root_view_controller presentViewController:controller animated:YES completion:nil];
    }
}

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError
{
    UIViewController * __block root_view_controller = nil;

    [[[UIApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
        root_view_controller = [window rootViewController];

        *stop = (root_view_controller != nil);
    }];

    if (root_view_controller != nil) {
        VKCaptchaViewController *captcha_view_controller = [VKCaptchaViewController captchaControllerWithError:captchaError];

        [captcha_view_controller presentIn:root_view_controller];
    }
}

@end

bool compareFriends(const QVariant &friend_1, const QVariant &friend_2)
{
    bool friend_1_trusted = friend_1.toMap().contains("trusted") ? (friend_1.toMap())["trusted"].toBool() : false;
    bool friend_2_trusted = friend_2.toMap().contains("trusted") ? (friend_2.toMap())["trusted"].toBool() : false;

    bool friend_1_tracked = friend_1.toMap().contains("tracked") ? (friend_1.toMap())["tracked"].toBool() : false;
    bool friend_2_tracked = friend_2.toMap().contains("tracked") ? (friend_2.toMap())["tracked"].toBool() : false;

    bool friend_1_online = friend_1.toMap().contains("online") ? (friend_1.toMap())["online"].toBool() : false;
    bool friend_2_online = friend_2.toMap().contains("online") ? (friend_2.toMap())["online"].toBool() : false;

    QString friend_1_name = friend_1.toMap().contains("firstName") &&
                            friend_1.toMap().contains("lastName") ?
                                QString("%1 %2").arg((friend_1.toMap())["firstName"].toString())
                                                .arg((friend_1.toMap())["lastName"].toString()) :
                                "";
    QString friend_2_name = friend_2.toMap().contains("firstName") &&
                            friend_2.toMap().contains("lastName") ?
                                QString("%1 %2").arg((friend_2.toMap())["firstName"].toString())
                                                .arg((friend_2.toMap())["lastName"].toString()) :
                                "";

    if (friend_1_trusted == friend_2_trusted) {
        if (friend_1_tracked == friend_2_tracked) {
            if (friend_1_online == friend_2_online) {
                return friend_1_name < friend_2_name;
            } else if (friend_1_online) {
                return true;
            } else {
                return false;
            }
        } else if (friend_1_tracked) {
            return true;
        } else {
            return false;
        }
    } else if (friend_1_trusted) {
        return true;
    } else {
        return false;
    }
}

VKHelper::VKHelper(QObject *parent) : QObject(parent)
{
    Initialized                           = false;
    AuthState                             = VKAuthState::StateUnknown;
    MaxTrustedFriendsCount                = DEFAULT_MAX_TRUSTED_FRIENDS_COUNT;
    MaxTrackedFriendsCount                = DEFAULT_MAX_TRACKED_FRIENDS_COUNT;
    LastReportLocationTime                = 0;
    LastUpdateTrackedFriendsLocationsTime = 0;
    PhotoUrl                              = DEFAULT_PHOTO_URL;
    BigPhotoUrl                           = DEFAULT_PHOTO_URL;
    Instance                              = this;
    VKDelegateInstance                    = NULL;
}

VKHelper::~VKHelper()
{
    if (Initialized) {
        [VKDelegateInstance release];
    }
}

bool VKHelper::locationValid() const
{
    return LastLocationInfo.contains("update_time") &&
           LastLocationInfo.contains("latitude") &&
           LastLocationInfo.contains("longitude");
}

qint64 VKHelper::locationUpdateTime() const
{
    if (LastLocationInfo.contains("update_time")) {
        return LastLocationInfo["update_time"].toLongLong();
    } else {
        return 0;
    }
}

qreal VKHelper::locationLatitude() const
{
    if (LastLocationInfo.contains("latitude")) {
        return LastLocationInfo["latitude"].toReal();
    } else {
        return 0.0;
    }
}

qreal VKHelper::locationLongitude() const
{
    if (LastLocationInfo.contains("longitude")) {
        return LastLocationInfo["longitude"].toReal();
    } else {
        return 0.0;
    }
}

int VKHelper::authState() const
{
    return AuthState;
}

int VKHelper::friendsCount() const
{
    return FriendsData.count();
}

QString VKHelper::userId() const
{
    return UserId;
}

QString VKHelper::firstName() const
{
    return FirstName;
}

QString VKHelper::lastName() const
{
    return LastName;
}

QString VKHelper::photoUrl() const
{
    return PhotoUrl;
}

QString VKHelper::bigPhotoUrl() const
{
    return BigPhotoUrl;
}

int VKHelper::maxTrustedFriendsCount() const
{
    return MaxTrustedFriendsCount;
}

void VKHelper::setMaxTrustedFriendsCount(int count)
{
    MaxTrustedFriendsCount = count;

    emit maxTrustedFriendsCountChanged(MaxTrustedFriendsCount);
}

int VKHelper::maxTrackedFriendsCount() const
{
    return MaxTrackedFriendsCount;
}

void VKHelper::setMaxTrackedFriendsCount(int count)
{
    MaxTrackedFriendsCount = count;

    emit maxTrackedFriendsCountChanged(MaxTrackedFriendsCount);
}

void VKHelper::initialize()
{
    if (!Initialized) {
        VKDelegateInstance = [[VKDelegate alloc] init];

        connect(&RequestQueueTimer, SIGNAL(timeout()), this, SLOT(RequestQueueTimerTimeout()));

        RequestQueueTimer.setInterval(REQUEST_QUEUE_TIMER_INTERVAL);
        RequestQueueTimer.start();

        connect(&ReportLocationTimer, SIGNAL(timeout()), this, SLOT(ReportLocationTimerTimeout()));

        ReportLocationTimer.setInterval(REPORT_LOCATION_TIMER_INTERVAL);
        ReportLocationTimer.start();

        Initialized = true;
    }
}

void VKHelper::cleanup()
{
    if (Initialized) {
        LastReportLocationTime                = 0;
        LastUpdateTrackedFriendsLocationsTime = 0;
        UserId                                = "";
        FirstName                             = "";
        LastName                              = "";
        PhotoUrl                              = DEFAULT_PHOTO_URL;
        BigPhotoUrl                           = DEFAULT_PHOTO_URL;
        TrustedFriendsListId                  = "";
        TrackedFriendsListId                  = "";

        emit userIdChanged(UserId);
        emit firstNameChanged(FirstName);
        emit lastNameChanged(LastName);
        emit photoUrlChanged(PhotoUrl);
        emit bigPhotoUrlChanged(BigPhotoUrl);

        while (!RequestQueue.isEmpty()) {
            QVariantMap request = RequestQueue.dequeue();

            ContextTrackerDelRequest(request);
        }

        foreach (VKBatchRequest *vk_batch_request, VKBatchRequestTracker.keys()) {
            [vk_batch_request cancel];
        }

        FriendsData.clear();
        FriendsDataTmp.clear();

        emit friendsCountChanged(FriendsData.count());
        emit friendsUpdated();
    }
}

void VKHelper::login()
{
    if (Initialized) {
        [VKSdk authorize:AUTH_SCOPE];
    }
}

void VKHelper::logout()
{
    if (Initialized) {
        [VKSdk forceLogout];

        setAuthState(VKAuthState::StateNotAuthorized);
    }
}

void VKHelper::updateLocation(qreal latitude, qreal longitude)
{
    LastLocationInfo["updated"]     = true;
    LastLocationInfo["update_time"] = QDateTime::currentSecsSinceEpoch();
    LastLocationInfo["latitude"]    = latitude;
    LastLocationInfo["longitude"]   = longitude;

    emit locationUpdated();
}

void VKHelper::reportLocation()
{
    ReportLocation(true);
}

void VKHelper::updateFriends()
{
    if (Initialized && !ContextHaveActiveRequests("updateFriends")) {
        QVariantMap request, parameters;

        FriendsDataTmp.clear();

        parameters["count"]  = MAX_FRIENDS_GET_COUNT;
        parameters["fields"] = "photo_100,photo_200,online,screen_name,last_seen,status";

        request["method"]     = "friends.get";
        request["context"]    = "updateFriends";
        request["parameters"] = parameters;

        EnqueueRequest(request);
    }
}

QVariantMap VKHelper::getFriends()
{
    if (Initialized) {
        return FriendsData;
    } else {
        return QVariantMap();
    }
}

QVariantList VKHelper::getFriendsList()
{
    if (Initialized) {
        QVariantList friends_list = FriendsData.values();

        std::sort(friends_list.begin(), friends_list.end(), compareFriends);

        return friends_list;
    } else {
        return QVariantList();
    }
}

void VKHelper::updateTrustedFriendsList(QVariantList trusted_friends_list)
{
    if (Initialized && !ContextHaveActiveRequests("updateTrustedFriendsList")) {
        QStringList user_id_list;

        foreach (QString key, FriendsData.keys()) {
            QVariantMap frnd = FriendsData[key].toMap();

            frnd["trusted"] = false;

            FriendsData[key] = frnd;
        }

        for (int i = 0; i < trusted_friends_list.count() && i < MaxTrustedFriendsCount; i++) {
            QString friend_id = trusted_friends_list[i].toString();

            user_id_list.append(friend_id);

            if (FriendsData.contains(friend_id)) {
                QVariantMap frnd = FriendsData[friend_id].toMap();

                frnd["trusted"] = true;
                frnd["tracked"] = false;

                FriendsData[friend_id] = frnd;
            }
        }

        QVariantMap request, parameters;

        if (TrustedFriendsListId == "") {
            request["method"]   = "friends.getLists";
            request["context"]  = "updateTrustedFriendsList";
            request["user_ids"] = user_id_list.join(",");
        } else {
            parameters["list_id"]  = TrustedFriendsListId.toInt();
            parameters["name"]     = TRUSTED_FRIENDS_LIST_NAME;
            parameters["user_ids"] = user_id_list.join(",");

            request["method"]     = "friends.editList";
            request["context"]    = "updateTrustedFriendsList";
            request["parameters"] = parameters;
        }

        EnqueueRequest(request);

        emit friendsUpdated();
    }
}

void VKHelper::updateTrackedFriendsList(QVariantList tracked_friends_list)
{
    if (Initialized && !ContextHaveActiveRequests("updateTrackedFriendsList")) {
        QStringList user_id_list;

        foreach (QString key, FriendsData.keys()) {
            QVariantMap frnd = FriendsData[key].toMap();

            frnd["tracked"] = false;

            FriendsData[key] = frnd;
        }

        for (int i = 0; i < tracked_friends_list.count() && i < MaxTrackedFriendsCount; i++) {
            QString friend_id = tracked_friends_list[i].toString();

            user_id_list.append(friend_id);

            if (FriendsData.contains(friend_id)) {
                QVariantMap frnd = FriendsData[friend_id].toMap();

                if (!frnd.contains("trusted") || !frnd["trusted"].toBool()) {
                    frnd["tracked"] = true;
                }

                FriendsData[friend_id] = frnd;
            }
        }

        QVariantMap request, parameters;

        if (TrackedFriendsListId == "") {
            request["method"]   = "friends.getLists";
            request["context"]  = "updateTrackedFriendsList";
            request["user_ids"] = user_id_list.join(",");
        } else {
            parameters["list_id"]  = TrackedFriendsListId.toInt();
            parameters["name"]     = TRACKED_FRIENDS_LIST_NAME;
            parameters["user_ids"] = user_id_list.join(",");

            request["method"]     = "friends.editList";
            request["context"]    = "updateTrackedFriendsList";
            request["parameters"] = parameters;
        }

        EnqueueRequest(request);

        emit friendsUpdated();
    }
}

void VKHelper::updateTrackedFriendsLocations(bool expedited)
{
    if (Initialized) {
        if (expedited || QDateTime::currentSecsSinceEpoch() > LastUpdateTrackedFriendsLocationsTime + UPDATE_TRACKED_FRIENDS_LOCATIONS_INTERVAL) {
            LastUpdateTrackedFriendsLocationsTime = QDateTime::currentSecsSinceEpoch();

            foreach (QString key, FriendsData.keys()) {
                QVariantMap frnd = FriendsData[key].toMap();

                if ((frnd.contains("trusted") && frnd["trusted"].toBool()) ||
                    (frnd.contains("tracked") && frnd["tracked"].toBool())) {
                    QVariantMap request, parameters;

                    parameters["count"]   = MAX_NOTES_GET_COUNT;
                    parameters["user_id"] = key.toInt();

                    request["method"]     = "notes.get";
                    request["context"]    = "updateTrackedFriendsLocations";
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                }
            }
        }
    }
}

void VKHelper::sendMessage(QString user_id, QString message)
{
    if (Initialized) {
        QVariantMap request, parameters;

        parameters["user_id"] = user_id.toInt();
        parameters["message"] = message;

        request["method"]     = "messages.send";
        request["context"]    = "sendMessage";
        request["parameters"] = parameters;

        EnqueueRequest(request);
    }
}

void VKHelper::sendInvitation(QString user_id, QString text)
{
    if (Initialized) {
        QVariantMap request, parameters;

        parameters["user_id"] = user_id.toInt();
        parameters["text"]    = text;
        parameters["type"]    = "invite";

        request["method"]     = "apps.sendRequest";
        request["context"]    = "sendInvitation";
        request["parameters"] = parameters;

        EnqueueRequest(request);
    }
}

void VKHelper::joinGroup(QString group_id)
{
    if (Initialized) {
        QVariantMap request, parameters;

        parameters["group_id"] = group_id.toInt();

        request["method"]     = "groups.join";
        request["context"]    = "joinGroup";
        request["parameters"] = parameters;

        EnqueueRequest(request);
    }
}

void VKHelper::setAuthState(int state)
{
    Instance->AuthState = state;

    emit Instance->authStateChanged(Instance->AuthState);

    if (Instance->AuthState == VKAuthState::StateAuthorized) {
        VKAccessToken *token = [VKSdk accessToken];

        if (token != nil && token.localUser != nil && token.localUser.id != nil) {
            Instance->UserId = QString::fromNSString([token.localUser.id stringValue]);
        } else {
            Instance->UserId = "";
        }

        emit Instance->userIdChanged(Instance->UserId);

        if (token != nil && token.localUser != nil && token.localUser.first_name != nil) {
            Instance->FirstName = QString::fromNSString(token.localUser.first_name);
        } else {
            Instance->FirstName = "";
        }

        emit Instance->firstNameChanged(Instance->FirstName);

        if (token != nil && token.localUser != nil && token.localUser.last_name != nil) {
            Instance->LastName = QString::fromNSString(token.localUser.last_name);
        } else {
            Instance->LastName = "";
        }

        emit Instance->lastNameChanged(Instance->LastName);

        if (token != nil && token.localUser != nil && token.localUser.photo_100 != nil) {
            Instance->PhotoUrl = QString::fromNSString(token.localUser.photo_100);
        } else {
            Instance->PhotoUrl = DEFAULT_PHOTO_URL;
        }

        emit Instance->photoUrlChanged(Instance->PhotoUrl);

        if (token != nil && token.localUser != nil && token.localUser.photo_200 != nil) {
            Instance->BigPhotoUrl = QString::fromNSString(token.localUser.photo_200);
        } else {
            Instance->BigPhotoUrl = DEFAULT_PHOTO_URL;
        }

        emit Instance->bigPhotoUrlChanged(Instance->BigPhotoUrl);
    } else if (Instance->AuthState == VKAuthState::StateNotAuthorized) {
        Instance->cleanup();
    }
}

void VKHelper::RequestQueueTimerTimeout()
{
    if (!RequestQueue.isEmpty()) {
        NSMutableArray *vk_request_array = [NSMutableArray arrayWithCapacity:MAX_BATCH_SIZE];

        for (int i = 0; i < MAX_BATCH_SIZE && !RequestQueue.isEmpty(); i++) {
            QVariantMap request = RequestQueue.dequeue();

            ContextTrackerDelRequest(request);

            if (AuthState == VKAuthState::StateAuthorized) {
                VKRequest *vk_request = ProcessRequest(request);

                if (vk_request != nil) {
                    [vk_request_array addObject:vk_request];
                }
            }
        }

        if (vk_request_array.count > 0) {
            VKBatchRequest *vk_batch_request = [[VKBatchRequest alloc] initWithRequestsArray:vk_request_array];

            VKBatchRequestTracker[vk_batch_request] = true;

            [vk_batch_request executeWithResultBlock:^(NSArray *responses) {
                Q_UNUSED(responses)

                if (VKBatchRequestTracker.contains(vk_batch_request)) {
                    VKBatchRequestTracker.remove(vk_batch_request);

                    [vk_batch_request autorelease];
                }
            } errorBlock:^(NSError *error) {
                Q_UNUSED(error)

                if (VKBatchRequestTracker.contains(vk_batch_request)) {
                    VKBatchRequestTracker.remove(vk_batch_request);

                    [vk_batch_request autorelease];
                }
            }];
        }
    }
}

void VKHelper::ReportLocationTimerTimeout()
{
    ReportLocation(false);
}

void VKHelper::ReportLocation(bool expedited)
{
    if (!ContextHaveActiveRequests("reportLocation")) {
        if (LastLocationInfo.contains("updated")  && LastLocationInfo.contains("update_time") &&
            LastLocationInfo.contains("latitude") && LastLocationInfo.contains("longitude")) {
            if (AuthState == VKAuthState::StateAuthorized) {
                if (LastLocationInfo["updated"].toBool()) {
                    if (expedited || QDateTime::currentSecsSinceEpoch() > LastReportLocationTime + REPORT_LOCATION_INTERVAL) {
                        LastReportLocationTime = QDateTime::currentSecsSinceEpoch();

                        QVariantMap request, user_data, parameters;

                        user_data["update_time"] = LastLocationInfo["update_time"].toLongLong();
                        user_data["latitude"]    = LastLocationInfo["latitude"].toReal();
                        user_data["longitude"]   = LastLocationInfo["longitude"].toReal();

                        QString user_data_string = QString("{{{%1}}}").arg(QString::fromUtf8(QJsonDocument::fromVariant(user_data)
                                                                                             .toJson(QJsonDocument::Compact)
                                                                                             .toBase64()));

                        if (TrustedFriendsListId == "") {
                            request["method"]    = "friends.getLists";
                            request["context"]   = "reportLocation";
                            request["user_data"] = user_data_string;
                        } else {
                            parameters["count"] = MAX_NOTES_GET_COUNT;

                            request["method"]     = "notes.get";
                            request["context"]    = "reportLocation";
                            request["user_data"]  = user_data_string;
                            request["parameters"] = parameters;
                        }

                        EnqueueRequest(request);

                        LastLocationInfo["updated"] = false;

                        emit locationReported();
                    }
                }
            }
        }
    }
}

void VKHelper::ContextTrackerAddRequest(QVariantMap request)
{
    if (request.contains("context")) {
        QString context = request["context"].toString();

        if (ContextTracker.contains(context)) {
            ContextTracker[context]++;
        } else {
            ContextTracker[context] = 1;
        }
    } else {
        qWarning() << "ContextTrackerAddRequest() : request have no context";
    }
}

void VKHelper::ContextTrackerDelRequest(QVariantMap request)
{
    if (request.contains("context")) {
        QString context = request["context"].toString();

        if (ContextTracker.contains(context)) {
            if (ContextTracker[context] > 0) {
                ContextTracker[context]--;
            } else {
                qWarning() << QString("ContextTrackerDelRequest() : negative tracker value for context: %1").arg(context);
            }
        } else {
            qWarning() << QString("ContextTrackerDelRequest() : no tracker value for context: %1").arg(context);
        }
    } else {
        qWarning() << "ContextTrackerDelRequest() : request have no context";
    }
}

bool VKHelper::ContextHaveActiveRequests(QString context)
{
    if (ContextTracker.contains(context) && ContextTracker[context] > 0) {
        return true;
    } else {
        return false;
    }
}

void VKHelper::EnqueueRequest(QVariantMap request)
{
    RequestQueue.enqueue(request);

    ContextTrackerAddRequest(request);
}

VKRequest *VKHelper::ProcessRequest(QVariantMap request)
{
    if (request.contains("method") && request.contains("context")) {
        NSMutableDictionary *vk_parameters = nil;

        if (request.contains("parameters")) {
            QVariantMap parameters = request["parameters"].toMap();

            vk_parameters = [NSMutableDictionary dictionaryWithCapacity:parameters.count()];

            foreach (QString key, parameters.keys()) {
                vk_parameters[key.toNSString()] = parameters[key].toString().toNSString();
            }
        } else {
            vk_parameters = [NSMutableDictionary dictionaryWithCapacity:0];
        }

        if (request["method"].toString() == "notes.get") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessNotesGetResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessNotesGetError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "notes.add") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessNotesAddResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessNotesAddError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "notes.delete") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessNotesDeleteResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessNotesDeleteError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "friends.get") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessFriendsGetResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessFriendsGetError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "friends.getLists") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessFriendsGetListsResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessFriendsGetListsError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "friends.addList") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessFriendsAddListResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessFriendsAddListError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "friends.editList") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessFriendsEditListResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessFriendsEditListError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "messages.send") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessMessagesSendResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessMessagesSendError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "apps.sendRequest") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessAppsSendRequestResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessAppsSendRequestError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else if (request["method"].toString() == "groups.join") {
            VKRequest *vk_request = [VKRequest requestWithMethod:request["method"].toString().toNSString() parameters:vk_parameters];

            vk_request.completeBlock = ^(VKResponse *response) {
                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessGroupsJoinResponse(QString::fromNSString(response.responseString), request);
                }
            };
            vk_request.errorBlock = ^(NSError *error) {
                qWarning() << QString("ProcessRequest() : %1 request failed : %2").arg(QString::fromNSString(vk_request.methodName))
                                                                                  .arg(QString::fromNSString([error localizedDescription]));

                if (VKRequestTracker.contains(vk_request)) {
                    VKRequestTracker.remove(vk_request);

                    ContextTrackerDelRequest(request);

                    ProcessGroupsJoinError(request);
                }
            };

            VKRequestTracker[vk_request] = true;

            ContextTrackerAddRequest(request);

            return vk_request;
        } else {
            qWarning() << QString("ProcessRequest() : unknown request method: %1").arg(request["method"].toString());

            return nil;
        }
    } else {
        qWarning() << "ProcessRequest() : invalid request";

        return nil;
    }
}

void VKHelper::ProcessNotesGetResponse(QString response, QVariantMap resp_request)
{
    if (resp_request["context"].toString() == "reportLocation") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("count") && json_response.contains("items")) {
                int         offset      = 0;
                int         notes_count = json_response.value("count").toInt();
                QStringList notes_to_delete;

                if (resp_request.contains("parameters") && resp_request["parameters"].toMap().contains("offset")) {
                    offset = (resp_request["parameters"].toMap())["offset"].toInt();
                }
                if (resp_request.contains("notes_to_delete")) {
                    notes_to_delete = resp_request["notes_to_delete"].toString().split(",");
                }

                QJsonArray json_items = json_response.value("items").toArray();

                for (int i = 0; i < json_items.count(); i++) {
                    QJsonObject json_note = json_items.at(i).toObject();

                    if (json_note.contains("id") && json_note.contains("title")) {
                        if (json_note.value("title").toString() == DATA_NOTE_TITLE) {
                            QString data_note_id = QString::number(json_note.value("id").toInt());

                            if (data_note_id != "") {
                                notes_to_delete.append(data_note_id);
                            }
                        }
                    }
                }

                if (resp_request.contains("user_data")) {
                    if (offset + json_items.count() < notes_count) {
                        QVariantMap request, parameters;

                        parameters["count"]  = MAX_NOTES_GET_COUNT;
                        parameters["offset"] = offset + json_items.count();

                        request["method"]     = "notes.get";
                        request["context"]    = resp_request["context"].toString();
                        request["user_data"]  = resp_request["user_data"].toString();

                        if (notes_to_delete.count() > 0) {
                            request["notes_to_delete"] = notes_to_delete.join(",");
                        }

                        request["parameters"] = parameters;

                        EnqueueRequest(request);
                    } else {
                        for (int i = 0; i < notes_to_delete.count(); i++) {
                            QVariantMap request, parameters;

                            parameters["note_id"] = notes_to_delete[i].toInt();

                            request["method"]     = "notes.delete";
                            request["context"]    = resp_request["context"].toString();
                            request["parameters"] = parameters;

                            EnqueueRequest(request);
                        }

                        QVariantMap request, parameters;

                        parameters["title"]           = DATA_NOTE_TITLE;
                        parameters["text"]            = resp_request["user_data"].toString();
                        parameters["privacy_comment"] = "nobody";

                        if (TrustedFriendsListId == "") {
                            parameters["privacy_view"] = "nobody";
                        } else {
                            parameters["privacy_view"] = QString("list%1").arg(TrustedFriendsListId);
                        }

                        request["method"]     = "notes.add";
                        request["context"]    = resp_request["context"].toString();
                        request["parameters"] = parameters;

                        EnqueueRequest(request);
                    }
                } else {
                    qWarning() << "ProcessNotesGetResponse() : invalid request";
                }
            } else {
                qWarning() << "ProcessNotesGetResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessNotesGetResponse() : invalid json";
        }
    } else if (resp_request["context"].toString() == "updateTrackedFriendsLocations") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("count") && json_response.contains("items")) {
                bool data_note_found = false;

                int     offset      = 0;
                int     notes_count = json_response.value("count").toInt();
                QString user_id;

                if (resp_request.contains("parameters") && resp_request["parameters"].toMap().contains("offset")) {
                    offset = (resp_request["parameters"].toMap())["offset"].toInt();
                }
                if (resp_request.contains("parameters") && resp_request["parameters"].toMap().contains("user_id")) {
                    user_id = (resp_request["parameters"].toMap())["user_id"].toString();
                }

                QJsonArray json_items = json_response.value("items").toArray();

                for (int i = 0; i < json_items.count(); i++) {
                    QJsonObject json_note = json_items.at(i).toObject();

                    if (json_note.contains("title") && json_note.contains("text")) {
                        if (json_note.value("title").toString() == DATA_NOTE_TITLE) {
                            data_note_found = true;

                            if (user_id != "") {
                                QString note_text = json_note.value("text").toString();
                                QRegExp base64_regexp("\\{\\{\\{([^\\}]+)\\}\\}\\}");

                                if (base64_regexp.indexIn(note_text) != -1) {
                                    QString note_base64 = base64_regexp.cap(1);

                                    QVariantMap user_data = QJsonDocument::fromJson(QByteArray::fromBase64(note_base64.toUtf8())).toVariant().toMap();

                                    if (user_data.contains("update_time") && user_data.contains("latitude") &&
                                                                             user_data.contains("longitude")) {
                                        emit trackedFriendLocationUpdated(user_id, user_data["update_time"].toLongLong(),
                                                                                   user_data["latitude"].toReal(),
                                                                                   user_data["longitude"].toReal());
                                    } else {
                                        qWarning() << "ProcessNotesGetResponse() : invalid user data";
                                    }
                                } else {
                                    qWarning() << "ProcessNotesGetResponse() : invalid user data";
                                }
                            } else {
                                qWarning() << "ProcessNotesGetResponse() : invalid request";
                            }

                            break;
                        }
                    }
                }

                if (!data_note_found) {
                    if (user_id != "") {
                        if (offset + json_items.count() < notes_count) {
                            QVariantMap request, parameters;

                            parameters["count"]   = MAX_NOTES_GET_COUNT;
                            parameters["offset"]  = offset + json_items.count();
                            parameters["user_id"] = user_id.toInt();

                            request["method"]     = "notes.get";
                            request["context"]    = resp_request["context"].toString();
                            request["user_data"]  = resp_request["user_data"].toString();
                            request["parameters"] = parameters;

                            EnqueueRequest(request);
                        }
                    } else {
                        qWarning() << "ProcessNotesGetResponse() : invalid request";
                    }
                }
            } else {
                qWarning() << "ProcessNotesGetResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessNotesGetResponse() : invalid json";
        }
    }
}

void VKHelper::ProcessNotesGetError(QVariantMap err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::ProcessNotesAddResponse(QString response, QVariantMap resp_request)
{
    Q_UNUSED(response)
    Q_UNUSED(resp_request)
}

void VKHelper::ProcessNotesAddError(QVariantMap err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::ProcessNotesDeleteResponse(QString response, QVariantMap resp_request)
{
    Q_UNUSED(response)
    Q_UNUSED(resp_request)
}

void VKHelper::ProcessNotesDeleteError(QVariantMap err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::ProcessFriendsGetResponse(QString response, QVariantMap resp_request)
{
    if (resp_request["context"].toString() == "updateFriends") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("count") && json_response.contains("items")) {
                int     offset        = 0;
                int     friends_count = json_response.value("count").toInt();
                QString fields, list_id;

                if (resp_request.contains("parameters") && resp_request["parameters"].toMap().contains("offset")) {
                    offset = (resp_request["parameters"].toMap())["offset"].toInt();
                }
                if (resp_request.contains("parameters") && resp_request["parameters"].toMap().contains("fields")) {
                    fields = (resp_request["parameters"].toMap())["fields"].toString();
                }
                if (resp_request.contains("parameters") && resp_request["parameters"].toMap().contains("list_id")) {
                    list_id = (resp_request["parameters"].toMap())["list_id"].toString();
                }

                QJsonArray json_items = json_response.value("items").toArray();

                if (list_id == "") {
                    for (int i = 0; i < json_items.count(); i++) {
                        QJsonObject json_friend = json_items.at(i).toObject();

                        if (json_friend.contains("id")) {
                            if (!json_friend.contains("deactivated")) {
                                QVariantMap frnd;

                                frnd["userId"]  = QString::number(json_friend.value("id").toInt());
                                frnd["trusted"] = false;
                                frnd["tracked"] = false;

                                if (json_friend.contains("first_name")) {
                                    frnd["firstName"] = json_friend.value("first_name").toString();
                                } else {
                                    frnd["firstName"] = "";
                                }
                                if (json_friend.contains("last_name")) {
                                    frnd["lastName"] = json_friend.value("last_name").toString();
                                } else {
                                    frnd["lastName"] = "";
                                }
                                if (json_friend.contains("photo_100")) {
                                    frnd["photoUrl"] = json_friend.value("photo_100").toString();
                                } else {
                                    frnd["photoUrl"] = DEFAULT_PHOTO_URL;
                                }
                                if (json_friend.contains("photo_200")) {
                                    frnd["bigPhotoUrl"] = json_friend.value("photo_200").toString();
                                } else {
                                    frnd["bigPhotoUrl"] = DEFAULT_PHOTO_URL;
                                }
                                if (json_friend.contains("online")) {
                                    frnd["online"] = json_friend.value("online").toInt() ? true : false;
                                } else {
                                    frnd["online"] = false;
                                }
                                if (json_friend.contains("screen_name")) {
                                    frnd["screenName"] = json_friend.value("screen_name").toString();
                                } else {
                                    frnd["screenName"] = QString("id%1").arg(frnd["userId"].toString());
                                }
                                if (json_friend.contains("status")) {
                                    frnd["status"] = json_friend.value("status").toString();
                                } else {
                                    frnd["status"] = "";
                                }
                                if (json_friend.contains("last_seen")) {
                                    QJsonObject json_last_seen = json_friend.value("last_seen").toObject();

                                    if (json_last_seen.contains("time")) {
                                        frnd["lastSeenTime"] = QString::number(json_last_seen["time"].toInt());
                                    } else {
                                        frnd["lastSeenTime"] = "";
                                    }
                                } else {
                                    frnd["lastSeenTime"] = "";
                                }

                                FriendsDataTmp[frnd["userId"].toString()] = frnd;
                            }
                        } else {
                            qWarning() << "ProcessFriendsGetResponse() : invalid entry";
                        }
                    }
                } else if (list_id == TrustedFriendsListId) {
                    for (int i = 0; i < json_items.count() && offset + i < MaxTrustedFriendsCount; i++) {
                        QString friend_id = QString::number(json_items.at(i).toInt());

                        if (FriendsDataTmp.contains(friend_id)) {
                            QVariantMap frnd = FriendsDataTmp[friend_id].toMap();

                            frnd["trusted"] = true;
                            frnd["tracked"] = false;

                            FriendsDataTmp[friend_id] = frnd;
                        }
                    }
                } else if (list_id == TrackedFriendsListId) {
                    for (int i = 0; i < json_items.count() && offset + i < MaxTrackedFriendsCount; i++) {
                        QString friend_id = QString::number(json_items.at(i).toInt());

                        if (FriendsDataTmp.contains(friend_id)) {
                            QVariantMap frnd = FriendsDataTmp[friend_id].toMap();

                            if (!frnd.contains("trusted") || !frnd["trusted"].toBool()) {
                                frnd["tracked"] = true;
                            }

                            FriendsDataTmp[friend_id] = frnd;
                        }
                    }
                } else {
                    qWarning() << "ProcessFriendsGetResponse() : unknown list id";
                }

                if (offset + json_items.count() < friends_count) {
                    QVariantMap request, parameters;

                    parameters["count"]  = MAX_FRIENDS_GET_COUNT;
                    parameters["offset"] = offset + json_items.count();

                    if (fields != "") {
                        parameters["fields"] = fields;
                    }
                    if (list_id != "") {
                        parameters["list_id"] = list_id.toInt();
                    }

                    request["method"]     = "friends.get";
                    request["context"]    = resp_request["context"].toString();
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                } else if (list_id == "") {
                    QVariantMap request;

                    request["method"]  = "friends.getLists";
                    request["context"] = resp_request["context"].toString();

                    EnqueueRequest(request);
                }
            } else {
                qWarning() << "ProcessFriendsGetResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessFriendsGetResponse() : invalid json";
        }

        if (!ContextHaveActiveRequests(resp_request["context"].toString())) {
            FriendsData = FriendsDataTmp;

            emit friendsCountChanged(FriendsData.count());
            emit friendsUpdated();
        }
    }
}

void VKHelper::ProcessFriendsGetError(QVariantMap err_request)
{
    if (err_request["context"].toString() == "updateFriends") {
        if (!ContextHaveActiveRequests(err_request["context"].toString())) {
            FriendsData = FriendsDataTmp;

            emit friendsCountChanged(FriendsData.count());
            emit friendsUpdated();
        }
    }
}

void VKHelper::ProcessFriendsGetListsResponse(QString response, QVariantMap resp_request)
{
    if (resp_request["context"].toString() == "reportLocation") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("count") && json_response.contains("items")) {
                QString trusted_friends_list_id, tracked_friends_list_id;

                QJsonArray json_items = json_response.value("items").toArray();

                for (int i = 0; i < json_items.count(); i++) {
                    QJsonObject json_list = json_items.at(i).toObject();

                    if (json_list.contains("id") && json_list.contains("name")) {
                        if (json_list.value("name").toString() == TRUSTED_FRIENDS_LIST_NAME) {
                            trusted_friends_list_id = QString::number(json_list.value("id").toInt());
                        } else if (json_list.value("name").toString() == TRACKED_FRIENDS_LIST_NAME) {
                            tracked_friends_list_id = QString::number(json_list.value("id").toInt());
                        }

                        if (trusted_friends_list_id != "" && tracked_friends_list_id != "") {
                            break;
                        }
                    }
                }

                if (resp_request.contains("user_data")) {
                    if (trusted_friends_list_id != "") {
                        TrustedFriendsListId = trusted_friends_list_id;
                    }
                    if (tracked_friends_list_id != "") {
                        TrackedFriendsListId = tracked_friends_list_id;
                    }

                    QVariantMap request, parameters;

                    parameters["count"] = MAX_NOTES_GET_COUNT;

                    request["method"]     = "notes.get";
                    request["context"]    = resp_request["context"].toString();
                    request["user_data"]  = resp_request["user_data"].toString();
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                } else {
                    qWarning() << "ProcessFriendsGetListsResponse() : invalid request";
                }
            } else {
                qWarning() << "ProcessFriendsGetListsResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessFriendsGetListsResponse() : invalid json";
        }
    } if (resp_request["context"].toString() == "updateFriends") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("count") && json_response.contains("items")) {
                QString trusted_friends_list_id, tracked_friends_list_id;

                QJsonArray json_items = json_response.value("items").toArray();

                for (int i = 0; i < json_items.count(); i++) {
                    QJsonObject json_list = json_items.at(i).toObject();

                    if (json_list.contains("id") && json_list.contains("name")) {
                        if (json_list.value("name").toString() == TRUSTED_FRIENDS_LIST_NAME) {
                            trusted_friends_list_id = QString::number(json_list.value("id").toInt());
                        } else if (json_list.value("name").toString() == TRACKED_FRIENDS_LIST_NAME) {
                            tracked_friends_list_id = QString::number(json_list.value("id").toInt());
                        }

                        if (trusted_friends_list_id != "" && tracked_friends_list_id != "") {
                            break;
                        }
                    }
                }

                if (trusted_friends_list_id != "") {
                    TrustedFriendsListId = trusted_friends_list_id;

                    QVariantMap request, parameters;

                    parameters["count"]   = MAX_FRIENDS_GET_COUNT;
                    parameters["list_id"] = TrustedFriendsListId.toInt();

                    request["method"]     = "friends.get";
                    request["context"]    = resp_request["context"].toString();
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                }
                if (tracked_friends_list_id != "") {
                    TrackedFriendsListId = tracked_friends_list_id;

                    QVariantMap request, parameters;

                    parameters["count"]   = MAX_FRIENDS_GET_COUNT;
                    parameters["list_id"] = TrackedFriendsListId.toInt();

                    request["method"]     = "friends.get";
                    request["context"]    = resp_request["context"].toString();
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                }
            } else {
                qWarning() << "ProcessFriendsGetListsResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessFriendsGetListsResponse() : invalid json";
        }

        if (!ContextHaveActiveRequests(resp_request["context"].toString())) {
            FriendsData = FriendsDataTmp;

            emit friendsCountChanged(FriendsData.count());
            emit friendsUpdated();
        }
    } else if (resp_request["context"].toString() == "updateTrustedFriendsList") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("count") && json_response.contains("items")) {
                QString trusted_friends_list_id;

                QJsonArray json_items = json_response.value("items").toArray();

                for (int i = 0; i < json_items.count(); i++) {
                    QJsonObject json_list = json_items.at(i).toObject();

                    if (json_list.contains("id") && json_list.contains("name")) {
                        if (json_list.value("name").toString() == TRUSTED_FRIENDS_LIST_NAME) {
                            trusted_friends_list_id = QString::number(json_list.value("id").toInt());

                            if (trusted_friends_list_id != "") {
                                break;
                            }
                        }
                    }
                }

                if (resp_request.contains("user_ids")) {
                    QVariantMap request, parameters;

                    if (trusted_friends_list_id != "") {
                        TrustedFriendsListId = trusted_friends_list_id;

                        parameters["list_id"]  = TrustedFriendsListId.toInt();
                        parameters["name"]     = TRUSTED_FRIENDS_LIST_NAME;
                        parameters["user_ids"] = resp_request["user_ids"].toString();

                        request["method"]     = "friends.editList";
                        request["context"]    = resp_request["context"].toString();
                        request["parameters"] = parameters;
                    } else {
                        parameters["name"]     = TRUSTED_FRIENDS_LIST_NAME;
                        parameters["user_ids"] = resp_request["user_ids"].toString();

                        request["method"]     = "friends.addList";
                        request["context"]    = resp_request["context"].toString();
                        request["parameters"] = parameters;
                    }

                    EnqueueRequest(request);
                } else {
                    qWarning() << "ProcessFriendsGetListsResponse() : invalid request";
                }
            } else {
                qWarning() << "ProcessFriendsGetListsResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessFriendsGetListsResponse() : invalid json";
        }
    } else if (resp_request["context"].toString() == "updateTrackedFriendsList") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("count") && json_response.contains("items")) {
                QString tracked_friends_list_id;

                QJsonArray json_items = json_response.value("items").toArray();

                for (int i = 0; i < json_items.count(); i++) {
                    QJsonObject json_list = json_items.at(i).toObject();

                    if (json_list.contains("id") && json_list.contains("name")) {
                        if (json_list.value("name").toString() == TRACKED_FRIENDS_LIST_NAME) {
                            tracked_friends_list_id = QString::number(json_list.value("id").toInt());

                            if (tracked_friends_list_id != "") {
                                break;
                            }
                        }
                    }
                }

                if (resp_request.contains("user_ids")) {
                    QVariantMap request, parameters;

                    if (tracked_friends_list_id != "") {
                        TrackedFriendsListId = tracked_friends_list_id;

                        parameters["list_id"]  = TrackedFriendsListId.toInt();
                        parameters["name"]     = TRACKED_FRIENDS_LIST_NAME;
                        parameters["user_ids"] = resp_request["user_ids"].toString();

                        request["method"]     = "friends.editList";
                        request["context"]    = resp_request["context"].toString();
                        request["parameters"] = parameters;
                    } else {
                        parameters["name"]     = TRACKED_FRIENDS_LIST_NAME;
                        parameters["user_ids"] = resp_request["user_ids"].toString();

                        request["method"]     = "friends.addList";
                        request["context"]    = resp_request["context"].toString();
                        request["parameters"] = parameters;
                    }

                    EnqueueRequest(request);
                } else {
                    qWarning() << "ProcessFriendsGetListsResponse() : invalid request";
                }
            } else {
                qWarning() << "ProcessFriendsGetListsResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessFriendsGetListsResponse() : invalid json";
        }
    }
}

void VKHelper::ProcessFriendsGetListsError(QVariantMap err_request)
{
    if (err_request["context"].toString() == "updateFriends") {
        if (!ContextHaveActiveRequests(err_request["context"].toString())) {
            FriendsData = FriendsDataTmp;

            emit friendsCountChanged(FriendsData.count());
            emit friendsUpdated();
        }
    }
}

void VKHelper::ProcessFriendsAddListResponse(QString response, QVariantMap resp_request)
{
    if (resp_request["context"].toString() == "updateTrustedFriendsList") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("list_id")) {
                TrustedFriendsListId = QString::number(json_response.value("list_id").toInt());
            } else {
                qWarning() << "ProcessFriendsAddListResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessFriendsAddListResponse() : invalid json";
        }
    } else if (resp_request["context"].toString() == "updateTrackedFriendsList") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("list_id")) {
                TrackedFriendsListId = QString::number(json_response.value("list_id").toInt());
            } else {
                qWarning() << "ProcessFriendsAddListResponse() : invalid response";
            }
        } else {
            qWarning() << "ProcessFriendsAddListResponse() : invalid json";
        }
    }
}

void VKHelper::ProcessFriendsAddListError(QVariantMap err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::ProcessFriendsEditListResponse(QString response, QVariantMap resp_request)
{
    Q_UNUSED(response)
    Q_UNUSED(resp_request)
}

void VKHelper::ProcessFriendsEditListError(QVariantMap err_request)
{
    if (err_request["context"].toString() == "updateTrustedFriendsList") {
        TrustedFriendsListId = "";
    } else if (err_request["context"].toString() == "updateTrackedFriendsList") {
        TrackedFriendsListId = "";
    }
}

void VKHelper::ProcessMessagesSendResponse(QString response, QVariantMap resp_request)
{
    Q_UNUSED(response)
    Q_UNUSED(resp_request)
}

void VKHelper::ProcessMessagesSendError(QVariantMap err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::ProcessAppsSendRequestResponse(QString response, QVariantMap resp_request)
{
    Q_UNUSED(response)
    Q_UNUSED(resp_request)
}

void VKHelper::ProcessAppsSendRequestError(QVariantMap err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::ProcessGroupsJoinResponse(QString response, QVariantMap resp_request)
{
    Q_UNUSED(response)
    Q_UNUSED(resp_request)
}

void VKHelper::ProcessGroupsJoinError(QVariantMap err_request)
{
    Q_UNUSED(err_request)
}
