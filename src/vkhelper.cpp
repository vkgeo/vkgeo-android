#include <algorithm>

#include <QtCore/QLatin1String>
#include <QtCore/QByteArray>
#include <QtCore/QDateTime>
#include <QtCore/QVariant>
#include <QtCore/QStringList>
#include <QtCore/QJsonValue>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QRegExp>
#include <QtCore/QDebug>
#include <QtAndroidExtras/QtAndroid>

#include "cryptohelper.h"

#include "vkhelper.h"

const QString VKHelper::AUTH_SCOPE               (QStringLiteral("[\"friends\", \"notes\", \"groups\", \"offline\"]"));
const QString VKHelper::DEFAULT_PHOTO_URL        (QStringLiteral("https://vk.com/images/camera_100.png"));
const QString VKHelper::DATA_NOTE_TITLE          (QStringLiteral("VKGeo Data"));
const QString VKHelper::TRUSTED_FRIENDS_LIST_NAME(QStringLiteral("VKGeo Trusted Friends"));
const QString VKHelper::TRACKED_FRIENDS_LIST_NAME(QStringLiteral("VKGeo Tracked Friends"));
const QString VKHelper::ENCRYPTED_PAYLOAD_COOKIE (QStringLiteral("VKGeo Payload Cookie"));

QAndroidJniObject VKHelper::AndroidContext;

namespace {

bool compareFriends(const QVariant &friend_1, const QVariant &friend_2)
{
    bool friend_1_trusted = friend_1.toMap().contains(QStringLiteral("trusted")) ? (friend_1.toMap())[QStringLiteral("trusted")].toBool() : false;
    bool friend_2_trusted = friend_2.toMap().contains(QStringLiteral("trusted")) ? (friend_2.toMap())[QStringLiteral("trusted")].toBool() : false;

    bool friend_1_tracked = friend_1.toMap().contains(QStringLiteral("tracked")) ? (friend_1.toMap())[QStringLiteral("tracked")].toBool() : false;
    bool friend_2_tracked = friend_2.toMap().contains(QStringLiteral("tracked")) ? (friend_2.toMap())[QStringLiteral("tracked")].toBool() : false;

    bool friend_1_online = friend_1.toMap().contains(QStringLiteral("online")) ? (friend_1.toMap())[QStringLiteral("online")].toBool() : false;
    bool friend_2_online = friend_2.toMap().contains(QStringLiteral("online")) ? (friend_2.toMap())[QStringLiteral("online")].toBool() : false;

    QString friend_1_name = friend_1.toMap().contains(QStringLiteral("firstName")) &&
                            friend_1.toMap().contains(QStringLiteral("lastName")) ?
                                QStringLiteral("%1 %2").arg((friend_1.toMap())[QStringLiteral("firstName")].toString(),
                                                            (friend_1.toMap())[QStringLiteral("lastName")].toString()) :
                                QLatin1String("");
    QString friend_2_name = friend_2.toMap().contains(QStringLiteral("firstName")) &&
                            friend_2.toMap().contains(QStringLiteral("lastName")) ?
                                QStringLiteral("%1 %2").arg((friend_2.toMap())[QStringLiteral("firstName")].toString(),
                                                            (friend_2.toMap())[QStringLiteral("lastName")].toString()) :
                                QLatin1String("");

    if (friend_1_trusted == friend_2_trusted) {
        if (friend_1_tracked == friend_2_tracked) {
            if (friend_1_online == friend_2_online) {
                return friend_1_name < friend_2_name;
            } else {
                return friend_1_online;
            }
        } else {
            return friend_1_tracked;
        }
    } else {
        return friend_1_trusted;
    }
}

}

VKHelper::VKHelper(QObject *parent) :
    QObject                         (parent),
    EncryptionEnabled               (false),
    CurrentDataState                (StateNoNewData),
    AuthState                       (VKAuthState::StateUnknown),
    MaxTrustedFriendsCount          (0),
    MaxTrackedFriendsCount          (0),
    LastSendDataTime                (0),
    LastUpdateTrackedFriendsDataTime(0),
    NextRequestQueueTimerTimeout    (0),
    PhotoUrl                        (DEFAULT_PHOTO_URL),
    BigPhotoUrl                     (DEFAULT_PHOTO_URL)
{
    connect(&RequestQueueTimer, &QTimer::timeout, this, &VKHelper::handleRequestQueueTimerTimeout);

    RequestQueueTimer.setInterval(REQUEST_QUEUE_TIMER_INTERVAL);

    connect(&SendDataOnUpdateTimer, &QTimer::timeout, this, &VKHelper::handleSendDataTimerTimeout);

    SendDataOnUpdateTimer.setInterval(SEND_DATA_ON_UPDATE_TIMER_INTERVAL);
    SendDataOnUpdateTimer.setSingleShot(true);

    connect(&SendDataTimer, &QTimer::timeout, this, &VKHelper::handleSendDataTimerTimeout);

    SendDataTimer.setInterval(SEND_DATA_TIMER_INTERVAL);
}

VKHelper &VKHelper::GetInstance()
{
    static VKHelper instance;

    return instance;
}

bool VKHelper::locationValid() const
{
    return CurrentData.contains(QStringLiteral("update_time")) &&
           CurrentData.contains(QStringLiteral("latitude")) &&
           CurrentData.contains(QStringLiteral("longitude"));
}

qint64 VKHelper::updateTime() const
{
    if (CurrentData.contains(QStringLiteral("update_time"))) {
        return CurrentData[QStringLiteral("update_time")].toLongLong();
    } else {
        return 0;
    }
}

qreal VKHelper::latitude() const
{
    if (CurrentData.contains(QStringLiteral("latitude"))) {
        return CurrentData[QStringLiteral("latitude")].toDouble();
    } else {
        return 0.0;
    }
}

