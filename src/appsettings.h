#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QSettings>

class AppSettings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString configuredTheme READ configuredTheme WRITE setConfiguredTheme)
    Q_PROPERTY(QString adMobConsent    READ adMobConsent    WRITE setAdMobConsent)

private:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings() noexcept override = default;

public:
    AppSettings(const AppSettings &) = delete;
    AppSettings(AppSettings &&) noexcept = delete;

    AppSettings &operator=(const AppSettings &) = delete;
    AppSettings &operator=(AppSettings &&) noexcept = delete;

    static AppSettings &GetInstance();

    QString configuredTheme();
    void setConfiguredTheme(const QString &theme);

    QString adMobConsent();
    void setAdMobConsent(const QString &consent);

signals:
    void settingsUpdated();

private:
    QSettings Settings {QStringLiteral("Oleg Derevenetz"), QStringLiteral("VKGeo")};
};

#endif // APPSETTINGS_H
