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

public:
    static const int UPDATE_FRIENDS_TIMER_INTERVAL = 60000,
                     UPDATE_FRIENDS_INTERVAL       = 600,
                     UPDATE_FRIENDS_ON_AUTH_DELAY  = 15000,
                     NEARBY_DISTANCE               = 500;

    explicit VKService(QObject *parent = nullptr);

    VKService(const VKService&) = delete;
    VKService(VKService&&) noexcept = delete;

    VKService& operator=(const VKService&) = delete;
    VKService& operator=(VKService&&) noexcept = delete;

    ~VKService() noexcept override = default;

public slots:
    void authStateChanged(int auth_state);
    void dataSent();
    void friendsUpdated();
    void trackedFriendDataUpdated(const QString &id, const QVariantMap &data);

private slots:
    void updateFriendsOnAuthSingleShot();
    void updateFriendsTimerTimeout();

signals:
    void updateFriends();
    void updateTrackedFriendsData(bool expedited);

private:
    qint64      LastUpdateFriendsTime;
    QTimer      UpdateFriendsTimer;
    QVariantMap FriendsData;
};

#endif // VKSERVICE_H
