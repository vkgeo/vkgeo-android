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
#include "storehelper.h"
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

        auto android_gw   = new AndroidGW(&app);
        auto admob_helper = new AdMobHelper(&app);
        auto vk_helper    = new VKHelper("ACTIVITY", &app);

        QObject::connect(android_gw, &AndroidGW::setBannerViewHeight, admob_helper, &AdMobHelper::setBannerViewHeight);
        QObject::connect(android_gw, &AndroidGW::setAuthState,        vk_helper,    &VKHelper::setAuthState);
        QObject::connect(android_gw, &AndroidGW::processResponse,     vk_helper,    &VKHelper::processResponse);
        QObject::connect(android_gw, &AndroidGW::processError,        vk_helper,    &VKHelper::processError);

        qmlRegisterType<VKAuthState>("VKHelper", 1, 0, "VKAuthState");

        QQmlApplicationEngine engine;

        engine.rootContext()->setContextProperty(QStringLiteral("AdMobHelper"), admob_helper);
        engine.rootContext()->setContextProperty(QStringLiteral("StoreHelper"), new StoreHelper(&app));
        engine.rootContext()->setContextProperty(QStringLiteral("BatteryHelper"), new BatteryHelper(&app));
        engine.rootContext()->setContextProperty(QStringLiteral("UIHelper"), new UIHelper(&app));
        engine.rootContext()->setContextProperty(QStringLiteral("VKHelper"), vk_helper);

        engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

        QtAndroid::hideSplashScreen();

        if (engine.rootObjects().isEmpty())
            return -1;

        return QGuiApplication::exec();
    } else if (argc == 2 && QString(argv[1]) == "-service") {
        QAndroidService app(argc, argv);

        auto android_gw = new AndroidGW(&app);
        auto vk_helper  = new VKHelper("SERVICE", &app);
        auto vk_service = new VKService(&app);

        QObject::connect(android_gw, &AndroidGW::setAuthState,               vk_helper,  &VKHelper::setAuthState);
        QObject::connect(android_gw, &AndroidGW::processResponse,            vk_helper,  &VKHelper::processResponse);
        QObject::connect(android_gw, &AndroidGW::processError,               vk_helper,  &VKHelper::processError);
        QObject::connect(android_gw, &AndroidGW::processLocationUpdate,      vk_helper,  &VKHelper::processLocationUpdate);
        QObject::connect(android_gw, &AndroidGW::processBatteryStatusUpdate, vk_helper,  &VKHelper::processBatteryStatusUpdate);
        QObject::connect(vk_helper,  &VKHelper::authStateChanged,            vk_service, &VKService::authStateChanged);
        QObject::connect(vk_helper,  &VKHelper::dataSent,                    vk_service, &VKService::dataSent);
        QObject::connect(vk_helper,  &VKHelper::friendsUpdated,              vk_service, &VKService::friendsUpdated);
        QObject::connect(vk_helper,  &VKHelper::trackedFriendDataUpdated,    vk_service, &VKService::trackedFriendDataUpdated);
        QObject::connect(vk_service, &VKService::updateFriends,              vk_helper,  &VKHelper::updateFriends);
        QObject::connect(vk_service, &VKService::updateTrackedFriendsData,   vk_helper,  &VKHelper::updateTrackedFriendsData);

        return QGuiApplication::exec();
    } else {
        return 0;
    }
}
