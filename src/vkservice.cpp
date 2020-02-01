#include <QtCore/QDateTime>
#include <QtPositioning/QGeoCoordinate>
#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "vkhelper.h"
#include "vkservice.h"

VKService::VKService(QObject *parent) : QObject(parent)
{
    LastUpdateFriendsTime = 0;

    connect(&UpdateFriendsTimer, &QTimer::timeout, this, &VKService::handleUpdateFriendsTimerTimeout);

    UpdateFriendsTimer.setInterval(UPDATE_FRIENDS_TIMER_INTERVAL);
    UpdateFriendsTimer.start();
}

VKService &VKService::GetInstance()
{
    static VKService instance;

    return instance;
}

void VKService::handleAuthStateChange(int auth_state)
{
    if (auth_state == VKAuthState::StateNotAuthorized) {
        QtAndroid::androidService().callMethod<void>("showNotLoggedInNotification");
    } else if (auth_state == VKAuthState::StateAuthorized) {
        QtAndroid::androidService().callMethod<void>("hideNotLoggedInNotification");

        QTimer::singleShot(UPDATE_FRIENDS_ON_AUTH_DELAY, this, &VKService::handleUpdateFriendsOnAuthSingleShot);
    }
}

void VKService::handleDataSending()
{
    emit trackedFriendsDataUpdateRequested(true);
}

void VKService::handleFriendsUpdate()
{
    auto vk_helper = qobject_cast<VKHelper *>(sender());

    if (vk_helper != nullptr) {
        QVariantMap friends_data = vk_helper->getFriends();

        for (const QString &key : friends_data.keys()) {
            QVariantMap frnd = friends_data[key].toMap();

            if (FriendsData.contains(key) && FriendsData[key].toMap().contains(QStringLiteral("nearby"))) {
                frnd[QStringLiteral("nearby")] = FriendsData[key].toMap()[QStringLiteral("nearby")].toBool();
            } else {
                frnd[QStringLiteral("nearby")] = false;
            }

            friends_data[key] = frnd;
        }

        FriendsData = friends_data;
    }

    emit trackedFriendsDataUpdateRequested(true);
}

void VKService::handleTrackedFriendDataUpdate(const QString &friend_user_id, const QVariantMap &friend_data)
{
    auto vk_helper = qobject_cast<VKHelper *>(sender());

    if (vk_helper != nullptr && friend_data.contains(QStringLiteral("latitude")) &&
                                friend_data.contains(QStringLiteral("longitude"))) {
        qreal latitude  = friend_data[QStringLiteral("latitude")].toDouble();
        qreal longitude = friend_data[QStringLiteral("longitude")].toDouble();

        if (FriendsData.contains(friend_user_id)) {
            QVariantMap frnd = FriendsData[friend_user_id].toMap();

            if (vk_helper->locationValid()) {
                QGeoCoordinate my_coordinate(vk_helper->locationLatitude(), vk_helper->locationLongitude());
                QGeoCoordinate friend_coordinate(latitude, longitude);

                if (my_coordinate.distanceTo(friend_coordinate) < NEARBY_DISTANCE) {
                    if (!frnd.contains(QStringLiteral("nearby")) || !frnd[QStringLiteral("nearby")].toBool()) {
                        frnd[QStringLiteral("nearby")] = true;

                        if (frnd.contains(QStringLiteral("firstName")) && frnd.contains(QStringLiteral("lastName"))) {
                            QAndroidJniObject j_user_id   = QAndroidJniObject::fromString(friend_user_id);
                            QAndroidJniObject j_user_name = QAndroidJniObject::fromString(QStringLiteral("%1 %2").arg(frnd[QStringLiteral("firstName")].toString())
                                                                                                                 .arg(frnd[QStringLiteral("lastName")].toString()));

                            QtAndroid::androidService().callMethod<void>("showFriendsNearbyNotification", "(Ljava/lang/String;Ljava/lang/String;)V", j_user_id.object<jstring>(),
                                                                                                                                                     j_user_name.object<jstring>());
                        }
                    }
                } else {
                    frnd[QStringLiteral("nearby")] = false;
                }
            }

            FriendsData[friend_user_id] = frnd;
        }
    }
}

void VKService::handleUpdateFriendsOnAuthSingleShot()
{
    emit friendsUpdateRequested();
}

void VKService::handleUpdateFriendsTimerTimeout()
{
    qint64 elapsed = QDateTime::currentSecsSinceEpoch() - LastUpdateFriendsTime;

    if (elapsed < 0 || elapsed > UPDATE_FRIENDS_INTERVAL) {
        LastUpdateFriendsTime = QDateTime::currentSecsSinceEpoch();

        emit friendsUpdateRequested();
    }
}
