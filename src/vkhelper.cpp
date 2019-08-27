#include <QtCore/QByteArray>
#include <QtCore/QDateTime>
#include <QtCore/QVariant>
#include <QtCore/QStringList>
#include <QtCore/QRandomGenerator>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QRegExp>
#include <QtCore/QDebug>
#include <QtAndroidExtras/QtAndroid>

#include "vkhelper.h"

const QString VKHelper::AUTH_SCOPE               ("[\"friends\", \"notes\", \"groups\", \"offline\"]");
const QString VKHelper::DEFAULT_PHOTO_URL        ("https://vk.com/images/camera_100.png");
const QString VKHelper::DATA_NOTE_TITLE          ("VKGeo Data");
const QString VKHelper::TRUSTED_FRIENDS_LIST_NAME("VKGeo Trusted Friends");
const QString VKHelper::TRACKED_FRIENDS_LIST_NAME("VKGeo Tracked Friends");

QAndroidJniObject VKHelper::AndroidContext;

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
    CurrentDataState                 = DataNotUpdated;
    AuthState                        = VKAuthState::StateUnknown;
    MaxTrustedFriendsCount           = DEFAULT_MAX_TRUSTED_FRIENDS_COUNT;
    MaxTrackedFriendsCount           = DEFAULT_MAX_TRACKED_FRIENDS_COUNT;
    SendDataTryNumber                = 0;
    LastSendDataTime                 = 0;
    LastUpdateTrackedFriendsDataTime = 0;
    NextRequestQueueTimerTimeout     = 0;
    PhotoUrl                         = DEFAULT_PHOTO_URL;
    BigPhotoUrl                      = DEFAULT_PHOTO_URL;

    connect(&RequestQueueTimer, &QTimer::timeout, this, &VKHelper::handleRequestQueueTimerTimeout);

    RequestQueueTimer.setInterval(REQUEST_QUEUE_TIMER_INTERVAL);

    connect(&SendDataOnUpdateTimer, &QTimer::timeout, this, &VKHelper::handleSendDataOnUpdateTimerTimeout);

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
    return CurrentData.contains("update_time") &&
           CurrentData.contains("latitude") &&
           CurrentData.contains("longitude");
}

qint64 VKHelper::locationUpdateTime() const
{
    if (CurrentData.contains("update_time")) {
        return CurrentData["update_time"].toLongLong();
    } else {
        return 0;
    }
}

qreal VKHelper::locationLatitude() const
{
    if (CurrentData.contains("latitude")) {
        return CurrentData["latitude"].toDouble();
    } else {
        return 0.0;
    }
}