qreal VKHelper::longitude() const
{
    if (CurrentData.contains(QStringLiteral("longitude"))) {
        return CurrentData[QStringLiteral("longitude")].toDouble();
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

bool VKHelper::encryptionEnabled() const
{
    return EncryptionEnabled;
}

void VKHelper::setEncryptionEnabled(bool enabled)
{
    if (EncryptionEnabled != enabled) {
        EncryptionEnabled = enabled;

        emit encryptionEnabledChanged(EncryptionEnabled);
    }
}

int VKHelper::maxTrustedFriendsCount() const
{
    return MaxTrustedFriendsCount;
}

void VKHelper::setMaxTrustedFriendsCount(int count)
{
    if (MaxTrustedFriendsCount != count) {
        MaxTrustedFriendsCount = count;

        emit maxTrustedFriendsCountChanged(MaxTrustedFriendsCount);
    }
}

int VKHelper::maxTrackedFriendsCount() const
{
    return MaxTrackedFriendsCount;
}

void VKHelper::setMaxTrackedFriendsCount(int count)
{
    if (MaxTrackedFriendsCount != count) {
        MaxTrackedFriendsCount = count;

        emit maxTrackedFriendsCountChanged(MaxTrackedFriendsCount);
    }
}

void VKHelper::initVK() const
{
    AndroidContext.callMethod<void>("initVK");
}

void VKHelper::login() const
{
    QAndroidJniObject j_auth_scope = QAndroidJniObject::fromString(AUTH_SCOPE);

    AndroidContext.callMethod<void>("loginVK", "(Ljava/lang/String;)V", j_auth_scope.object<jstring>());
}

void VKHelper::logout()
{
    AndroidContext.callMethod<void>("logoutVK");

    setAuthState(VKAuthState::StateNotAuthorized);
}

void VKHelper::updateLocation(qreal latitude, qreal longitude)
{
    CurrentDataState                           = StateNewDataArrived;
    CurrentData[QStringLiteral("update_time")] = QDateTime::currentSecsSinceEpoch();
    CurrentData[QStringLiteral("latitude")]    = latitude;
    CurrentData[QStringLiteral("longitude")]   = longitude;

    emit locationUpdated();

    SendDataOnUpdateTimer.start();
}

void VKHelper::updateBatteryStatus(const QString &status, int level)
{
    CurrentDataState                              = StateNewDataArrived;
    CurrentData[QStringLiteral("update_time")]    = QDateTime::currentSecsSinceEpoch();
    CurrentData[QStringLiteral("battery_status")] = status;
    CurrentData[QStringLiteral("battery_level")]  = level;

    emit batteryStatusUpdated();

    SendDataOnUpdateTimer.start();
}

void VKHelper::sendDataImmediately()
{
    SendData();
}

void VKHelper::updateFriends()
{
    if (!ContextHasActiveRequests(QStringLiteral("updateFriends"))) {
        QVariantMap request, parameters;

        FriendsDataTmp.clear();

        parameters[QStringLiteral("count")]  = MAX_FRIENDS_GET_COUNT;
        parameters[QStringLiteral("fields")] = QStringLiteral("photo_100,photo_200,online,screen_name,last_seen,status");

        request[QStringLiteral("method")]     = QStringLiteral("friends.get");
        request[QStringLiteral("context")]    = QStringLiteral("updateFriends");
        request[QStringLiteral("parameters")] = parameters;

        EnqueueRequest(request);
    }
}

QVariantMap VKHelper::getFriends() const
{
    return FriendsData;
}

QVariantList VKHelper::getFriendsList() const
{
    QVariantList friends_list = FriendsData.values();

    std::sort(friends_list.begin(), friends_list.end(), compareFriends);

    return friends_list;
}

void VKHelper::updateTrustedFriendsList(const QVariantList &trusted_friends_list)
{
    if (!ContextHasActiveRequests(QStringLiteral("updateTrustedFriendsList"))) {
        for (const QString &key : FriendsData.keys()) {
            QVariantMap frnd = FriendsData[key].toMap();

            frnd[QStringLiteral("trusted")] = false;

            FriendsData[key] = frnd;
        }

        QStringList user_id_list;

        for (int i = 0; i < trusted_friends_list.count() && i < MaxTrustedFriendsCount; i++) {
            QString user_id = trusted_friends_list[i].toString();

            user_id_list.append(user_id);

            if (FriendsData.contains(user_id)) {
                QVariantMap frnd = FriendsData[user_id].toMap();

                frnd[QStringLiteral("trusted")] = true;
                frnd[QStringLiteral("tracked")] = false;

                FriendsData[user_id] = frnd;
            }
        }

        QVariantMap request, parameters;

        if (TrustedFriendsListId == QLatin1String("")) {
            request[QStringLiteral("method")]   = QStringLiteral("friends.getLists");
            request[QStringLiteral("context")]  = QStringLiteral("updateTrustedFriendsList");
            request[QStringLiteral("user_ids")] = user_id_list.join(QStringLiteral(","));
        } else {
            parameters[QStringLiteral("list_id")]  = TrustedFriendsListId.toLongLong();
            parameters[QStringLiteral("name")]     = TRUSTED_FRIENDS_LIST_NAME;
            parameters[QStringLiteral("user_ids")] = user_id_list.join(QStringLiteral(","));

            request[QStringLiteral("method")]     = QStringLiteral("friends.editList");
            request[QStringLiteral("context")]    = QStringLiteral("updateTrustedFriendsList");
            request[QStringLiteral("parameters")] = parameters;
        }

        EnqueueRequest(request);

        emit friendsUpdated();
    }
}

void VKHelper::updateTrackedFriendsList(const QVariantList &tracked_friends_list)
{
    if (!ContextHasActiveRequests(QStringLiteral("updateTrackedFriendsList"))) {
        for (const QString &key : FriendsData.keys()) {
            QVariantMap frnd = FriendsData[key].toMap();

            frnd[QStringLiteral("tracked")] = false;

            FriendsData[key] = frnd;
        }

        QStringList user_id_list;

        for (int i = 0; i < tracked_friends_list.count() && i < MaxTrackedFriendsCount; i++) {
            QString user_id = tracked_friends_list[i].toString();

            user_id_list.append(user_id);

            if (FriendsData.contains(user_id)) {
                QVariantMap frnd = FriendsData[user_id].toMap();

                if (!frnd.contains(QStringLiteral("trusted")) || !frnd[QStringLiteral("trusted")].toBool()) {
                    frnd[QStringLiteral("tracked")] = true;
                }

                FriendsData[user_id] = frnd;
            }
        }

        QVariantMap request, parameters;

        if (TrackedFriendsListId == QLatin1String("")) {
            request[QStringLiteral("method")]   = QStringLiteral("friends.getLists");
            request[QStringLiteral("context")]  = QStringLiteral("updateTrackedFriendsList");
            request[QStringLiteral("user_ids")] = user_id_list.join(QStringLiteral(","));
        } else {
            parameters[QStringLiteral("list_id")]  = TrackedFriendsListId.toLongLong();
            parameters[QStringLiteral("name")]     = TRACKED_FRIENDS_LIST_NAME;
            parameters[QStringLiteral("user_ids")] = user_id_list.join(QStringLiteral(","));

            request[QStringLiteral("method")]     = QStringLiteral("friends.editList");
            request[QStringLiteral("context")]    = QStringLiteral("updateTrackedFriendsList");
            request[QStringLiteral("parameters")] = parameters;
        }

        EnqueueRequest(request);

        emit friendsUpdated();
    }
}

void VKHelper::updateTrackedFriendsData(bool immediately)
{
    qint64 elapsed = QDateTime::currentSecsSinceEpoch() - LastUpdateTrackedFriendsDataTime;

    if (immediately || elapsed < 0 || elapsed > UPDATE_TRACKED_FRIENDS_DATA_INTERVAL) {
        LastUpdateTrackedFriendsDataTime = QDateTime::currentSecsSinceEpoch();

        for (const QString &key : FriendsData.keys()) {
            QVariantMap frnd = FriendsData[key].toMap();

            if ((frnd.contains(QStringLiteral("trusted")) && frnd[QStringLiteral("trusted")].toBool()) ||
                (frnd.contains(QStringLiteral("tracked")) && frnd[QStringLiteral("tracked")].toBool())) {
                bool is_closed         = frnd.contains(QStringLiteral("isClosed"))        && frnd[QStringLiteral("isClosed")].toBool();
                bool can_access_closed = frnd.contains(QStringLiteral("canAccessClosed")) && frnd[QStringLiteral("canAccessClosed")].toBool();

                if (!is_closed || can_access_closed) {
                    QVariantMap request, parameters;

                    parameters[QStringLiteral("count")]   = MAX_NOTES_GET_COUNT;
                    parameters[QStringLiteral("sort")]    = 0;
                    parameters[QStringLiteral("user_id")] = key.toLongLong();

                    request[QStringLiteral("method")]     = QStringLiteral("notes.get");
                    request[QStringLiteral("context")]    = QStringLiteral("updateTrackedFriendsData");
                    request[QStringLiteral("parameters")] = parameters;

                    EnqueueRequest(request);
                }
            }
        }
    }
}

void VKHelper::joinGroup(const QString &group_id)
{
    QVariantMap request, parameters;

    parameters[QStringLiteral("group_id")] = group_id.toLongLong();

    request[QStringLiteral("method")]     = QStringLiteral("groups.join");
    request[QStringLiteral("context")]    = QStringLiteral("joinGroup");
    request[QStringLiteral("parameters")] = parameters;

    EnqueueRequest(request);
}

void VKHelper::setAuthState(int state)
{
    if (AuthState != state) {
        AuthState = state;

        emit authStateChanged(AuthState);

        if (AuthState == VKAuthState::StateAuthorized) {
            QVariantMap request, parameters;

            parameters[QStringLiteral("fields")] = QStringLiteral("photo_100,photo_200");

            request[QStringLiteral("method")]     = QStringLiteral("users.get");
            request[QStringLiteral("context")]    = QStringLiteral("updateUser");
            request[QStringLiteral("parameters")] = parameters;

            EnqueueRequest(request);
        } else if (AuthState == VKAuthState::StateNotAuthorized) {
            Cleanup();
        }
    }
}

void VKHelper::handleResponse(const QString &response, const QString &resp_request_str)
{
    QVariantMap resp_request = QJsonDocument::fromJson(resp_request_str.toUtf8()).toVariant().toMap();

    if (resp_request.contains(QStringLiteral("method")) && resp_request.contains(QStringLiteral("context"))) {
        ContextTrackerDelRequest(resp_request);

        if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("notes.get")) {
            HandleNotesGetResponse(response, resp_request);
        } else if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("notes.add")) {
            HandleNotesAddResponse(response, resp_request);
        } else if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("notes.delete")) {
            HandleNotesDeleteResponse(response, resp_request);
        } else if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("friends.get")) {
            HandleFriendsGetResponse(response, resp_request);
        } else if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("friends.getLists")) {
            HandleFriendsGetListsResponse(response, resp_request);
        } else if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("friends.addList")) {
            HandleFriendsAddListResponse(response, resp_request);
        } else if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("friends.editList")) {
            HandleFriendsEditListResponse(response, resp_request);
        } else if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("groups.join")) {
            HandleGroupsJoinResponse(response, resp_request);
        } else if (resp_request[QStringLiteral("method")].toString() == QStringLiteral("users.get")) {
            HandleUsersGetResponse(response, resp_request);
        } else {
            qWarning() << QStringLiteral("handleResponse() : unknown request method: %1").arg(resp_request[QStringLiteral("method")].toString());
        }
    } else {
        qWarning() << "handleResponse() : invalid request";
    }
}

