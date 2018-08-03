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
    static const int UPDATE_FRIENDS_TIMER_INTERVAL = 1000,
                     UPDATE_FRIENDS_INTERVAL       = 600,
                     UPDATE_FRIENDS_ON_AUTH_DELAY  = 15000,
                     NEARBY_DISTANCE               = 500;

    explicit VKService(QObject *parent = nullptr);
    virtual ~VKService();

public slots:
    void authStateChanged(int authState);
    void dataSent();
    void friendsUpdated();
    void trackedFriendDataUpdated(QString id, QVariantMap data);

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