qreal VKHelper::locationLongitude() const
{
    if (CurrentData.contains("longitude")) {
        return CurrentData["longitude"].toDouble();
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

void VKHelper::initVK()
{
    AndroidContext.callMethod<void>("initVK");
}

void VKHelper::login()
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
    CurrentDataState           = DataUpdated;
    CurrentData["update_time"] = QDateTime::currentSecsSinceEpoch();
    CurrentData["latitude"]    = latitude;
    CurrentData["longitude"]   = longitude;

    emit locationUpdated();

    SendDataOnUpdateTimer.start();
}

void VKHelper::updateBatteryStatus(const QString &status, int level)
{
    CurrentDataState              = DataUpdated;
    CurrentData["update_time"]    = QDateTime::currentSecsSinceEpoch();
    CurrentData["battery_status"] = status;
    CurrentData["battery_level"]  = level;

    emit batteryStatusUpdated();

    SendDataOnUpdateTimer.start();
}

void VKHelper::sendData()
{
    SendData(true);
}

void VKHelper::updateFriends()
{
    if (!ContextHasActiveRequests("updateFriends")) {
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
    return FriendsData;
}

QVariantList VKHelper::getFriendsList()
{
    QVariantList friends_list = FriendsData.values();

    std::sort(friends_list.begin(), friends_list.end(), compareFriends);

    return friends_list;
}

void VKHelper::updateTrustedFriendsList(const QVariantList &trusted_friends_list)
{
    if (!ContextHasActiveRequests("updateTrustedFriendsList")) {
        QStringList user_id_list;

        for (const QString &key : FriendsData.keys()) {
            QVariantMap frnd = FriendsData[key].toMap();

            frnd["trusted"] = false;

            FriendsData[key] = frnd;
        }

        for (int i = 0; i < trusted_friends_list.count() && i < MaxTrustedFriendsCount; i++) {
            QString user_id = trusted_friends_list[i].toString();

            user_id_list.append(user_id);

            if (FriendsData.contains(user_id)) {
                QVariantMap frnd = FriendsData[user_id].toMap();

                frnd["trusted"] = true;
                frnd["tracked"] = false;

                FriendsData[user_id] = frnd;
            }
        }

        QVariantMap request, parameters;

        if (TrustedFriendsListId == "") {
            request["method"]   = "friends.getLists";
            request["context"]  = "updateTrustedFriendsList";
            request["user_ids"] = user_id_list.join(",");
        } else {
            parameters["list_id"]  = TrustedFriendsListId.toLongLong();
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

void VKHelper::updateTrackedFriendsList(const QVariantList &tracked_friends_list)
{
    if (!ContextHasActiveRequests("updateTrackedFriendsList")) {
        QStringList user_id_list;

        for (const QString &key : FriendsData.keys()) {
            QVariantMap frnd = FriendsData[key].toMap();

            frnd["tracked"] = false;

            FriendsData[key] = frnd;
        }

        for (int i = 0; i < tracked_friends_list.count() && i < MaxTrackedFriendsCount; i++) {
            QString user_id = tracked_friends_list[i].toString();

            user_id_list.append(user_id);

            if (FriendsData.contains(user_id)) {
                QVariantMap frnd = FriendsData[user_id].toMap();

                if (!frnd.contains("trusted") || !frnd["trusted"].toBool()) {
                    frnd["tracked"] = true;
                }

                FriendsData[user_id] = frnd;
            }
        }

        QVariantMap request, parameters;

        if (TrackedFriendsListId == "") {
            request["method"]   = "friends.getLists";
            request["context"]  = "updateTrackedFriendsList";
            request["user_ids"] = user_id_list.join(",");
        } else {
            parameters["list_id"]  = TrackedFriendsListId.toLongLong();
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

void VKHelper::updateTrackedFriendsData(bool expedited)
{
    qint64 elapsed = QDateTime::currentSecsSinceEpoch() - LastUpdateTrackedFriendsDataTime;

    if (expedited || elapsed < 0 || elapsed > UPDATE_TRACKED_FRIENDS_DATA_INTERVAL) {
        LastUpdateTrackedFriendsDataTime = QDateTime::currentSecsSinceEpoch();

        for (const QString &key : FriendsData.keys()) {
            QVariantMap frnd = FriendsData[key].toMap();

            if ((frnd.contains("trusted") && frnd["trusted"].toBool()) ||
                (frnd.contains("tracked") && frnd["tracked"].toBool())) {
                bool is_closed         = frnd.contains("isClosed")        && frnd["isClosed"].toBool();
                bool can_access_closed = frnd.contains("canAccessClosed") && frnd["canAccessClosed"].toBool();

                if (!is_closed || can_access_closed) {
                    QVariantMap request, parameters;

                    parameters["count"]   = MAX_NOTES_GET_COUNT;
                    parameters["sort"]    = 0;
                    parameters["user_id"] = key.toLongLong();

                    request["method"]     = "notes.get";
                    request["context"]    = "updateTrackedFriendsData";
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                }
            }
        }
    }
}

void VKHelper::joinGroup(const QString &group_id)
{
    QVariantMap request, parameters;

    parameters["group_id"] = group_id.toLongLong();

    request["method"]     = "groups.join";
    request["context"]    = "joinGroup";
    request["parameters"] = parameters;

    EnqueueRequest(request);
}

void VKHelper::setAuthState(int state)
{
    AuthState = state;

    emit authStateChanged(AuthState);

    if (AuthState == VKAuthState::StateAuthorized) {
        QVariantMap request, parameters;

        parameters["fields"] = "photo_100,photo_200";

        request["method"]     = "users.get";
        request["context"]    = "updateUser";
        request["parameters"] = parameters;

        EnqueueRequest(request);
    } else if (AuthState == VKAuthState::StateNotAuthorized) {
        Cleanup();
    }
}

void VKHelper::handleResponse(const QString &response, const QString &resp_request_str)
{
    QVariantMap resp_request = QJsonDocument::fromJson(resp_request_str.toUtf8()).toVariant().toMap();

    if (resp_request.contains("method") && resp_request.contains("context")) {
        ContextTrackerDelRequest(resp_request);

        if (resp_request["method"].toString() == "notes.get") {
            HandleNotesGetResponse(response, resp_request);
        } else if (resp_request["method"].toString() == "notes.add") {
            HandleNotesAddResponse(response, resp_request);
        } else if (resp_request["method"].toString() == "notes.delete") {
            HandleNotesDeleteResponse(response, resp_request);
        } else if (resp_request["method"].toString() == "friends.get") {
            HandleFriendsGetResponse(response, resp_request);
        } else if (resp_request["method"].toString() == "friends.getLists") {
            HandleFriendsGetListsResponse(response, resp_request);
        } else if (resp_request["method"].toString() == "friends.addList") {
            HandleFriendsAddListResponse(response, resp_request);
        } else if (resp_request["method"].toString() == "friends.editList") {
            HandleFriendsEditListResponse(response, resp_request);
        } else if (resp_request["method"].toString() == "groups.join") {
            HandleGroupsJoinResponse(response, resp_request);
        } else if (resp_request["method"].toString() == "users.get") {
            HandleUsersGetResponse(response, resp_request);
        } else {
            qWarning() << QString("handleResponse() : unknown request method: %1").arg(resp_request["method"].toString());
        }
    } else {
        qWarning() << "handleResponse() : invalid request";
    }
}

void VKHelper::handleError(const QString &error_message, const QString &err_request_str)
{
    QVariantMap err_request = QJsonDocument::fromJson(err_request_str.toUtf8()).toVariant().toMap();

    if (err_request.contains("method") && err_request.contains("context")) {
        ContextTrackerDelRequest(err_request);

        if (err_request["method"].toString() == "notes.get") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleNotesGetError(err_request);
        } else if (err_request["method"].toString() == "notes.add") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleNotesAddError(err_request);
        } else if (err_request["method"].toString() == "notes.delete") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleNotesDeleteError(err_request);
        } else if (err_request["method"].toString() == "friends.get") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleFriendsGetError(err_request);
        } else if (err_request["method"].toString() == "friends.getLists") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleFriendsGetListsError(err_request);
        } else if (err_request["method"].toString() == "friends.addList") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleFriendsAddListError(err_request);
        } else if (err_request["method"].toString() == "friends.editList") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleFriendsEditListError(err_request);
        } else if (err_request["method"].toString() == "groups.join") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleGroupsJoinError(err_request);
        } else if (err_request["method"].toString() == "users.get") {
            qWarning() << QString("handleError() : %1 request failed : %2").arg(err_request["method"].toString())
                                                                           .arg(error_message);

            HandleUsersGetError(err_request);
        } else {
            qWarning() << QString("handleError() : unknown request method: %1").arg(err_request["method"].toString());
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

            if (request.contains("method") && request.contains("context")) {
                if (AuthState == VKAuthState::StateAuthorized) {
                    request_list.append(request);
                } else {
                    ContextTrackerDelRequest(request);
                }
            } else {
                qWarning() << "requestQueueTimerTimeout() : invalid request";

                ContextTrackerDelRequest(request);
            }
        }

        if (request_list.count() > 0) {
            QAndroidJniObject j_request_list = QAndroidJniObject::fromString(QJsonDocument::fromVariant(request_list).toJson(QJsonDocument::Compact));

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

void VKHelper::handleSendDataOnUpdateTimerTimeout()
{
    SendData(false);
}

void VKHelper::handleSendDataTimerTimeout()
{
    SendData(false);
}

void VKHelper::Cleanup()
{
    LastSendDataTime                 = 0;
    LastUpdateTrackedFriendsDataTime = 0;
    NextRequestQueueTimerTimeout     = QDateTime::currentMSecsSinceEpoch() + REQUEST_QUEUE_TIMER_INTERVAL;
    UserId                           = "";
    FirstName                        = "";
    LastName                         = "";
    PhotoUrl                         = DEFAULT_PHOTO_URL;
    BigPhotoUrl                      = DEFAULT_PHOTO_URL;
    TrustedFriendsListId             = "";
    TrackedFriendsListId             = "";

    emit userIdChanged(UserId);
    emit firstNameChanged(FirstName);
    emit lastNameChanged(LastName);
    emit photoUrlChanged(PhotoUrl);
    emit bigPhotoUrlChanged(BigPhotoUrl);

    while (!RequestQueue.isEmpty()) {
        QVariantMap request = RequestQueue.dequeue();

        ContextTrackerDelRequest(request);
    }

    RequestQueueTimer.stop();

    AndroidContext.callMethod<void>("cancelAllVKRequests");

    FriendsData.clear();
    FriendsDataTmp.clear();

    emit friendsCountChanged(FriendsData.count());
    emit friendsUpdated();
}

void VKHelper::SendData(bool expedited)
{
    if (CurrentDataState == DataUpdated || (CurrentDataState == DataUpdatedAndSent &&
                                            SendDataTryNumber < MAX_SEND_DATA_TRIES_COUNT)) {
        qint64 elapsed = QDateTime::currentSecsSinceEpoch() - LastSendDataTime;

        if (!ContextHasActiveRequests("sendData") &&
            AuthState == VKAuthState::StateAuthorized &&
            (expedited || elapsed < 0 || elapsed > SEND_DATA_INTERVAL)) {
            QVariantMap request, parameters;

            QString user_data_string = QString("{{{%1}}}").arg(QString::fromUtf8(QJsonDocument::fromVariant(CurrentData)
                                                                                 .toJson(QJsonDocument::Compact)
                                                                                 .toBase64()));

            if (TrustedFriendsListId == "") {
                request["method"]    = "friends.getLists";
                request["context"]   = "sendData";
                request["user_data"] = user_data_string;
            } else {
                parameters["count"] = MAX_NOTES_GET_COUNT;
                parameters["sort"]  = 0;

                request["method"]     = "notes.get";
                request["context"]    = "sendData";
                request["user_data"]  = user_data_string;
                request["parameters"] = parameters;
            }

            EnqueueRequest(request);

            if (CurrentDataState == DataUpdatedAndSent) {
                SendDataTryNumber = SendDataTryNumber + 1;
            } else {
                SendDataTryNumber = 0;
            }

            CurrentDataState = DataUpdatedAndSent;
        }

        if (!SendDataTimer.isActive()) {
            SendDataTimer.start();
        }
    } else {
        SendDataTimer.stop();
    }
}

void VKHelper::ContextTrackerAddRequest(const QVariantMap &request)
{
    if (request.contains("context")) {
        QString context = request["context"].toString();

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
        qWarning() << "ContextTrackerDelRequest() : request has no context";
    }
}

bool VKHelper::ContextHasActiveRequests(const QString &context)
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
    if (resp_request["context"].toString() == "sendData") {
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

                    if (json_note.contains("id") && json_note.contains("title") &&
                        json_note.value("title").toString() == DATA_NOTE_TITLE) {
                        QString data_note_id = QString::number(json_note.value("id").toVariant().toLongLong());

                        if (data_note_id != "") {
                            notes_to_delete.append(data_note_id);
                        }
                    }
                }

                if (resp_request.contains("user_data")) {
                    QVariantMap request, parameters;

                    if (json_items.count() > 0 && offset + json_items.count() < notes_count) {
                        parameters["count"]  = MAX_NOTES_GET_COUNT;
                        parameters["offset"] = offset + json_items.count();
                        parameters["sort"]   = 0;

                        request["method"]    = "notes.get";
                        request["context"]   = resp_request["context"].toString();
                        request["user_data"] = resp_request["user_data"].toString();

                        if (notes_to_delete.count() > 0) {
                            request["notes_to_delete"] = notes_to_delete.join(",");
                        }

                        request["parameters"] = parameters;
                    } else {
                        parameters["title"]           = DATA_NOTE_TITLE;
                        parameters["text"]            = resp_request["user_data"].toString();
                        parameters["privacy_comment"] = "nobody";

                        if (TrustedFriendsListId == "") {
                            parameters["privacy_view"] = "nobody";
                        } else {
                            parameters["privacy_view"] = QString("list%1").arg(TrustedFriendsListId);
                        }

                        request["method"]  = "notes.add";
                        request["context"] = resp_request["context"].toString();

                        if (notes_to_delete.count() > 0) {
                            request["notes_to_delete"] = notes_to_delete.join(",");
                        }

                        request["parameters"] = parameters;
                    }

                    EnqueueRequest(request);
                } else {
                    qWarning() << "HandleNotesGetResponse() : invalid request";
                }
            } else {
                qWarning() << "HandleNotesGetResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleNotesGetResponse() : invalid json";
        }
    } else if (resp_request["context"].toString() == "updateTrackedFriendsData") {
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

                    if (json_note.contains("title") && json_note.contains("text") &&
                        json_note.value("title").toString() == DATA_NOTE_TITLE) {
                        data_note_found = true;

                        if (user_id != "") {
                            QString note_text = json_note.value("text").toString();
                            QRegExp base64_regexp("\\{\\{\\{([^\\}]+)\\}\\}\\}");

                            if (base64_regexp.indexIn(note_text) != -1) {
                                QString note_base64 = base64_regexp.cap(1);

                                emit trackedFriendDataUpdated(user_id, QJsonDocument::fromJson(QByteArray::fromBase64(note_base64.toUtf8())).toVariant().toMap());
                            } else {
                                qWarning() << "HandleNotesGetResponse() : invalid user data";
                            }
                        } else {
                            qWarning() << "HandleNotesGetResponse() : invalid request";
                        }

                        break;
                    }
                }

                if (!data_note_found) {
                    if (user_id != "") {
                        if (json_items.count() > 0 && offset + json_items.count() < notes_count) {
                            QVariantMap request, parameters;

                            parameters["count"]   = MAX_NOTES_GET_COUNT;
                            parameters["offset"]  = offset + json_items.count();
                            parameters["sort"]    = 0;
                            parameters["user_id"] = user_id.toLongLong();

                            request["method"]     = "notes.get";
                            request["context"]    = resp_request["context"].toString();
                            request["parameters"] = parameters;

                            EnqueueRequest(request);
                        }
                    } else {
                        qWarning() << "HandleNotesGetResponse() : invalid request";
                    }
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

    if (resp_request["context"].toString() == "sendData") {
        QStringList notes_to_delete;

        if (resp_request.contains("notes_to_delete")) {
            notes_to_delete = resp_request["notes_to_delete"].toString().split(",");
        }

        for (int i = 0; i < notes_to_delete.count(); i++) {
            QVariantMap request, parameters;

            parameters["note_id"] = notes_to_delete[i].toLongLong();

            request["method"]     = "notes.delete";
            request["context"]    = resp_request["context"].toString();
            request["parameters"] = parameters;

            EnqueueRequest(request);
        }

        LastSendDataTime = QDateTime::currentSecsSinceEpoch();

        if (CurrentDataState != DataUpdated) {
            CurrentDataState = DataNotUpdated;

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

                                frnd["userId"]  = QString::number(json_friend.value("id").toVariant().toLongLong());
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
                                if (json_friend.contains("is_closed")) {
                                    frnd["isClosed"] = json_friend.value("is_closed").toBool();
                                } else {
                                    frnd["isClosed"] = false;
                                }
                                if (json_friend.contains("can_access_closed")) {
                                    frnd["canAccessClosed"] = json_friend.value("can_access_closed").toBool();
                                } else {
                                    frnd["canAccessClosed"] = false;
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
                                    frnd["online"] = (json_friend.value("online").toInt() != 0);
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
                                        frnd["lastSeenTime"] = QString::number(json_last_seen["time"].toVariant().toLongLong());
                                    } else {
                                        frnd["lastSeenTime"] = "";
                                    }
                                } else {
                                    frnd["lastSeenTime"] = "";
                                }

                                FriendsDataTmp[frnd["userId"].toString()] = frnd;
                            }
                        } else {
                            qWarning() << "HandleFriendsGetResponse() : invalid entry";
                        }
                    }
                } else if (list_id == TrustedFriendsListId) {
                    for (int i = 0; i < json_items.count() && offset + i < MaxTrustedFriendsCount; i++) {
                        QString user_id = QString::number(json_items.at(i).toVariant().toLongLong());

                        if (FriendsDataTmp.contains(user_id)) {
                            QVariantMap frnd = FriendsDataTmp[user_id].toMap();

                            frnd["trusted"] = true;
                            frnd["tracked"] = false;

                            FriendsDataTmp[user_id] = frnd;
                        }
                    }
                } else if (list_id == TrackedFriendsListId) {
                    for (int i = 0; i < json_items.count() && offset + i < MaxTrackedFriendsCount; i++) {
                        QString user_id = QString::number(json_items.at(i).toVariant().toLongLong());

                        if (FriendsDataTmp.contains(user_id)) {
                            QVariantMap frnd = FriendsDataTmp[user_id].toMap();

                            if (!frnd.contains("trusted") || !frnd["trusted"].toBool()) {
                                frnd["tracked"] = true;
                            }

                            FriendsDataTmp[user_id] = frnd;
                        }
                    }
                } else {
                    qWarning() << "HandleFriendsGetResponse() : unknown list id";
                }

                if (json_items.count() > 0 && offset + json_items.count() < friends_count) {
                    QVariantMap request, parameters;

                    parameters["count"]  = MAX_FRIENDS_GET_COUNT;
                    parameters["offset"] = offset + json_items.count();

                    if (fields != "") {
                        parameters["fields"] = fields;
                    }
                    if (list_id != "") {
                        parameters["list_id"] = list_id.toLongLong();
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

                if (!ContextHasActiveRequests(resp_request["context"].toString())) {
                    FriendsData = FriendsDataTmp;

                    emit friendsCountChanged(FriendsData.count());
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
    if (resp_request["context"].toString() == "sendData") {
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
                            trusted_friends_list_id = QString::number(json_list.value("id").toVariant().toLongLong());
                        } else if (json_list.value("name").toString() == TRACKED_FRIENDS_LIST_NAME) {
                            tracked_friends_list_id = QString::number(json_list.value("id").toVariant().toLongLong());
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
                    parameters["sort"]  = 0;

                    request["method"]     = "notes.get";
                    request["context"]    = resp_request["context"].toString();
                    request["user_data"]  = resp_request["user_data"].toString();
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                } else {
                    qWarning() << "HandleFriendsGetListsResponse() : invalid request";
                }
            } else {
                qWarning() << "HandleFriendsGetListsResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleFriendsGetListsResponse() : invalid json";
        }
    } else if (resp_request["context"].toString() == "updateFriends") {
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
                            trusted_friends_list_id = QString::number(json_list.value("id").toVariant().toLongLong());
                        } else if (json_list.value("name").toString() == TRACKED_FRIENDS_LIST_NAME) {
                            tracked_friends_list_id = QString::number(json_list.value("id").toVariant().toLongLong());
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
                    parameters["list_id"] = TrustedFriendsListId.toLongLong();

                    request["method"]     = "friends.get";
                    request["context"]    = resp_request["context"].toString();
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                }
                if (tracked_friends_list_id != "") {
                    TrackedFriendsListId = tracked_friends_list_id;

                    QVariantMap request, parameters;

                    parameters["count"]   = MAX_FRIENDS_GET_COUNT;
                    parameters["list_id"] = TrackedFriendsListId.toLongLong();

                    request["method"]     = "friends.get";
                    request["context"]    = resp_request["context"].toString();
                    request["parameters"] = parameters;

                    EnqueueRequest(request);
                }

                if (!ContextHasActiveRequests(resp_request["context"].toString())) {
                    FriendsData = FriendsDataTmp;

                    emit friendsCountChanged(FriendsData.count());
                    emit friendsUpdated();
                }
            } else {
                qWarning() << "HandleFriendsGetListsResponse() : invalid response";
            }
        } else {
            qWarning() << "HandleFriendsGetListsResponse() : invalid json";
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

                    if (json_list.contains("id") && json_list.contains("name") &&
                        json_list.value("name").toString() == TRUSTED_FRIENDS_LIST_NAME) {
                        trusted_friends_list_id = QString::number(json_list.value("id").toVariant().toLongLong());

                        if (trusted_friends_list_id != "") {
                            break;
                        }
                    }
                }

                if (resp_request.contains("user_ids")) {
                    QVariantMap request, parameters;

                    if (trusted_friends_list_id != "") {
                        TrustedFriendsListId = trusted_friends_list_id;

                        parameters["list_id"]  = TrustedFriendsListId.toLongLong();
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
    } else if (resp_request["context"].toString() == "updateTrackedFriendsList") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("count") && json_response.contains("items")) {
                QString tracked_friends_list_id;

                QJsonArray json_items = json_response.value("items").toArray();

                for (int i = 0; i < json_items.count(); i++) {
                    QJsonObject json_list = json_items.at(i).toObject();

                    if (json_list.contains("id") && json_list.contains("name") &&
                        json_list.value("name").toString() == TRACKED_FRIENDS_LIST_NAME) {
                        tracked_friends_list_id = QString::number(json_list.value("id").toVariant().toLongLong());

                        if (tracked_friends_list_id != "") {
                            break;
                        }
                    }
                }

                if (resp_request.contains("user_ids")) {
                    QVariantMap request, parameters;

                    if (tracked_friends_list_id != "") {
                        TrackedFriendsListId = tracked_friends_list_id;

                        parameters["list_id"]  = TrackedFriendsListId.toLongLong();
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
    if (err_request["context"].toString() == "updateTrustedFriendsList") {
        emit trustedFriendsListUpdateFailed();
    } else if (err_request["context"].toString() == "updateTrackedFriendsList") {
        emit trackedFriendsListUpdateFailed();
    }
}

void VKHelper::HandleFriendsAddListResponse(const QString &response, const QVariantMap &resp_request)
{
    if (resp_request["context"].toString() == "updateTrustedFriendsList") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("list_id")) {
                TrustedFriendsListId = QString::number(json_response.value("list_id").toVariant().toLongLong());

                emit trustedFriendsListUpdated();
            } else {
                qWarning() << "HandleFriendsAddListResponse() : invalid response";

                emit trustedFriendsListUpdateFailed();
            }
        } else {
            qWarning() << "HandleFriendsAddListResponse() : invalid json";

            emit trustedFriendsListUpdateFailed();
        }
    } else if (resp_request["context"].toString() == "updateTrackedFriendsList") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonObject json_response = json_document.object().value("response").toObject();

            if (json_response.contains("list_id")) {
                TrackedFriendsListId = QString::number(json_response.value("list_id").toVariant().toLongLong());

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
    if (err_request["context"].toString() == "updateTrustedFriendsList") {
        emit trustedFriendsListUpdateFailed();
    } else if (err_request["context"].toString() == "updateTrackedFriendsList") {
        emit trackedFriendsListUpdateFailed();
    }
}