void VKHelper::handleError(const QString &error_message, const QString &err_request_str)
{
    QVariantMap err_request = QJsonDocument::fromJson(err_request_str.toUtf8()).toVariant().toMap();

    if (err_request.contains(QStringLiteral("method")) && err_request.contains(QStringLiteral("context"))) {
        ContextTrackerDelRequest(err_request);

        if (err_request[QStringLiteral("method")].toString() == QStringLiteral("notes.get")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleNotesGetError(err_request);
        } else if (err_request[QStringLiteral("method")].toString() == QStringLiteral("notes.add")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleNotesAddError(err_request);
        } else if (err_request[QStringLiteral("method")].toString() == QStringLiteral("notes.delete")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleNotesDeleteError(err_request);
        } else if (err_request[QStringLiteral("method")].toString() == QStringLiteral("friends.get")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleFriendsGetError(err_request);
        } else if (err_request[QStringLiteral("method")].toString() == QStringLiteral("friends.getLists")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleFriendsGetListsError(err_request);
        } else if (err_request[QStringLiteral("method")].toString() == QStringLiteral("friends.addList")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleFriendsAddListError(err_request);
        } else if (err_request[QStringLiteral("method")].toString() == QStringLiteral("friends.editList")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleFriendsEditListError(err_request);
        } else if (err_request[QStringLiteral("method")].toString() == QStringLiteral("groups.join")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleGroupsJoinError(err_request);
        } else if (err_request[QStringLiteral("method")].toString() == QStringLiteral("users.get")) {
            qWarning() << QStringLiteral("handleError() : %1 request failed : %2").arg(err_request[QStringLiteral("method")].toString(),
                                                                                       error_message);

            HandleUsersGetError(err_request);
        } else {
            qWarning() << QStringLiteral("handleError() : unknown request method: %1").arg(err_request[QStringLiteral("method")].toString());
        }
    } else {
        qWarning() << "handleError() : invalid request";
    }
}

void VKHelper::handleLocationUpdate(qreal latitude, qreal longitude)
{
    updateLocation(latitude, longitude);
}

void VKHelper::handleBatteryStatusUpdate(const QString &status, int level)
{
    updateBatteryStatus(status, level);
}

void VKHelper::handleRequestQueueTimerTimeout()
{
    if (!RequestQueue.isEmpty()) {
        QVariantList request_list;

        for (int i = 0; i < MAX_BATCH_SIZE && !RequestQueue.isEmpty(); i++) {
            QVariantMap request = RequestQueue.dequeue();

            if (request.contains(QStringLiteral("method")) && request.contains(QStringLiteral("context"))) {
                if (AuthState == VKAuthState::StateAuthorized) {
                    //
                    // Workaround for issue when friends.get with list_id parameter returns empty
                    // items list if combined with list-related operation in the same batch.
                    //
                    if (request[QStringLiteral("method")] == QStringLiteral("friends.getLists") ||
                        request[QStringLiteral("method")] == QStringLiteral("friends.addList") ||
                        request[QStringLiteral("method")] == QStringLiteral("friends.editList")) {
                        if (i == 0) {
                            request_list.append(request);
                        } else {
                            RequestQueue.insert(0, request);
                        }

                        break;
                    } else {
                        request_list.append(request);
                    }
                } else {
                    ContextTrackerDelRequest(request);
                }
            } else {
                qWarning() << "handleRequestQueueTimerTimeout() : invalid request";

                ContextTrackerDelRequest(request);
            }
        }

        if (request_list.count() > 0) {
            QAndroidJniObject j_request_list = QAndroidJniObject::fromString(QString::fromUtf8(QJsonDocument::fromVariant(request_list).toJson(QJsonDocument::Compact)));

            AndroidContext.callMethod<void>("executeVKBatch", "(Ljava/lang/String;)V", j_request_list.object<jstring>());
        }
    }

    if (RequestQueue.isEmpty()) {
        NextRequestQueueTimerTimeout = QDateTime::currentMSecsSinceEpoch() + REQUEST_QUEUE_TIMER_INTERVAL;

        RequestQueueTimer.stop();
    } else {
        RequestQueueTimer.setInterval(REQUEST_QUEUE_TIMER_INTERVAL);
    }
}

void VKHelper::handleSendDataTimerTimeout()
{
    if (CurrentDataState == StateNewDataArrived || CurrentDataState == StateDataIsBeingSent) {
        qint64 elapsed = QDateTime::currentSecsSinceEpoch() - LastSendDataTime;

        if (elapsed < 0 || elapsed > SEND_DATA_INTERVAL) {
            SendData();
        }

        if (!SendDataTimer.isActive()) {
            SendDataTimer.start();
        }
    }
}

void VKHelper::Cleanup()
{
    LastSendDataTime                 = 0;
    LastUpdateTrackedFriendsDataTime = 0;
    NextRequestQueueTimerTimeout     = QDateTime::currentMSecsSinceEpoch() + REQUEST_QUEUE_TIMER_INTERVAL;
    TrustedFriendsListId             = QLatin1String("");
    TrackedFriendsListId             = QLatin1String("");

    if (UserId != QLatin1String("")) {
        UserId = QLatin1String("");

        emit userIdChanged(UserId);
    }

    if (FirstName != QLatin1String("")) {
        FirstName = QLatin1String("");

        emit firstNameChanged(FirstName);
    }

    if (LastName != QLatin1String("")) {
        LastName = QLatin1String("");

        emit lastNameChanged(LastName);
    }

    if (PhotoUrl != DEFAULT_PHOTO_URL) {
        PhotoUrl = DEFAULT_PHOTO_URL;

        emit photoUrlChanged(PhotoUrl);
    }

    if (BigPhotoUrl != DEFAULT_PHOTO_URL) {
        BigPhotoUrl = DEFAULT_PHOTO_URL;

        emit bigPhotoUrlChanged(BigPhotoUrl);
    }

    while (!RequestQueue.isEmpty()) {
        QVariantMap request = RequestQueue.dequeue();

        ContextTrackerDelRequest(request);
    }

    RequestQueueTimer.stop();

    AndroidContext.callMethod<void>("cancelAllVKRequests");

    int prev_friends_count = FriendsData.count();

    FriendsData.clear();
    FriendsDataTmp.clear();

    if (FriendsData.count() != prev_friends_count) {
        emit friendsCountChanged(FriendsData.count());
    }

    emit friendsUpdated();
}

