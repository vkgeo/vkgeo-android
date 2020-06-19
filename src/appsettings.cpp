#include "appsettings.h"

AppSettings::AppSettings(QObject *parent) :
    QObject(parent)
{
}

AppSettings &AppSettings::GetInstance()
{
    static AppSettings instance;

    return instance;
}

bool AppSettings::disableAds()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("DisableAds"))) {
        return Settings.value(QStringLiteral("DisableAds")).toBool();
    } else {
        return false;
    }
}

void AppSettings::setDisableAds(bool disable)
{
    Settings.setValue(QStringLiteral("DisableAds"), disable);

    Settings.sync();

    emit settingsUpdated();
}

bool AppSettings::enableTrackedFriends()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("EnableTrackedFriends"))) {
        return Settings.value(QStringLiteral("EnableTrackedFriends")).toBool();
    } else {
        return false;
    }
}

void AppSettings::setEnableTrackedFriends(bool enable)
{
    Settings.setValue(QStringLiteral("EnableTrackedFriends"), enable);

    Settings.sync();

    emit settingsUpdated();
}

bool AppSettings::increaseTrackingLimits()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("IncreaseTrackingLimits"))) {
        return Settings.value(QStringLiteral("IncreaseTrackingLimits")).toBool();
    } else {
        return false;
    }
}

void AppSettings::setIncreaseTrackingLimits(bool increase)
{
    Settings.setValue(QStringLiteral("IncreaseTrackingLimits"), increase);

    Settings.sync();

    emit settingsUpdated();
}

bool AppSettings::appRated()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("AppRated"))) {
        return Settings.value(QStringLiteral("AppRated")).toBool();
    } else {
        return false;
    }
}

void AppSettings::setAppRated(bool rated)
{
    Settings.setValue(QStringLiteral("AppRated"), rated);

    Settings.sync();

    emit settingsUpdated();
}

QString AppSettings::configuredTheme()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("ConfiguredTheme"))) {
        return Settings.value(QStringLiteral("ConfiguredTheme")).toString();
    } else {
        return QStringLiteral("");
    }
}

void AppSettings::setConfiguredTheme(const QString &theme)
{
    Settings.setValue(QStringLiteral("ConfiguredTheme"), theme);

    Settings.sync();

    emit settingsUpdated();
}

QString AppSettings::adMobConsent()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("AdMobConsent"))) {
        return Settings.value(QStringLiteral("AdMobConsent")).toString();
    } else {
        return QStringLiteral("");
    }
}

void AppSettings::setAdMobConsent(const QString &consent)
{
    Settings.setValue(QStringLiteral("AdMobConsent"), consent);

    Settings.sync();

    emit settingsUpdated();
}
