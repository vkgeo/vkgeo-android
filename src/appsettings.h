#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QVariantMap>
#include <QtCore/QSettings>

class AppSettings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool        enableEncryption      READ enableEncryption      WRITE setEnableEncryption)
    Q_PROPERTY(QString     configuredTheme       READ configuredTheme       WRITE setConfiguredTheme)
    Q_PROPERTY(QString     adMobConsent          READ adMobConsent          WRITE setAdMobConsent)
    Q_PROPERTY(QString     encryptionKey         READ encryptionKey         WRITE setEncryptionKey)
    Q_PROPERTY(QVariantMap friendsEncryptionKeys READ friendsEncryptionKeys WRITE setFriendsEncryptionKeys)

private:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings() noexcept override = default;

public:
    AppSettings(const AppSettings &) = delete;
    AppSettings(AppSettings &&) noexcept = delete;

    AppSettings &operator=(const AppSettings &) = delete;
    AppSettings &operator=(AppSettings &&) noexcept = delete;

    static AppSettings &GetInstance();

    bool enableEncryption();
    void setEnableEncryption(bool enable);

    QString configuredTheme();
    void setConfiguredTheme(const QString &theme);

    QString adMobConsent();
    void setAdMobConsent(const QString &consent);

    QString encryptionKey();
    void setEncryptionKey(const QString &key);

    QVariantMap friendsEncryptionKeys();
    void setFriendsEncryptionKeys(const QVariantMap &keys);

signals:
    void settingsUpdated();

private:
    QSettings Settings {QStringLiteral("Oleg Derevenetz"), QStringLiteral("VKGeo")};
};

#endif // APPSETTINGS_H