void VKHelper::SendData()
{
    if (!ContextHasActiveRequests(QStringLiteral("sendData"))) {
        QVariantMap request, parameters;

        if (TrustedFriendsListId == QLatin1String("")) {
            request[QStringLiteral("method")]  = QStringLiteral("friends.getLists");
            request[QStringLiteral("context")] = QStringLiteral("sendData");
        } else {
            parameters[QStringLiteral("count")]   = MAX_FRIENDS_GET_COUNT;
            parameters[QStringLiteral("list_id")] = TrustedFriendsListId.toLongLong();

            request[QStringLiteral("method")]     = QStringLiteral("friends.get");
            request[QStringLiteral("context")]    = QStringLiteral("sendData");
            request[QStringLiteral("parameters")] = parameters;
        }

        EnqueueRequest(request);
    }
}

void VKHelper::ContextTrackerAddRequest(const QVariantMap &request)
{
    if (request.contains(QStringLiteral("context"))) {
        QString context = request[QStringLiteral("context")].toString();

        if (ContextTracker.contains(context)) {
            ContextTracker[context]++;
        } else {
            ContextTracker[context] = 1;
        }
    } else {
        qWarning() << "ContextTrackerAddRequest() : request has no context";
    }
}

void VKHelper::ContextTrackerDelRequest(const QVariantMap &request)
{
    if (request.contains(QStringLiteral("context"))) {
        QString context = request[QStringLiteral("context")].toString();

        if (ContextTracker.contains(context)) {
            if (ContextTracker[context] > 0) {
                ContextTracker[context]--;
            } else {
                qWarning() << QStringLiteral("ContextTrackerDelRequest() : negative tracker value for context: %1").arg(context);
            }
        } else {
            qWarning() << QStringLiteral("ContextTrackerDelRequest() : no tracker value for context: %1").arg(context);
        }
    } else {
        qWarning() << "ContextTrackerDelRequest() : request has no context";
    }
}

bool VKHelper::ContextHasActiveRequests(const QString &context) const
{
    return (ContextTracker.contains(context) && ContextTracker[context] > 0);
}

void VKHelper::EnqueueRequest(const QVariantMap &request)
{
    RequestQueue.enqueue(request);

    ContextTrackerAddRequest(request);

    if (!RequestQueueTimer.isActive()) {
        RequestQueueTimer.setInterval(static_cast<int>(qMax(static_cast<qint64>(0),
                                                            qMin(NextRequestQueueTimerTimeout - QDateTime::currentMSecsSinceEpoch(),
                                                                 static_cast<qint64>(REQUEST_QUEUE_TIMER_INTERVAL)))));
        RequestQueueTimer.start();
    }
}

void VKHelper::HandleNotesGetResponse(const QString &response, const QVariantMap &resp_request)
{
    if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("sendData")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("count")) && json_response.contains(QStringLiteral("items"))) {
                int         offset      = 0;
                int         notes_count = json_response.value(QStringLiteral("count")).toInt();
                QStringList trusted_friends, notes_to_delete;

                if (resp_request.contains(QStringLiteral("parameters")) && resp_request[QStringLiteral("parameters")].toMap().contains(QStringLiteral("offset"))) {
                    offset = (resp_request[QStringLiteral("parameters")].toMap())[QStringLiteral("offset")].toInt();
                }
                if (resp_request.contains(QStringLiteral("trusted_friends"))) {
                    trusted_friends = resp_request[QStringLiteral("trusted_friends")].toString().split(QStringLiteral(","));
                }
                if (resp_request.contains(QStringLiteral("notes_to_delete"))) {
                    notes_to_delete = resp_request[QStringLiteral("notes_to_delete")].toString().split(QStringLiteral(","));
                }

                QJsonArray json_items = json_response.value(QStringLiteral("items")).toArray();

                for (const QJsonValueRef &json_item : json_items) {
                    QJsonObject json_note = json_item.toObject();

                    if (json_note.contains(QStringLiteral("id")) && json_note.contains(QStringLiteral("title")) &&
                        json_note.value(QStringLiteral("title")).toString() == DATA_NOTE_TITLE) {
                        QString data_note_id = QString::number(json_note.value(QStringLiteral("id")).toVariant().toLongLong());

                        if (data_note_id != QLatin1String("")) {
                            notes_to_delete.append(data_note_id);
                        }
                    }
                }

                QVariantMap request, parameters;

                if (json_items.count() > 0 && offset + json_items.count() < notes_count) {
                    parameters[QStringLiteral("count")]  = MAX_NOTES_GET_COUNT;
                    parameters[QStringLiteral("offset")] = offset + json_items.count();
                    parameters[QStringLiteral("sort")]   = 0;

                    request[QStringLiteral("method")]  = QStringLiteral("notes.get");
                    request[QStringLiteral("context")] = resp_request[QStringLiteral("context")].toString();

                    if (trusted_friends.count() > 0) {
                        request[QStringLiteral("trusted_friends")] = trusted_friends.join(QStringLiteral(","));
                    }
                    if (notes_to_delete.count() > 0) {
                        request[QStringLiteral("notes_to_delete")] = notes_to_delete.join(QStringLiteral(","));
                    }

                    request[QStringLiteral("parameters")] = parameters;
                } else {
                    QString note_text;

                    if (EncryptionEnabled) {
                        QVariantList encrypted_payload;

                        for (const QString &user_id : trusted_friends) {
                            QString friend_key = CryptoHelper::GetInstance().getPublicKeyOfFriend(user_id);

                            if (friend_key != QLatin1String("")) {
                                QVariantMap payload_item;

                                payload_item[QStringLiteral("payload_cookie")] = ENCRYPTED_PAYLOAD_COOKIE;
                                payload_item[QStringLiteral("data")]           = CurrentData;

                                QByteArray encrypted_payload_item = CryptoHelper::GetInstance().EncryptWithRSA(QByteArray::fromBase64(friend_key.toUtf8()),
                                                                                                               QJsonDocument::fromVariant(payload_item)
                                                                                                               .toJson(QJsonDocument::Compact));

                                if (!encrypted_payload_item.isEmpty()) {
                                    encrypted_payload.append(QString::fromUtf8(encrypted_payload_item.toBase64()));
                                }
                            }
                        }

                        QVariantMap note_data;

                        note_data[QStringLiteral("encryption")]        = QStringLiteral("RSA-2048");
                        note_data[QStringLiteral("encrypted_payload")] = encrypted_payload;

                        note_text = QStringLiteral("{{{%1}}}").arg(QString::fromUtf8(QJsonDocument::fromVariant(note_data)
                                                                                     .toJson(QJsonDocument::Compact)
                                                                                     .toBase64()));
                    } else {
                        note_text = QStringLiteral("{{{%1}}}").arg(QString::fromUtf8(QJsonDocument::fromVariant(CurrentData)
                                                                                     .toJson(QJsonDocument::Compact)
                                                                                     .toBase64()));
                    }

                    parameters[QStringLiteral("title")]           = DATA_NOTE_TITLE;
                    parameters[QStringLiteral("text")]            = note_text;
                    parameters[QStringLiteral("privacy_comment")] = QStringLiteral("nobody");

                    if (TrustedFriendsListId == QLatin1String("")) {
                        parameters[QStringLiteral("privacy_view")] = QStringLiteral("nobody");
                    } else {
                        parameters[QStringLiteral("privacy_view")] = QStringLiteral("list%1").arg(TrustedFriendsListId);
                    }

                    request[QStringLiteral("method")]  = QStringLiteral("notes.add");
                    request[QStringLiteral("context")] = resp_request[QStringLiteral("context")].toString();

                    if (notes_to_delete.count() > 0) {
                        request[QStringLiteral("notes_to_delete")] = notes_to_delete.join(QStringLiteral(","));
                    }

                    request[QStringLiteral("parameters")] = parameters;

                    CurrentDataState = StateDataIsBeingSent;
                }

                EnqueueRequest(request);
            } else {
                qWarning() << "HandleNotesGetResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleNotesGetResponse() : invalid json";
        }
    } else if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrackedFriendsData")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("count")) && json_response.contains(QStringLiteral("items"))) {
                bool data_note_found = false;

                int     offset      = 0;
                int     notes_count = json_response.value(QStringLiteral("count")).toInt();
                QString user_id;

                if (resp_request.contains(QStringLiteral("parameters")) && resp_request[QStringLiteral("parameters")].toMap().contains(QStringLiteral("offset"))) {
                    offset = (resp_request[QStringLiteral("parameters")].toMap())[QStringLiteral("offset")].toInt();
                }
                if (resp_request.contains(QStringLiteral("parameters")) && resp_request[QStringLiteral("parameters")].toMap().contains(QStringLiteral("user_id"))) {
                    user_id = (resp_request[QStringLiteral("parameters")].toMap())[QStringLiteral("user_id")].toString();
                }

                if (user_id != QLatin1String("")) {
                    QJsonArray json_items = json_response.value(QStringLiteral("items")).toArray();

                    for (const QJsonValueRef &json_item : json_items) {
                        QJsonObject json_note = json_item.toObject();

                        if (json_note.contains(QStringLiteral("title")) && json_note.contains(QStringLiteral("text")) &&
                            json_note.value(QStringLiteral("title")).toString() == DATA_NOTE_TITLE) {
                            data_note_found = true;

                            QString note_text = json_note.value(QStringLiteral("text")).toString();
                            QRegExp base64_regexp(QStringLiteral("\\{\\{\\{([^\\}]+)\\}\\}\\}"));

                            if (base64_regexp.indexIn(note_text) != -1) {
                                QVariantMap friend_data = QJsonDocument::fromJson(QByteArray::fromBase64(base64_regexp.cap(1).toUtf8())).toVariant().toMap();

                                if (friend_data.contains(QStringLiteral("encryption"))) {
                                    if (friend_data[QStringLiteral("encryption")] == QStringLiteral("RSA-2048")) {
                                        if (friend_data.contains(QStringLiteral("encrypted_payload"))) {
                                            QByteArray   raw_private_key   = QByteArray::fromBase64(CryptoHelper::GetInstance().privateKey().toUtf8());
                                            QVariantList encrypted_payload = friend_data[QStringLiteral("encrypted_payload")].toList();

                                            for (const QVariant &variant_item : encrypted_payload) {
                                                QByteArray  encrypted_payload_item = QByteArray::fromBase64(variant_item.toString().toUtf8());
                                                QVariantMap payload_item           = QJsonDocument::fromJson(CryptoHelper::GetInstance().DecryptRSA(raw_private_key,
                                                                                                                                                    encrypted_payload_item))
                                                                                                                                        .toVariant().toMap();

                                                if (payload_item.contains(QStringLiteral("payload_cookie")) &&
                                                    payload_item.contains(QStringLiteral("data")) &&
                                                    payload_item[QStringLiteral("payload_cookie")] == ENCRYPTED_PAYLOAD_COOKIE) {
                                                    emit trackedFriendDataUpdated(user_id, payload_item[QStringLiteral("data")].toMap());

                                                    break;
                                                }
                                            }
                                        } else {
                                            qWarning() << "HandleNotesGetResponse() : invalid user data";
                                        }
                                    } else {
                                        qWarning() << "HandleNotesGetResponse() : unknown encryption method";
                                    }
                                } else {
                                    emit trackedFriendDataUpdated(user_id, friend_data);
                                }
                            } else {
                                qWarning() << "HandleNotesGetResponse() : invalid user data";
                            }

                            break;
                        }
                    }

                    if (!data_note_found && json_items.count() > 0 && offset + json_items.count() < notes_count) {
                        QVariantMap request, parameters;

                        parameters[QStringLiteral("count")]   = MAX_NOTES_GET_COUNT;
                        parameters[QStringLiteral("offset")]  = offset + json_items.count();
                        parameters[QStringLiteral("sort")]    = 0;
                        parameters[QStringLiteral("user_id")] = user_id.toLongLong();

                        request[QStringLiteral("method")]     = QStringLiteral("notes.get");
                        request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                        request[QStringLiteral("parameters")] = parameters;

                        EnqueueRequest(request);
                    }
                } else {
                    qWarning() << "HandleNotesGetResponse() : invalid request";
                }
            } else {
                qWarning() << "HandleNotesGetResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleNotesGetResponse() : invalid json";
        }
    }
}

