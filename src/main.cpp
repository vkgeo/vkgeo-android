#include <QtCore/QString>
#include <QtCore/QLocale>
#include <QtCore/QTranslator>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQuickControls2/QQuickStyle>
#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidService>

#include "androidgw.h"
#include "appsettings.h"
#include "batteryhelper.h"
#include "cryptohelper.h"
#include "gplayhelper.h"
#include "uihelper.h"
#include "vkhelper.h"
#include "vkservice.h"

int main(int argc, char *argv[])
{
    if (argc == 1) {
        QTranslator     translator;
        QGuiApplication app(argc, argv);

        if (translator.load(QStringLiteral(":/tr/vkgeo_%1").arg(QLocale::system().name()))) {
            QGuiApplication::installTranslator(&translator);
        }

        QObject::connect(&AppSettings::GetInstance(), &AppSettings::settingsUpdated, [] () {
            QtAndroid::androidActivity().callMethod<void>("notifyServiceAboutSettingsUpdate");
        });

        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::deviceConfigurationUpdated, &UIHelper::GetInstance(), &UIHelper::handleDeviceConfigurationUpdate);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::authStateUpdated,           &VKHelper::GetInstance(), &VKHelper::setAuthState);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::vkRequestCompleted,         &VKHelper::GetInstance(), &VKHelper::handleResponse);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::vkRequestFailed,            &VKHelper::GetInstance(), &VKHelper::handleError);

        VKHelper::GetInstance().initVK();

        qmlRegisterUncreatableType<UITheme>    ("UIHelper", 1, 0, "UITheme",     QStringLiteral("Could not create an object of type UITheme"));
        qmlRegisterUncreatableType<VKAuthState>("VKHelper", 1, 0, "VKAuthState", QStringLiteral("Could not create an object of type VKAuthState"));

        QQmlApplicationEngine engine;

        engine.rootContext()->setContextProperty(QStringLiteral("AppSettings"), &AppSettings::GetInstance());
        engine.rootContext()->setContextProperty(QStringLiteral("BatteryHelper"), &BatteryHelper::GetInstance());
        engine.rootContext()->setContextProperty(QStringLiteral("CryptoHelper"), &CryptoHelper::GetInstance());
        engine.rootContext()->setContextProperty(QStringLiteral("GPlayHelper"), &GPlayHelper::GetInstance());
        engine.rootContext()->setContextProperty(QStringLiteral("UIHelper"), &UIHelper::GetInstance());
        engine.rootContext()->setContextProperty(QStringLiteral("VKHelper"), &VKHelper::GetInstance());

        QQuickStyle::setStyle(QStringLiteral("Default"));

        engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

        QtAndroid::hideSplashScreen();

        if (engine.rootObjects().isEmpty()) {
            return -1;
        } else {
            return QGuiApplication::exec();
        }
    } else if (argc == 2 && QString::fromUtf8(argv[1]) == QStringLiteral("-service")) {
        QAndroidService app(argc, argv);

        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::authStateUpdated,                  &VKHelper::GetInstance(),  &VKHelper::setAuthState);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::vkRequestCompleted,                &VKHelper::GetInstance(),  &VKHelper::handleResponse);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::vkRequestFailed,                   &VKHelper::GetInstance(),  &VKHelper::handleError);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::locationUpdated,                   &VKHelper::GetInstance(),  &VKHelper::handleLocationUpdate);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::batteryStatusUpdated,              &VKHelper::GetInstance(),  &VKHelper::handleBatteryStatusUpdate);
        QObject::connect(&AndroidGW::GetInstance(), &AndroidGW::settingsUpdated,                   &VKService::GetInstance(), &VKService::handleSettingsUpdate);
        QObject::connect(&VKHelper::GetInstance(),  &VKHelper::authStateChanged,                   &VKService::GetInstance(), &VKService::handleAuthStateChange);
        QObject::connect(&VKHelper::GetInstance(),  &VKHelper::dataSent,                           &VKService::GetInstance(), &VKService::handleDataSending);
        QObject::connect(&VKHelper::GetInstance(),  &VKHelper::friendsUpdated,                     &VKService::GetInstance(), &VKService::handleFriendsUpdate);
        QObject::connect(&VKHelper::GetInstance(),  &VKHelper::trackedFriendDataUpdated,           &VKService::GetInstance(), &VKService::handleTrackedFriendDataUpdate);
        QObject::connect(&VKService::GetInstance(), &VKService::friendsUpdateRequested,            &VKHelper::GetInstance(),  &VKHelper::updateFriends);
        QObject::connect(&VKService::GetInstance(), &VKService::trackedFriendsDataUpdateRequested, &VKHelper::GetInstance(),  &VKHelper::updateTrackedFriendsData);

        VKHelper::GetInstance().initVK();

        return QGuiApplication::exec();
    } else {
        return -1;
    }
}
