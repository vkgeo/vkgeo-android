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

class VKAuthState
{
    Q_GADGET

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

    Q_PROPERTY(bool   locationValid READ locationValid)
    Q_PROPERTY(qint64 updateTime    READ updateTime)
    Q_PROPERTY(qreal  latitude      READ latitude)
    Q_PROPERTY(qreal  longitude     READ longitude)

    Q_PROPERTY(int     authState    READ authState    NOTIFY authStateChanged)
    Q_PROPERTY(int     friendsCount READ friendsCount NOTIFY friendsCountChanged)
    Q_PROPERTY(QString userId       READ userId       NOTIFY userIdChanged)
    Q_PROPERTY(QString firstName    READ firstName    NOTIFY firstNameChanged)
    Q_PROPERTY(QString lastName     READ lastName     NOTIFY lastNameChanged)
    Q_PROPERTY(QString photoUrl     READ photoUrl     NOTIFY photoUrlChanged)
    Q_PROPERTY(QString bigPhotoUrl  READ bigPhotoUrl  NOTIFY bigPhotoUrlChanged)

    Q_PROPERTY(bool encryptionEnabled      READ encryptionEnabled      WRITE setEncryptionEnabled      NOTIFY encryptionEnabledChanged)
    Q_PROPERTY(int  maxTrustedFriendsCount READ maxTrustedFriendsCount WRITE setMaxTrustedFriendsCount NOTIFY maxTrustedFriendsCountChanged)
    Q_PROPERTY(int  maxTrackedFriendsCount READ maxTrackedFriendsCount WRITE setMaxTrackedFriendsCount NOTIFY maxTrackedFriendsCountChanged)

private:
    explicit VKHelper(QObject *parent = nullptr);
    ~VKHelper() noexcept override = default;

public:
    VKHelper(const VKHelper &) = delete;
    VKHelper(VKHelper &&) noexcept = delete;

    VKHelper &operator=(const VKHelper &) = delete;
    VKHelper &operator=(VKHelper &&) noexcept = delete;

    static VKHelper &GetInstance();

    bool locationValid() const;
    qint64 updateTime() const;
    qreal latitude() const;
    qreal longitude() const;

    int authState() const;
    int friendsCount() const;
    QString userId() const;
    QString firstName() const;
    QString lastName() const;
    QString photoUrl() const;
    QString bigPhotoUrl() const;

    bool encryptionEnabled() const;
    void setEncryptionEnabled(bool enabled);

    int maxTrustedFriendsCount() const;
    void setMaxTrustedFriendsCount(int count);

    int maxTrackedFriendsCount() const;
    void setMaxTrackedFriendsCount(int count);

    Q_INVOKABLE void initVK() const;

    Q_INVOKABLE void login() const;
    Q_INVOKABLE void logout();

    Q_INVOKABLE void updateLocation(qreal latitude, qreal longitude);
    Q_INVOKABLE void updateBatteryStatus(const QString &status, int level);
    Q_INVOKABLE void sendDataImmediately();

    Q_INVOKABLE void updateFriends();
    Q_INVOKABLE QVariantMap getFriends() const;
    Q_INVOKABLE QVariantList getFriendsList() const;

    Q_INVOKABLE void updateTrustedFriendsList(const QVariantList &trusted_friends_list);
    Q_INVOKABLE void updateTrackedFriendsList(const QVariantList &tracked_friends_list);

    Q_INVOKABLE void updateTrackedFriendsData(bool immediately);

    Q_INVOKABLE void joinGroup(const QString &group_id);

    static QAndroidJniObject AndroidContext;

public slots:
    void setAuthState(int state);
    void handleResponse(const QString &response, const QString &resp_request_str);
    void handleError(const QString &error_message, const QString &err_request_str);
    void handleLocationUpdate(qreal latitude, qreal longitude);
    void handleBatteryStatusUpdate(const QString &status, int level);

private slots:
    void handleRequestQueueTimerTimeout();
    void handleSendDataTimerTimeout();

signals:
    void authStateChanged(int authState);
    void friendsCountChanged(int friendsCount);
    void userIdChanged(const QString &userId);
    void firstNameChanged(const QString &firstName);
    void lastNameChanged(const QString &lastName);
    void photoUrlChanged(const QString &photoUrl);
    void bigPhotoUrlChanged(const QString &bigPhotoUrl);
    void encryptionEnabledChanged(bool encryptionEnabled);
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
    void trackedFriendDataUpdated(const QString &friendUserId, const QVariantMap &friendData);
    void joiningGroupCompleted();
    void joiningGroupFailed();

private:
    void Cleanup();

    void SendData();

    void ContextTrackerAddRequest(const QVariantMap &request);
    void ContextTrackerDelRequest(const QVariantMap &request);

    bool ContextHasActiveRequests(const QString &context) const;

    void EnqueueRequest(const QVariantMap &request);

    void HandleNotesGetResponse(const QString &response, const QVariantMap &resp_request);
    void HandleNotesGetError(const QVariantMap &err_request);

    void HandleNotesAddResponse(const QString &response, const QVariantMap &resp_request);
    void HandleNotesAddError(const QVariantMap &err_request);

    void HandleNotesDeleteResponse(const QString &response, const QVariantMap &resp_request);
    void HandleNotesDeleteError(const QVariantMap &err_request);

    void HandleFriendsGetResponse(const QString &response, const QVariantMap &resp_request);
    void HandleFriendsGetError(const QVariantMap &err_request);

    void HandleFriendsGetListsResponse(const QString &response, const QVariantMap &resp_request);
    void HandleFriendsGetListsError(const QVariantMap &err_request);

    void HandleFriendsAddListResponse(const QString &response, const QVariantMap &resp_request);
    void HandleFriendsAddListError(const QVariantMap &err_request);

    void HandleFriendsEditListResponse(const QString &response, const QVariantMap &resp_request);
    void HandleFriendsEditListError(const QVariantMap &err_request);

    void HandleGroupsJoinResponse(const QString &response, const QVariantMap &resp_request);
    void HandleGroupsJoinError(const QVariantMap &err_request);

    void HandleUsersGetResponse(const QString &response, const QVariantMap &resp_request);
    void HandleUsersGetError(const QVariantMap &err_request);

    static constexpr int REQUEST_QUEUE_TIMER_INTERVAL         = 1000,
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
                         TRACKED_FRIENDS_LIST_NAME,
                         ENCRYPTED_PAYLOAD_COOKIE;

    enum DataState {
        StateNoNewData,
        StateNewDataArrived,
        StateDataIsBeingSent
    };

    bool                EncryptionEnabled;
    int                 CurrentDataState, AuthState, MaxTrustedFriendsCount,
                        MaxTrackedFriendsCount;
    qint64              LastSendDataTime, LastUpdateTrackedFriendsDataTime,
                        NextRequestQueueTimerTimeout;
    QString             UserId, FirstName, LastName, PhotoUrl, BigPhotoUrl,
                        TrustedFriendsListId, TrackedFriendsListId;
    QTimer              RequestQueueTimer, SendDataOnUpdateTimer, SendDataTimer;
    QQueue<QVariantMap> RequestQueue;
    QMap<QString, int>  ContextTracker;
    QVariantMap         CurrentData, FriendsData, FriendsDataTmp;
};

#endif // VKHELPER_H
