#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QVariantMap>
#include <QtCore/QSettings>

class AppSettings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool        enableEncryption       READ enableEncryption       WRITE setEnableEncryption)
    Q_PROPERTY(bool        enableTrackedFriends   READ enableTrackedFriends   WRITE setEnableTrackedFriends)
    Q_PROPERTY(bool        increaseTrackingLimits READ increaseTrackingLimits WRITE setIncreaseTrackingLimits)
    Q_PROPERTY(QString     configuredTheme        READ configuredTheme        WRITE setConfiguredTheme)
    Q_PROPERTY(QString     publicKey              READ publicKey              WRITE setPublicKey)
    Q_PROPERTY(QString     privateKey             READ privateKey             WRITE setPrivateKey)
    Q_PROPERTY(QVariantMap publicKeysOfFriends    READ publicKeysOfFriends    WRITE setPublicKeysOfFriends)

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

    bool enableTrackedFriends();
    void setEnableTrackedFriends(bool enable);

    bool increaseTrackingLimits();
    void setIncreaseTrackingLimits(bool increase);

    QString configuredTheme();
    void setConfiguredTheme(const QString &theme);

    QString publicKey();
    void setPublicKey(const QString &key);

    QString privateKey();
    void setPrivateKey(const QString &key);

    QVariantMap publicKeysOfFriends();
    void setPublicKeysOfFriends(const QVariantMap &keys);

signals:
    void settingsUpdated();

private:
    QSettings Settings {QStringLiteral("Oleg Derevenetz"), QStringLiteral("VKGeo")};
};

#endif // APPSETTINGS_H
