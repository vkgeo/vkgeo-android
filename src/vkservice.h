#ifndef VKSERVICE_H
#define VKSERVICE_H

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QVariantMap>
#include <QtCore/QTimer>

class VKService : public QObject
{
    Q_OBJECT

public:
    static const int UPDATE_FRIENDS_TIMER_INTERVAL = 1000,
                     UPDATE_FRIENDS_INTERVAL       = 600,
                     UPDATE_FRIENDS_ON_AUTH_DELAY  = 15000,
                     NEARBY_DISTANCE               = 500;

    explicit VKService(QObject *parent = 0);
    virtual ~VKService();

public slots:
    void authStateChanged(int authState);
    void locationReported();
    void friendsUpdated();
    void trackedFriendLocationUpdated(QString id, qint64 updateTime, qreal latitude, qreal longitude);

private slots:
    void updateFriendsOnAuthSingleShot();
    void updateFriendsTimerTimeout();

signals:
    void updateFriends();
    void updateTrackedFriendsLocations(bool expedited);

private:
    qint64      LastUpdateFriendsTime;
    QTimer      UpdateFriendsTimer;
    QVariantMap FriendsData;
};

#endif // VKSERVICE_H
