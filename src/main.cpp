#include <QtCore/QLocale>
#include <QtCore/QTranslator>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>

#include "androidgw.h"
#include "admobhelper.h"
#include "uihelper.h"
#include "vkhelper.h"

int main(int argc, char *argv[])
{
    QTranslator     translator;
    QGuiApplication app(argc, argv);

    if (translator.load(QString(":/tr/vkgeo_%1").arg(QLocale::system().name()))) {
        app.installTranslator(&translator);
    }

    AndroidGW   *android_gw   = new AndroidGW(&app);
    AdMobHelper *admob_helper = new AdMobHelper(&app);
    VKHelper    *vk_helper    = new VKHelper(&app);

    QObject::connect(android_gw, SIGNAL(setBannerViewHeight(int)),          admob_helper, SLOT(setBannerViewHeight(int)));
    QObject::connect(android_gw, SIGNAL(setAuthState(int)),                 vk_helper,    SLOT(setAuthState(int)));
    QObject::connect(android_gw, SIGNAL(processResponse(QString, QString)), vk_helper,    SLOT(processResponse(QString, QString)));
    QObject::connect(android_gw, SIGNAL(processError(QString, QString)),    vk_helper,    SLOT(processError(QString, QString)));

    qmlRegisterType<VKAuthState>("VKHelper", 1, 0, "VKAuthState");

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(QStringLiteral("AdMobHelper"), admob_helper);
    engine.rootContext()->setContextProperty(QStringLiteral("UIHelper"), new UIHelper(&app));
    engine.rootContext()->setContextProperty(QStringLiteral("VKHelper"), vk_helper);

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