void VKHelper::HandleNotesGetError(const QVariantMap &err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::HandleNotesAddResponse(const QString &response, const QVariantMap &resp_request)
{
    Q_UNUSED(response)

    if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("sendData")) {
        QStringList notes_to_delete;

        if (resp_request.contains(QStringLiteral("notes_to_delete"))) {
            notes_to_delete = resp_request[QStringLiteral("notes_to_delete")].toString().split(QStringLiteral(","));
        }

        for (const QString &note_id : notes_to_delete) {
            QVariantMap request, parameters;

            parameters[QStringLiteral("note_id")] = note_id.toLongLong();

            request[QStringLiteral("method")]     = QStringLiteral("notes.delete");
            request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
            request[QStringLiteral("parameters")] = parameters;

            EnqueueRequest(request);
        }

        LastSendDataTime = QDateTime::currentSecsSinceEpoch();

        if (CurrentDataState == StateDataIsBeingSent) {
            CurrentDataState = StateNoNewData;

            SendDataTimer.stop();
        }

        emit dataSent();
    }
}

void VKHelper::HandleNotesAddError(const QVariantMap &err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::HandleNotesDeleteResponse(const QString &response, const QVariantMap &resp_request)
{
    Q_UNUSED(response)
    Q_UNUSED(resp_request)
}

void VKHelper::HandleNotesDeleteError(const QVariantMap &err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::HandleFriendsGetResponse(const QString &response, const QVariantMap &resp_request)
{
    if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("sendData")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("count")) && json_response.contains(QStringLiteral("items"))) {
                int         offset        = 0;
                int         friends_count = json_response.value(QStringLiteral("count")).toInt();
                QString     list_id;
                QStringList trusted_friends;

                if (resp_request.contains(QStringLiteral("parameters")) && resp_request[QStringLiteral("parameters")].toMap().contains(QStringLiteral("offset"))) {
                    offset = (resp_request[QStringLiteral("parameters")].toMap())[QStringLiteral("offset")].toInt();
                }
                if (resp_request.contains(QStringLiteral("parameters")) && resp_request[QStringLiteral("parameters")].toMap().contains(QStringLiteral("list_id"))) {
                    list_id = (resp_request[QStringLiteral("parameters")].toMap())[QStringLiteral("list_id")].toString();
                }
                if (resp_request.contains(QStringLiteral("trusted_friends"))) {
                    trusted_friends = resp_request[QStringLiteral("trusted_friends")].toString().split(QStringLiteral(","));
                }

                if (list_id != QLatin1String("")) {
                    QJsonArray json_items = json_response.value(QStringLiteral("items")).toArray();

                    if (list_id == TrustedFriendsListId) {
                        for (const QJsonValueRef &json_item : json_items) {
                            QString user_id = QString::number(json_item.toVariant().toLongLong());

                            if (user_id != QLatin1String("")) {
                                trusted_friends.append(user_id);
                            }
                        }
                    } else {
                        qWarning() << "HandleFriendsGetResponse() : unknown list id";
                    }

                    QVariantMap request, parameters;

                    if (json_items.count() > 0 && offset + json_items.count() < friends_count) {
                        parameters[QStringLiteral("count")]   = MAX_FRIENDS_GET_COUNT;
                        parameters[QStringLiteral("offset")]  = offset + json_items.count();
                        parameters[QStringLiteral("list_id")] = list_id.toLongLong();

                        request[QStringLiteral("method")]  = QStringLiteral("friends.get");
                        request[QStringLiteral("context")] = resp_request[QStringLiteral("context")].toString();

                        if (trusted_friends.count() > 0) {
                            request[QStringLiteral("trusted_friends")] = trusted_friends.join(QStringLiteral(","));
                        }

                        request[QStringLiteral("parameters")] = parameters;
                    } else {
                        parameters[QStringLiteral("count")] = MAX_NOTES_GET_COUNT;
                        parameters[QStringLiteral("sort")]  = 0;

                        request[QStringLiteral("method")]  = QStringLiteral("notes.get");
                        request[QStringLiteral("context")] = resp_request[QStringLiteral("context")].toString();

                        if (trusted_friends.count() > 0) {
                            request[QStringLiteral("trusted_friends")] = trusted_friends.join(QStringLiteral(","));
                        }

                        request[QStringLiteral("parameters")] = parameters;
                    }

                    EnqueueRequest(request);
                } else {
                    qWarning() << "HandleFriendsGetResponse() : invalid request";
                }
            } else {
                qWarning() << "HandleFriendsGetResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleFriendsGetResponse() : invalid json";
        }
    } else if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateFriends")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("count")) && json_response.contains(QStringLiteral("items"))) {
                int     offset        = 0;
                int     friends_count = json_response.value(QStringLiteral("count")).toInt();
                QString fields, list_id;

                if (resp_request.contains(QStringLiteral("parameters")) && resp_request[QStringLiteral("parameters")].toMap().contains(QStringLiteral("offset"))) {
                    offset = (resp_request[QStringLiteral("parameters")].toMap())[QStringLiteral("offset")].toInt();
                }
                if (resp_request.contains(QStringLiteral("parameters")) && resp_request[QStringLiteral("parameters")].toMap().contains(QStringLiteral("fields"))) {
                    fields = (resp_request[QStringLiteral("parameters")].toMap())[QStringLiteral("fields")].toString();
                }
                if (resp_request.contains(QStringLiteral("parameters")) && resp_request[QStringLiteral("parameters")].toMap().contains(QStringLiteral("list_id"))) {
                    list_id = (resp_request[QStringLiteral("parameters")].toMap())[QStringLiteral("list_id")].toString();
                }

                QJsonArray json_items = json_response.value(QStringLiteral("items")).toArray();

                if (list_id == QLatin1String("")) {
                    for (const QJsonValueRef &json_item : json_items) {
                        QJsonObject json_friend = json_item.toObject();

                        if (json_friend.contains(QStringLiteral("id"))) {
                            if (!json_friend.contains(QStringLiteral("deactivated"))) {
                                QVariantMap frnd;

                                frnd[QStringLiteral("userId")]  = QString::number(json_friend.value(QStringLiteral("id")).toVariant().toLongLong());
                                frnd[QStringLiteral("trusted")] = false;
                                frnd[QStringLiteral("tracked")] = false;

                                if (json_friend.contains(QStringLiteral("first_name"))) {
                                    frnd[QStringLiteral("firstName")] = json_friend.value(QStringLiteral("first_name")).toString();
                                } else {
                                    frnd[QStringLiteral("firstName")] = QLatin1String("");
                                }
                                if (json_friend.contains(QStringLiteral("last_name"))) {
                                    frnd[QStringLiteral("lastName")] = json_friend.value(QStringLiteral("last_name")).toString();
                                } else {
                                    frnd[QStringLiteral("lastName")] = QLatin1String("");
                                }
                                if (json_friend.contains(QStringLiteral("is_closed"))) {
                                    frnd[QStringLiteral("isClosed")] = json_friend.value(QStringLiteral("is_closed")).toBool();
                                } else {
                                    frnd[QStringLiteral("isClosed")] = false;
                                }
                                if (json_friend.contains(QStringLiteral("can_access_closed"))) {
                                    frnd[QStringLiteral("canAccessClosed")] = json_friend.value(QStringLiteral("can_access_closed")).toBool();
                                } else {
                                    frnd[QStringLiteral("canAccessClosed")] = false;
                                }
                                if (json_friend.contains(QStringLiteral("photo_100"))) {
                                    frnd[QStringLiteral("photoUrl")] = json_friend.value(QStringLiteral("photo_100")).toString();
                                } else {
                                    frnd[QStringLiteral("photoUrl")] = DEFAULT_PHOTO_URL;
                                }
                                if (json_friend.contains(QStringLiteral("photo_200"))) {
                                    frnd[QStringLiteral("bigPhotoUrl")] = json_friend.value(QStringLiteral("photo_200")).toString();
                                } else {
                                    frnd[QStringLiteral("bigPhotoUrl")] = DEFAULT_PHOTO_URL;
                                }
                                if (json_friend.contains(QStringLiteral("online"))) {
                                    frnd[QStringLiteral("online")] = (json_friend.value(QStringLiteral("online")).toInt() != 0);
                                } else {
                                    frnd[QStringLiteral("online")] = false;
                                }
                                if (json_friend.contains(QStringLiteral("screen_name"))) {
                                    frnd[QStringLiteral("screenName")] = json_friend.value(QStringLiteral("screen_name")).toString();
                                } else {
                                    frnd[QStringLiteral("screenName")] = QStringLiteral("id%1").arg(frnd[QStringLiteral("userId")].toString());
                                }
                                if (json_friend.contains(QStringLiteral("status"))) {
                                    frnd[QStringLiteral("status")] = json_friend.value(QStringLiteral("status")).toString();
                                } else {
                                    frnd[QStringLiteral("status")] = QLatin1String("");
                                }
                                if (json_friend.contains(QStringLiteral("last_seen"))) {
                                    QJsonObject json_last_seen = json_friend.value(QStringLiteral("last_seen")).toObject();

                                    if (json_last_seen.contains(QStringLiteral("time"))) {
                                        frnd[QStringLiteral("lastSeenTime")] = QString::number(json_last_seen[QStringLiteral("time")].toVariant().toLongLong());
                                    } else {
                                        frnd[QStringLiteral("lastSeenTime")] = QLatin1String("");
                                    }
                                } else {
                                    frnd[QStringLiteral("lastSeenTime")] = QLatin1String("");
                                }

                                FriendsDataTmp[frnd[QStringLiteral("userId")].toString()] = frnd;
                            }
                        } else {
                            qWarning() << "HandleFriendsGetResponse() : invalid entry";
                        }
                    }
                } else if (list_id == TrustedFriendsListId) {
                    for (int i = 0; i < json_items.count() && offset + i < MaxTrustedFriendsCount; i++) {
                        QString user_id = QString::number(json_items[i].toVariant().toLongLong());

                        if (FriendsDataTmp.contains(user_id)) {
                            QVariantMap frnd = FriendsDataTmp[user_id].toMap();

                            frnd[QStringLiteral("trusted")] = true;
                            frnd[QStringLiteral("tracked")] = false;

                            FriendsDataTmp[user_id] = frnd;
                        }
                    }
                } else if (list_id == TrackedFriendsListId) {
                    for (int i = 0; i < json_items.count() && offset + i < MaxTrackedFriendsCount; i++) {
                        QString user_id = QString::number(json_items[i].toVariant().toLongLong());

                        if (FriendsDataTmp.contains(user_id)) {
                            QVariantMap frnd = FriendsDataTmp[user_id].toMap();

                            if (!frnd.contains(QStringLiteral("trusted")) || !frnd[QStringLiteral("trusted")].toBool()) {
                                frnd[QStringLiteral("tracked")] = true;
                            }

                            FriendsDataTmp[user_id] = frnd;
                        }
                    }
                } else {
                    qWarning() << "HandleFriendsGetResponse() : unknown list id";
                }

                if (json_items.count() > 0 && offset + json_items.count() < friends_count) {
                    QVariantMap request, parameters;

                    parameters[QStringLiteral("count")]  = MAX_FRIENDS_GET_COUNT;
                    parameters[QStringLiteral("offset")] = offset + json_items.count();

                    if (fields != QLatin1String("")) {
                        parameters[QStringLiteral("fields")] = fields;
                    }
                    if (list_id != QLatin1String("")) {
                        parameters[QStringLiteral("list_id")] = list_id.toLongLong();
                    }

                    request[QStringLiteral("method")]     = QStringLiteral("friends.get");
                    request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                    request[QStringLiteral("parameters")] = parameters;

                    EnqueueRequest(request);
                } else if (list_id == QLatin1String("")) {
                    QVariantMap request;

                    request[QStringLiteral("method")]  = QStringLiteral("friends.getLists");
                    request[QStringLiteral("context")] = resp_request[QStringLiteral("context")].toString();

                    EnqueueRequest(request);
                }

                if (!ContextHasActiveRequests(resp_request[QStringLiteral("context")].toString())) {
                    int prev_friends_count = FriendsData.count();

                    FriendsData = FriendsDataTmp;

                    if (FriendsData.count() != prev_friends_count) {
                        emit friendsCountChanged(FriendsData.count());
                    }

                    emit friendsUpdated();
                }
            } else {
                qWarning() << "HandleFriendsGetResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleFriendsGetResponse() : invalid json";
        }
    }
}

