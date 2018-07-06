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
    static const int UPDATE_FRIENDS_TIMER_INTERVAL = 900000,
                     NEARBY_DISTANCE               = 500;

    explicit VKService(QObject *parent = 0);
    virtual ~VKService();

signals:
    void updateFriends();
    void updateTrackedFriendsLocations(bool expedited);

public slots:
    void authStateChanged(int authState);
    void locationReported();
    void friendsUpdated();
    void trackedFriendLocationUpdated(QString id, qint64 updateTime, qreal latitude, qreal longitude);

private:
    QTimer      UpdateFriendsTimer;
    QVariantMap FriendsData;
};

#endif // VKSERVICE_H
