#ifndef VKHELPER_H
#define VKHELPER_H

#include <QtCore/QtGlobal>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QQueue>
#include <QtCore/QVariantList>
#include <QtCore/QMap>
#include <QtCore/QVariantMap>
#include <QtCore/QTimer>
#include <QtAndroidExtras/QAndroidJniObject>

class VKAuthState : public QObject
{
    Q_OBJECT

public:
    enum AuthState {
        StateUnknown,
        StateNotAuthorized,
        StateAuthorized
    };
    Q_ENUM(AuthState)
};

class VKHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool   locationValid      READ locationValid)
    Q_PROPERTY(qint64 locationUpdateTime READ locationUpdateTime)
    Q_PROPERTY(qreal  locationLatitude   READ locationLatitude)
    Q_PROPERTY(qreal  locationLongitude  READ locationLongitude)

    Q_PROPERTY(int     authState    READ authState    NOTIFY authStateChanged)
    Q_PROPERTY(int     friendsCount READ friendsCount NOTIFY friendsCountChanged)
    Q_PROPERTY(QString userId       READ userId       NOTIFY userIdChanged)
    Q_PROPERTY(QString firstName    READ firstName    NOTIFY firstNameChanged)
    Q_PROPERTY(QString lastName     READ lastName     NOTIFY lastNameChanged)
    Q_PROPERTY(QString photoUrl     READ photoUrl     NOTIFY photoUrlChanged)
    Q_PROPERTY(QString bigPhotoUrl  READ bigPhotoUrl  NOTIFY bigPhotoUrlChanged)

    Q_PROPERTY(int maxTrustedFriendsCount READ maxTrustedFriendsCount WRITE setMaxTrustedFriendsCount NOTIFY maxTrustedFriendsCountChanged)
    Q_PROPERTY(int maxTrackedFriendsCount READ maxTrackedFriendsCount WRITE setMaxTrackedFriendsCount NOTIFY maxTrackedFriendsCountChanged)

private:
    explicit VKHelper(const QString &context, QObject *parent = nullptr);
    ~VKHelper() noexcept override = default;

public:
    static const int DEFAULT_MAX_TRUSTED_FRIENDS_COUNT    = 5,
                     DEFAULT_MAX_TRACKED_FRIENDS_COUNT    = 5,
                     MAX_SEND_DATA_TRIES_COUNT            = 5,
                     REQUEST_QUEUE_TIMER_INTERVAL         = 1000,
                     SEND_DATA_ON_UPDATE_TIMER_INTERVAL   = 100,
                     SEND_DATA_TIMER_INTERVAL             = 60000,
                     SEND_DATA_INTERVAL                   = 300,
                     UPDATE_TRACKED_FRIENDS_DATA_INTERVAL = 60,
                     MAX_BATCH_SIZE                       = 25,
                     MAX_NOTES_GET_COUNT                  = 100,
                     MAX_FRIENDS_GET_COUNT                = 500;

    static const QString AUTH_SCOPE,
                         DEFAULT_PHOTO_URL,
                         DATA_NOTE_TITLE,
                         TRUSTED_FRIENDS_LIST_NAME,
                         TRACKED_FRIENDS_LIST_NAME;

    VKHelper(const VKHelper&) = delete;
    VKHelper(VKHelper&&) noexcept = delete;

    VKHelper& operator=(const VKHelper&) = delete;
    VKHelper& operator=(VKHelper&&) noexcept = delete;

    static VKHelper &GetInstance(const QString &context);

    bool locationValid() const;
    qint64 locationUpdateTime() const;
    qreal locationLatitude() const;
    qreal locationLongitude() const;

    int authState() const;
    int friendsCount() const;
    QString userId() const;
    QString firstName() const;
    QString lastName() const;
    QString photoUrl() const;
    QString bigPhotoUrl() const;

    int maxTrustedFriendsCount() const;
    void setMaxTrustedFriendsCount(int count);

    int maxTrackedFriendsCount() const;
    void setMaxTrackedFriendsCount(int count);

    Q_INVOKABLE void cleanup();

    Q_INVOKABLE void login();
    Q_INVOKABLE void logout();

    Q_INVOKABLE void updateLocation(qreal latitude, qreal longitude);
    Q_INVOKABLE void updateBatteryStatus(const QString &status, int level);
    Q_INVOKABLE void sendData();

    Q_INVOKABLE void updateFriends();
    Q_INVOKABLE QVariantMap getFriends();
    Q_INVOKABLE QVariantList getFriendsList();

    Q_INVOKABLE void updateTrustedFriendsList(const QVariantList &trusted_friends_list);
    Q_INVOKABLE void updateTrackedFriendsList(const QVariantList &tracked_friends_list);

    Q_INVOKABLE void updateTrackedFriendsData(bool expedited);

    Q_INVOKABLE void joinGroup(const QString &group_id);