void VKHelper::HandleFriendsGetError(const QVariantMap &err_request)
{
    Q_UNUSED(err_request)
}

void VKHelper::HandleFriendsGetListsResponse(const QString &response, const QVariantMap &resp_request)
{
    if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("sendData")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("count")) && json_response.contains(QStringLiteral("items"))) {
                QString trusted_friends_list_id, tracked_friends_list_id;

                for (const QJsonValueRef &json_item : json_response.value(QStringLiteral("items")).toArray()) {
                    QJsonObject json_list = json_item.toObject();

                    if (json_list.contains(QStringLiteral("id")) && json_list.contains(QStringLiteral("name"))) {
                        if (json_list.value(QStringLiteral("name")).toString() == TRUSTED_FRIENDS_LIST_NAME) {
                            trusted_friends_list_id = QString::number(json_list.value(QStringLiteral("id")).toVariant().toLongLong());
                        } else if (json_list.value(QStringLiteral("name")).toString() == TRACKED_FRIENDS_LIST_NAME) {
                            tracked_friends_list_id = QString::number(json_list.value(QStringLiteral("id")).toVariant().toLongLong());
                        }

                        if (trusted_friends_list_id != QLatin1String("") && tracked_friends_list_id != QLatin1String("")) {
                            break;
                        }
                    }
                }

                if (trusted_friends_list_id != QLatin1String("")) {
                    TrustedFriendsListId = trusted_friends_list_id;
                }
                if (tracked_friends_list_id != QLatin1String("")) {
                    TrackedFriendsListId = tracked_friends_list_id;
                }

                QVariantMap request, parameters;

                parameters[QStringLiteral("count")]   = MAX_FRIENDS_GET_COUNT;
                parameters[QStringLiteral("list_id")] = TrustedFriendsListId.toLongLong();

                request[QStringLiteral("method")]     = QStringLiteral("friends.get");
                request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                request[QStringLiteral("parameters")] = parameters;

                EnqueueRequest(request);
            } else {
                qWarning() << "HandleFriendsGetListsResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleFriendsGetListsResponse() : invalid json";
        }
    } else if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateFriends")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("count")) && json_response.contains(QStringLiteral("items"))) {
                QString trusted_friends_list_id, tracked_friends_list_id;

                for (const QJsonValueRef &json_item : json_response.value(QStringLiteral("items")).toArray()) {
                    QJsonObject json_list = json_item.toObject();

                    if (json_list.contains(QStringLiteral("id")) && json_list.contains(QStringLiteral("name"))) {
                        if (json_list.value(QStringLiteral("name")).toString() == TRUSTED_FRIENDS_LIST_NAME) {
                            trusted_friends_list_id = QString::number(json_list.value(QStringLiteral("id")).toVariant().toLongLong());
                        } else if (json_list.value(QStringLiteral("name")).toString() == TRACKED_FRIENDS_LIST_NAME) {
                            tracked_friends_list_id = QString::number(json_list.value(QStringLiteral("id")).toVariant().toLongLong());
                        }

                        if (trusted_friends_list_id != QLatin1String("") && tracked_friends_list_id != QLatin1String("")) {
                            break;
                        }
                    }
                }

                if (trusted_friends_list_id != QLatin1String("")) {
                    TrustedFriendsListId = trusted_friends_list_id;

                    QVariantMap request, parameters;

                    parameters[QStringLiteral("count")]   = MAX_FRIENDS_GET_COUNT;
                    parameters[QStringLiteral("list_id")] = TrustedFriendsListId.toLongLong();

                    request[QStringLiteral("method")]     = QStringLiteral("friends.get");
                    request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                    request[QStringLiteral("parameters")] = parameters;

                    EnqueueRequest(request);
                }
                if (tracked_friends_list_id != QLatin1String("")) {
                    TrackedFriendsListId = tracked_friends_list_id;

                    QVariantMap request, parameters;

                    parameters[QStringLiteral("count")]   = MAX_FRIENDS_GET_COUNT;
                    parameters[QStringLiteral("list_id")] = TrackedFriendsListId.toLongLong();

                    request[QStringLiteral("method")]     = QStringLiteral("friends.get");
                    request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                    request[QStringLiteral("parameters")] = parameters;

                    EnqueueRequest(request);
                }

                if (!ContextHasActiveRequests(resp_request[QStringLiteral("context")].toString())) {
                    int prev_friends_count = FriendsData.count();

                    FriendsData = FriendsDataTmp;

                    if (FriendsData.count() != prev_friends_count) {
                        emit friendsCountChanged(FriendsData.count());
                    }

                    emit friendsUpdated();
                }
            } else {
                qWarning() << "HandleFriendsGetListsResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleFriendsGetListsResponse() : invalid json";
        }
    } else if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrustedFriendsList")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("count")) && json_response.contains(QStringLiteral("items"))) {
                QString trusted_friends_list_id;

                for (const QJsonValueRef &json_item : json_response.value(QStringLiteral("items")).toArray()) {
                    QJsonObject json_list = json_item.toObject();

                    if (json_list.contains(QStringLiteral("id")) && json_list.contains(QStringLiteral("name")) &&
                        json_list.value(QStringLiteral("name")).toString() == TRUSTED_FRIENDS_LIST_NAME) {
                        trusted_friends_list_id = QString::number(json_list.value(QStringLiteral("id")).toVariant().toLongLong());

                        if (trusted_friends_list_id != QLatin1String("")) {
                            break;
                        }
                    }
                }

                if (resp_request.contains(QStringLiteral("user_ids"))) {
                    QVariantMap request, parameters;

                    if (trusted_friends_list_id != QLatin1String("")) {
                        TrustedFriendsListId = trusted_friends_list_id;

                        parameters[QStringLiteral("list_id")]  = TrustedFriendsListId.toLongLong();
                        parameters[QStringLiteral("name")]     = TRUSTED_FRIENDS_LIST_NAME;
                        parameters[QStringLiteral("user_ids")] = resp_request[QStringLiteral("user_ids")].toString();

                        request[QStringLiteral("method")]     = QStringLiteral("friends.editList");
                        request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                        request[QStringLiteral("parameters")] = parameters;
                    } else {
                        parameters[QStringLiteral("name")]     = TRUSTED_FRIENDS_LIST_NAME;
                        parameters[QStringLiteral("user_ids")] = resp_request[QStringLiteral("user_ids")].toString();

                        request[QStringLiteral("method")]     = QStringLiteral("friends.addList");
                        request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                        request[QStringLiteral("parameters")] = parameters;
                    }

                    EnqueueRequest(request);
                } else {
                    qWarning() << "HandleFriendsGetListsResponse() : invalid request";

                    emit trustedFriendsListUpdateFailed();
                }
            } else {
                qWarning() << "HandleFriendsGetListsResponse() : invalid response";

                emit trustedFriendsListUpdateFailed();
            }
        } else {
            qWarning() << "HandleFriendsGetListsResponse() : invalid json";

            emit trustedFriendsListUpdateFailed();
        }
    } else if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrackedFriendsList")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("count")) && json_response.contains(QStringLiteral("items"))) {
                QString tracked_friends_list_id;

                for (const QJsonValueRef &json_item : json_response.value(QStringLiteral("items")).toArray()) {
                    QJsonObject json_list = json_item.toObject();

                    if (json_list.contains(QStringLiteral("id")) && json_list.contains(QStringLiteral("name")) &&
                        json_list.value(QStringLiteral("name")).toString() == TRACKED_FRIENDS_LIST_NAME) {
                        tracked_friends_list_id = QString::number(json_list.value(QStringLiteral("id")).toVariant().toLongLong());

                        if (tracked_friends_list_id != QLatin1String("")) {
                            break;
                        }
                    }
                }

                if (resp_request.contains(QStringLiteral("user_ids"))) {
                    QVariantMap request, parameters;

                    if (tracked_friends_list_id != QLatin1String("")) {
                        TrackedFriendsListId = tracked_friends_list_id;

                        parameters[QStringLiteral("list_id")]  = TrackedFriendsListId.toLongLong();
                        parameters[QStringLiteral("name")]     = TRACKED_FRIENDS_LIST_NAME;
                        parameters[QStringLiteral("user_ids")] = resp_request[QStringLiteral("user_ids")].toString();

                        request[QStringLiteral("method")]     = QStringLiteral("friends.editList");
                        request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                        request[QStringLiteral("parameters")] = parameters;
                    } else {
                        parameters[QStringLiteral("name")]     = TRACKED_FRIENDS_LIST_NAME;
                        parameters[QStringLiteral("user_ids")] = resp_request[QStringLiteral("user_ids")].toString();

                        request[QStringLiteral("method")]     = QStringLiteral("friends.addList");
                        request[QStringLiteral("context")]    = resp_request[QStringLiteral("context")].toString();
                        request[QStringLiteral("parameters")] = parameters;
                    }

                    EnqueueRequest(request);
                } else {
                    qWarning() << "HandleFriendsGetListsResponse() : invalid request";

                    emit trackedFriendsListUpdateFailed();
                }
            } else {
                qWarning() << "HandleFriendsGetListsResponse() : invalid response";

                emit trackedFriendsListUpdateFailed();
            }
        } else {
            qWarning() << "HandleFriendsGetListsResponse() : invalid json";

            emit trackedFriendsListUpdateFailed();
        }
    }
}

