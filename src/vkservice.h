#ifndef VKSERVICE_H
#define VKSERVICE_H

#include <QtCore/QtGlobal>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QVariantMap>
#include <QtCore/QTimer>

class VKService : public QObject
{
    Q_OBJECT

private:
    explicit VKService(QObject *parent = nullptr);
    ~VKService() noexcept override = default;

public:
    static constexpr int UPDATE_FRIENDS_TIMER_INTERVAL = 60000,
                         UPDATE_FRIENDS_INTERVAL       = 600,
                         UPDATE_FRIENDS_ON_AUTH_DELAY  = 15000,
                         NEARBY_DISTANCE               = 500;

    VKService(const VKService &) = delete;
    VKService(VKService &&) noexcept = delete;

    VKService &operator=(const VKService &) = delete;
    VKService &operator=(VKService &&) noexcept = delete;

    static VKService &GetInstance();

public slots:
    void handleAuthStateChange(int auth_state);
    void handleDataSending();
    void handleFriendsUpdate();
    void handleTrackedFriendDataUpdate(const QString &friend_user_id, const QVariantMap &friend_data);

private slots:
    void handleUpdateFriendsOnAuthSingleShot();
    void handleUpdateFriendsTimerTimeout();

signals:
    void friendsUpdateRequested();
    void trackedFriendsDataUpdateRequested(bool expedited);

private:
    qint64      LastUpdateFriendsTime;
    QTimer      UpdateFriendsTimer;
    QVariantMap FriendsData;
};

#endif // VKSERVICE_H
