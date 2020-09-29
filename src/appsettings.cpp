#include <QtCore/QLatin1String>

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
        return QLatin1String("");
    }
}

void AppSettings::setConfiguredTheme(const QString &theme)
{
    Settings.setValue(QStringLiteral("ConfiguredTheme"), theme);

    Settings.sync();

    emit settingsUpdated();
}

QString AppSettings::publicKey()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("PublicKey"))) {
        return Settings.value(QStringLiteral("PublicKey")).toString();
    } else {
        return QLatin1String("");
    }
}

void AppSettings::setPublicKey(const QString &key)
{
    Settings.setValue(QStringLiteral("PublicKey"), key);

    Settings.sync();

    emit settingsUpdated();
}

QString AppSettings::privateKey()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("PrivateKey"))) {
        return Settings.value(QStringLiteral("PrivateKey")).toString();
    } else {
        return QLatin1String("");
    }
}

void AppSettings::setPrivateKey(const QString &key)
{
    Settings.setValue(QStringLiteral("PrivateKey"), key);

    Settings.sync();

    emit settingsUpdated();
}

QVariantMap AppSettings::publicKeysOfFriends()
{
    Settings.sync();

    if (Settings.contains(QStringLiteral("PublicKeysOfFriends"))) {
        return Settings.value(QStringLiteral("PublicKeysOfFriends")).toMap();
    } else {
        return QVariantMap();
    }
}

void AppSettings::setPublicKeysOfFriends(const QVariantMap &keys)
{
    Settings.setValue(QStringLiteral("PublicKeysOfFriends"), keys);

    Settings.sync();

    emit settingsUpdated();
}