void VKHelper::HandleFriendsGetListsError(const QVariantMap &err_request)
{
    if (err_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrustedFriendsList")) {
        emit trustedFriendsListUpdateFailed();
    } else if (err_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrackedFriendsList")) {
        emit trackedFriendsListUpdateFailed();
    }
}

void VKHelper::HandleFriendsAddListResponse(const QString &response, const QVariantMap &resp_request)
{
    if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrustedFriendsList")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("list_id"))) {
                TrustedFriendsListId = QString::number(json_response.value(QStringLiteral("list_id")).toVariant().toLongLong());

                emit trustedFriendsListUpdated();
            } else {
                qWarning() << "HandleFriendsAddListResponse() : invalid response";

                emit trustedFriendsListUpdateFailed();
            }
        } else {
            qWarning() << "HandleFriendsAddListResponse() : invalid json";

            emit trustedFriendsListUpdateFailed();
        }
    } else if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrackedFriendsList")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonObject json_response = json_document.object().value(QStringLiteral("response")).toObject();

            if (json_response.contains(QStringLiteral("list_id"))) {
                TrackedFriendsListId = QString::number(json_response.value(QStringLiteral("list_id")).toVariant().toLongLong());

                emit trackedFriendsListUpdated();
            } else {
                qWarning() << "HandleFriendsAddListResponse() : invalid response";

                emit trackedFriendsListUpdateFailed();
            }
        } else {
            qWarning() << "HandleFriendsAddListResponse() : invalid json";

            emit trackedFriendsListUpdateFailed();
        }
    }
}

