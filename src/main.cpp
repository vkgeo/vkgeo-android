#include <QtCore/QLocale>
#include <QtCore/QTranslator>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>

#include "admobhelper.h"
#include "storehelper.h"
#include "uihelper.h"
#include "notificationhelper.h"
#include "vkhelpershared.h"

VKHelper *VKHelperShared = NULL;

int main(int argc, char *argv[])
{
    QTranslator     translator;
    QGuiApplication app(argc, argv);

    if (translator.load(QString(":/tr/vkgeo_%1").arg(QLocale::system().name()))) {
        app.installTranslator(&translator);
    }

    qmlRegisterType<VKAuthState>("VKHelper", 1, 0, "VKAuthState");

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(QStringLiteral("AdMobHelper"), new AdMobHelper(&app));
    engine.rootContext()->setContextProperty(QStringLiteral("StoreHelper"), new StoreHelper(&app));
    engine.rootContext()->setContextProperty(QStringLiteral("UIHelper"), new UIHelper(&app));
    engine.rootContext()->setContextProperty(QStringLiteral("NotificationHelper"), new NotificationHelper(&app));

    if (VKHelperShared != NULL) {
        VKHelperShared->setParent(&app);

        engine.rootContext()->setContextProperty(QStringLiteral("VKHelper"), VKHelperShared);
    }

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