void VKHelper::HandleFriendsEditListResponse(const QString &response, const QVariantMap &resp_request)
{
    Q_UNUSED(response)

    if (resp_request["context"].toString() == "updateTrustedFriendsList") {
        emit trustedFriendsListUpdated();
    } else if (resp_request["context"].toString() == "updateTrackedFriendsList") {
        emit trackedFriendsListUpdated();
    }
}

void VKHelper::HandleFriendsEditListError(const QVariantMap &err_request)
{
    if (err_request["context"].toString() == "updateTrustedFriendsList") {
        TrustedFriendsListId = "";

        emit trustedFriendsListUpdateFailed();
    } else if (err_request["context"].toString() == "updateTrackedFriendsList") {
        TrackedFriendsListId = "";

        emit trackedFriendsListUpdateFailed();
    }
}

void VKHelper::HandleGroupsJoinResponse(const QString &response, const QVariantMap &resp_request)
{
    Q_UNUSED(response)

    if (resp_request["context"].toString() == "joinGroup") {
        emit joiningGroupCompleted();
    }
}

void VKHelper::HandleGroupsJoinError(const QVariantMap &err_request)
{
    if (err_request["context"].toString() == "joinGroup") {
        emit joiningGroupFailed();
    }
}

void VKHelper::HandleUsersGetResponse(const QString &response, const QVariantMap &resp_request)
{
    if (resp_request["context"].toString() == "updateUser") {
        QJsonDocument json_document = QJsonDocument::fromJson(response.toUtf8());

        if (!json_document.isNull() && json_document.object().contains("response")) {
            QJsonArray json_response = json_document.object().value("response").toArray();

            if (json_response.count() == 1) {
                QJsonObject json_user = json_response.at(0).toObject();

                if (json_user.contains("id")) {
                    UserId = QString::number(json_user.value("id").toVariant().toLongLong());
                } else {
                    UserId = "";
                }

                emit userIdChanged(UserId);

                if (json_user.contains("first_name")) {
                    FirstName = json_user.value("first_name").toString();
                } else {
                    FirstName = "";
                }

                emit firstNameChanged(FirstName);

                if (json_user.contains("last_name")) {
                    LastName = json_user.value("last_name").toString();
                } else {
                    LastName = "";
                }

                emit lastNameChanged(LastName);

                if (json_user.contains("photo_100")) {
                    PhotoUrl = json_user.value("photo_100").toString();
                } else {
                    PhotoUrl = DEFAULT_PHOTO_URL;
                }

                emit photoUrlChanged(PhotoUrl);

                if (json_user.contains("photo_200")) {
                    BigPhotoUrl = json_user.value("photo_200").toString();
                } else {
                    BigPhotoUrl = DEFAULT_PHOTO_URL;
                }

                emit bigPhotoUrlChanged(BigPhotoUrl);
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