public slots:
    void setAuthState(int state);
    void processResponse(const QString &response, const QString &resp_request_str);
    void processError(const QString &error_message, const QString &err_request_str);
    void processLocationUpdate(qreal latitude, qreal longitude);
    void processBatteryStatusUpdate(const QString &status, int level);

private slots:
    void requestQueueTimerTimeout();
    void sendDataOnUpdateTimerTimeout();
    void sendDataTimerTimeout();

signals:
    void authStateChanged(int authState);
    void friendsCountChanged(int friendsCount);
    void userIdChanged(const QString &userId);
    void firstNameChanged(const QString &firstName);
    void lastNameChanged(const QString &lastName);
    void photoUrlChanged(const QString &photoUrl);
    void bigPhotoUrlChanged(const QString &bigPhotoUrl);
    void maxTrustedFriendsCountChanged(int maxTrustedFriendsCount);
    void maxTrackedFriendsCountChanged(int maxTrackedFriendsCount);
    void locationUpdated();
    void batteryStatusUpdated();
    void dataSent();
    void friendsUpdated();
    void trustedFriendsListUpdated();
    void trustedFriendsListUpdateFailed();
    void trackedFriendsListUpdated();
    void trackedFriendsListUpdateFailed();
    void trackedFriendDataUpdated(const QString &id, const QVariantMap &data);
    void joiningGroupCompleted();
    void joiningGroupFailed();

private:
    void SendData(bool expedited);

    void ContextTrackerAddRequest(const QVariantMap &request);
    void ContextTrackerDelRequest(const QVariantMap &request);

    bool ContextHasActiveRequests(const QString &context);

    void EnqueueRequest(const QVariantMap &request);

    void ProcessNotesGetResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessNotesGetError(const QVariantMap &err_request);

    void ProcessNotesAddResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessNotesAddError(const QVariantMap &err_request);

    void ProcessNotesDeleteResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessNotesDeleteError(const QVariantMap &err_request);

    void ProcessFriendsGetResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessFriendsGetError(const QVariantMap &err_request);

    void ProcessFriendsGetListsResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessFriendsGetListsError(const QVariantMap &err_request);

    void ProcessFriendsAddListResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessFriendsAddListError(const QVariantMap &err_request);

    void ProcessFriendsEditListResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessFriendsEditListError(const QVariantMap &err_request);

    void ProcessGroupsJoinResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessGroupsJoinError(const QVariantMap &err_request);

    void ProcessUsersGetResponse(const QString &response, const QVariantMap &resp_request);
    void ProcessUsersGetError(const QVariantMap &err_request);

    enum DataState {
        DataNotUpdated,
        DataUpdated,
        DataUpdatedAndSent
    };

    int                 CurrentDataState, AuthState, MaxTrustedFriendsCount,
                        MaxTrackedFriendsCount, SendDataTryNumber;
    qint64              LastSendDataTime, LastUpdateTrackedFriendsDataTime,
                        NextRequestQueueTimerTimeout;
    QString             UserId, FirstName, LastName, PhotoUrl, BigPhotoUrl,
                        TrustedFriendsListId, TrackedFriendsListId;
    QTimer              RequestQueueTimer, SendDataOnUpdateTimer, SendDataTimer;
    QQueue<QVariantMap> RequestQueue;
    QMap<QString, int>  ContextTracker;
    QVariantMap         CurrentData, FriendsData, FriendsDataTmp;
    QAndroidJniObject   Context;
};

#endif // VKHELPER_H