void VKHelper::HandleFriendsAddListError(const QVariantMap &err_request)
{
    if (err_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrustedFriendsList")) {
        emit trustedFriendsListUpdateFailed();
    } else if (err_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrackedFriendsList")) {
        emit trackedFriendsListUpdateFailed();
    }
}

void VKHelper::HandleFriendsEditListResponse(const QString &response, const QVariantMap &resp_request)
{
    Q_UNUSED(response)

    if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrustedFriendsList")) {
        emit trustedFriendsListUpdated();
    } else if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrackedFriendsList")) {
        emit trackedFriendsListUpdated();
    }
}

void VKHelper::HandleFriendsEditListError(const QVariantMap &err_request)
{
    if (err_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrustedFriendsList")) {
        TrustedFriendsListId = QLatin1String("");

        emit trustedFriendsListUpdateFailed();
    } else if (err_request[QStringLiteral("context")].toString() == QStringLiteral("updateTrackedFriendsList")) {
        TrackedFriendsListId = QLatin1String("");

        emit trackedFriendsListUpdateFailed();
    }
}

void VKHelper::HandleGroupsJoinResponse(const QString &response, const QVariantMap &resp_request)
{
    Q_UNUSED(response)

    if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("joinGroup")) {
        emit joiningGroupCompleted();
    }
}

void VKHelper::HandleGroupsJoinError(const QVariantMap &err_request)
{
    if (err_request[QStringLiteral("context")].toString() == QStringLiteral("joinGroup")) {
        emit joiningGroupFailed();
    }
}

void VKHelper::HandleUsersGetResponse(const QString &response, const QVariantMap &resp_request)
{
    if (resp_request[QStringLiteral("context")].toString() == QStringLiteral("updateUser")) {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains(QStringLiteral("response"))) {
            QJsonArray json_response = json_document.object().value(QStringLiteral("response")).toArray();

            if (json_response.count() == 1) {
                QJsonObject json_user = json_response[0].toObject();

                if (json_user.contains(QStringLiteral("id"))) {
                    QString user_id = QString::number(json_user.value(QStringLiteral("id")).toVariant().toLongLong());

                    if (UserId != user_id) {
                        UserId = user_id;

                        emit userIdChanged(UserId);
                    }
                } else if (UserId != QLatin1String("")) {
                    UserId = QLatin1String("");

                    emit userIdChanged(UserId);
                }

                if (json_user.contains(QStringLiteral("first_name"))) {
                    QString first_name = json_user.value(QStringLiteral("first_name")).toString();

                    if (FirstName != first_name) {
                        FirstName = first_name;

                        emit firstNameChanged(FirstName);
                    }
                } else if (FirstName != QLatin1String("")) {
                    FirstName = QLatin1String("");

                    emit firstNameChanged(FirstName);
                }

                if (json_user.contains(QStringLiteral("last_name"))) {
                    QString last_name = json_user.value(QStringLiteral("last_name")).toString();

                    if (LastName != last_name) {
                        LastName = last_name;

                        emit lastNameChanged(LastName);
                    }
                } else if (LastName != QLatin1String("")) {
                    LastName = QLatin1String("");

                    emit lastNameChanged(LastName);
                }

                if (json_user.contains(QStringLiteral("photo_100"))) {
                    QString photo_url = json_user.value(QStringLiteral("photo_100")).toString();

                    if (PhotoUrl != photo_url) {
                        PhotoUrl = photo_url;

                        emit photoUrlChanged(PhotoUrl);
                    }
                } else if (PhotoUrl != DEFAULT_PHOTO_URL) {
                    PhotoUrl = DEFAULT_PHOTO_URL;

                    emit photoUrlChanged(PhotoUrl);
                }

                if (json_user.contains(QStringLiteral("photo_200"))) {
                    QString big_photo_url = json_user.value(QStringLiteral("photo_200")).toString();

                    if (BigPhotoUrl != big_photo_url) {
                        BigPhotoUrl = big_photo_url;

                        emit bigPhotoUrlChanged(BigPhotoUrl);
                    }
                } else if (BigPhotoUrl != DEFAULT_PHOTO_URL) {
                    BigPhotoUrl = DEFAULT_PHOTO_URL;

                    emit bigPhotoUrlChanged(BigPhotoUrl);
                }
            } else {
                qWarning() << "HandleUsersGetResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleUsersGetResponse() : invalid json";
        }
    }
}

void VKHelper::HandleUsersGetError(const QVariantMap &err_request)
{
    Q_UNUSED(err_request)
}
