#include <QtCore/QString>
#include <QtCore/QLocale>
#include <QtCore/QTranslator>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidService>

#include "androidgw.h"
#include "admobhelper.h"
#include "batteryhelper.h"
#include "uihelper.h"
#include "vkhelper.h"
#include "vkservice.h"

int main(int argc, char *argv[])
{
    if (argc == 1) {
        QTranslator     translator;
        QGuiApplication app(argc, argv);

        if (translator.load(QString(":/tr/vkgeo_%1").arg(QLocale::system().name()))) {
            QGuiApplication::installTranslator(&translator);
        }

        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::setBannerViewHeight, &AdMobHelper::GetInstance(),        &AdMobHelper::setBannerViewHeight);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::setAuthState,        &VKHelper::GetInstance("ACTIVITY"), &VKHelper::setAuthState);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::processResponse,     &VKHelper::GetInstance("ACTIVITY"), &VKHelper::processResponse);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::processError,        &VKHelper::GetInstance("ACTIVITY"), &VKHelper::processError);

        qmlRegisterType<VKAuthState>("VKHelper", 1, 0, "VKAuthState");

        QQmlApplicationEngine engine;

        engine.rootContext()->setContextProperty(QStringLiteral("AdMobHelper"), &AdMobHelper::GetInstance());
        engine.rootContext()->setContextProperty(QStringLiteral("BatteryHelper"), &BatteryHelper::GetInstance());
        engine.rootContext()->setContextProperty(QStringLiteral("UIHelper"), &UIHelper::GetInstance());
        engine.rootContext()->setContextProperty(QStringLiteral("VKHelper"), &VKHelper::GetInstance("ACTIVITY"));

        engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

        QtAndroid::hideSplashScreen();

        if (engine.rootObjects().isEmpty())
            return -1;

        return QGuiApplication::exec();
    } else if (argc == 2 && QString(argv[1]) == "-service") {
        QAndroidService app(argc, argv);

        QObject::connect(&AndroidGW::GetInstance(),         &AndroidGW::setAuthState,               &VKHelper::GetInstance("SERVICE"), &VKHelper::setAuthState);
        QObject::connect(&AndroidGW::GetInstance(),         &AndroidGW::processResponse,            &VKHelper::GetInstance("SERVICE"), &VKHelper::processResponse);
        QObject::connect(&AndroidGW::GetInstance(),         &AndroidGW::processError,               &VKHelper::GetInstance("SERVICE"), &VKHelper::processError);
        QObject::connect(&AndroidGW::GetInstance(),         &AndroidGW::processLocationUpdate,      &VKHelper::GetInstance("SERVICE"), &VKHelper::processLocationUpdate);
        QObject::connect(&AndroidGW::GetInstance(),         &AndroidGW::processBatteryStatusUpdate, &VKHelper::GetInstance("SERVICE"), &VKHelper::processBatteryStatusUpdate);
        QObject::connect(&VKHelper::GetInstance("SERVICE"), &VKHelper::authStateChanged,            &VKService::GetInstance(),         &VKService::authStateChanged);
        QObject::connect(&VKHelper::GetInstance("SERVICE"), &VKHelper::dataSent,                    &VKService::GetInstance(),         &VKService::dataSent);
        QObject::connect(&VKHelper::GetInstance("SERVICE"), &VKHelper::friendsUpdated,              &VKService::GetInstance(),         &VKService::friendsUpdated);
        QObject::connect(&VKHelper::GetInstance("SERVICE"), &VKHelper::trackedFriendDataUpdated,    &VKService::GetInstance(),         &VKService::trackedFriendDataUpdated);
        QObject::connect(&VKService::GetInstance(),         &VKService::updateFriends,              &VKHelper::GetInstance("SERVICE"), &VKHelper::updateFriends);
        QObject::connect(&VKService::GetInstance(),         &VKService::updateTrackedFriendsData,   &VKHelper::GetInstance("SERVICE"), &VKHelper::updateTrackedFriendsData);

        return QGuiApplication::exec();
    } else {
        return 0;
    }
}
