#ifndef UIHELPER_H
#define UIHELPER_H

#include <QtCore/QObject>

class UITheme : public QObject
{
    Q_OBJECT

public:
    enum Theme {
        ThemeAuto,
        ThemeLight,
        ThemeDark
    };
    Q_ENUM(Theme)
};

class UIHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool darkTheme READ darkTheme NOTIFY darkThemeChanged)

    Q_PROPERTY(int configuredTheme READ configuredTheme WRITE setConfiguredTheme NOTIFY configuredThemeChanged)

private:
    explicit UIHelper(QObject *parent = nullptr);
    ~UIHelper() noexcept override = default;

public:
    UIHelper(const UIHelper &) = delete;
    UIHelper(UIHelper &&) noexcept = delete;

    UIHelper &operator=(const UIHelper &) = delete;
    UIHelper &operator=(UIHelper &&) noexcept = delete;

    static UIHelper &GetInstance();

    bool darkTheme() const;

    int configuredTheme() const;
    void setConfiguredTheme(int theme);

    Q_INVOKABLE int getScreenDPI();

    Q_INVOKABLE void showAppSettings();
    Q_INVOKABLE void sendInvitation(const QString &text);

public slots:
    void handleDeviceConfigurationUpdate();

signals:
    void darkThemeChanged(bool darkTheme);
    void configuredThemeChanged(int configuredTheme);

private:
    bool DarkTheme;
    int  ConfiguredTheme;
};

#endif // UIHELPER_H
