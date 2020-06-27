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

bool AppSettings::enableEncryption()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("EnableEncryption"))) {
        return Settings.value(QStringLiteral("EnableEncryption")).toBool();
    } else {
        return false;
    }
}

void AppSettings::setEnableEncryption(bool enable)
{
    Settings.setValue(QStringLiteral("EnableEncryption"), enable);

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

QString AppSettings::encryptionKey()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("EncryptionKey"))) {
        return Settings.value(QStringLiteral("EncryptionKey")).toString();
    } else {
        return QStringLiteral("");
    }
}

void AppSettings::setEncryptionKey(const QString &key)
{
    Settings.setValue(QStringLiteral("EncryptionKey"), key);

    Settings.sync();

    emit settingsUpdated();
}

QVariantMap AppSettings::friendsEncryptionKeys()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("FriendsEncryptionKeys"))) {
        return Settings.value(QStringLiteral("FriendsEncryptionKeys")).toMap();
    } else {
        return QVariantMap();
    }
}

void AppSettings::setFriendsEncryptionKeys(const QVariantMap &keys)
{
    Settings.setValue(QStringLiteral("FriendsEncryptionKeys"), keys);

    Settings.sync();

    emit settingsUpdated();
}
