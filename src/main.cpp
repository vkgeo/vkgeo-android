#include <QtCore/QLocale>
#include <QtCore/QTranslator>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtAndroidExtras/QAndroidService>

#include "androidgw.h"
#include "admobhelper.h"
#include "storehelper.h"
#include "uihelper.h"
#include "vkhelper.h"
#include "vkservice.h"

int main(int argc, char *argv[])
{
    if (argc == 1) {
        QTranslator     translator;
        QGuiApplication app(argc, argv);

        if (translator.load(QString(":/tr/vkgeo_%1").arg(QLocale::system().name()))) {
            app.installTranslator(&translator);
        }

        AndroidGW   *android_gw   = new AndroidGW(&app);
        AdMobHelper *admob_helper = new AdMobHelper(&app);
        VKHelper    *vk_helper    = new VKHelper("ACTIVITY", &app);

        QObject::connect(android_gw, &AndroidGW::setBannerViewHeight, admob_helper, &AdMobHelper::setBannerViewHeight);
        QObject::connect(android_gw, &AndroidGW::setAuthState,        vk_helper,    &VKHelper::setAuthState);
        QObject::connect(android_gw, &AndroidGW::processResponse,     vk_helper,    &VKHelper::processResponse);
        QObject::connect(android_gw, &AndroidGW::processError,        vk_helper,    &VKHelper::processError);

        qmlRegisterType<VKAuthState>("VKHelper", 1, 0, "VKAuthState");

        QQmlApplicationEngine engine;

        engine.rootContext()->setContextProperty(QStringLiteral("AdMobHelper"), admob_helper);
        engine.rootContext()->setContextProperty(QStringLiteral("StoreHelper"), new StoreHelper(&app));
        engine.rootContext()->setContextProperty(QStringLiteral("UIHelper"), new UIHelper(&app));
        engine.rootContext()->setContextProperty(QStringLiteral("VKHelper"), vk_helper);

        engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

        if (engine.rootObjects().isEmpty())
            return -1;

        return app.exec();
    } else if (argc == 2 && QString(argv[1]) == "-service") {
        QAndroidService app(argc, argv);

        AndroidGW *android_gw = new AndroidGW(&app);
        VKHelper  *vk_helper  = new VKHelper("SERVICE", &app);
        VKService *vk_service = new VKService(&app);

        QObject::connect(android_gw, &AndroidGW::setAuthState,                  vk_helper,  &VKHelper::setAuthState);
        QObject::connect(android_gw, &AndroidGW::processResponse,               vk_helper,  &VKHelper::processResponse);
        QObject::connect(android_gw, &AndroidGW::processError,                  vk_helper,  &VKHelper::processError);
        QObject::connect(android_gw, &AndroidGW::processLocationUpdate,         vk_helper,  &VKHelper::processLocationUpdate);
        QObject::connect(vk_helper,  &VKHelper::authStateChanged,               vk_service, &VKService::authStateChanged);
        QObject::connect(vk_helper,  &VKHelper::locationReported,               vk_service, &VKService::locationReported);
        QObject::connect(vk_helper,  &VKHelper::friendsUpdated,                 vk_service, &VKService::friendsUpdated);
        QObject::connect(vk_helper,  &VKHelper::trackedFriendLocationUpdated,   vk_service, &VKService::trackedFriendLocationUpdated);
        QObject::connect(vk_service, &VKService::updateFriends,                 vk_helper,  &VKHelper::updateFriends);
        QObject::connect(vk_service, &VKService::updateTrackedFriendsLocations, vk_helper,  &VKHelper::updateTrackedFriendsLocations);

        return app.exec();
    } else {
        return 0;
    }
}
