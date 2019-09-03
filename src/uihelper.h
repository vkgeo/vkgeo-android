#ifndef UIHELPER_H
#define UIHELPER_H

#include <QtCore/QObject>

class UIDarkThemeState : public QObject
{
    Q_OBJECT

public:
    enum DarkThemeState {
        StateSystem,
        StateDisabled,
        StateEnabled
    };
    Q_ENUM(DarkThemeState)
};

class UIHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool darkTheme READ darkTheme NOTIFY darkThemeChanged)

    Q_PROPERTY(int darkThemeState READ darkThemeState WRITE setDarkThemeState NOTIFY darkThemeStateChanged)

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

    int darkThemeState() const;
    void setDarkThemeState(int state);

    Q_INVOKABLE int getScreenDPI();

    Q_INVOKABLE void showAppSettings();
    Q_INVOKABLE void sendInvitation(const QString &text);

signals:
    void darkThemeChanged(bool darkTheme);
    void darkThemeStateChanged(int darkThemeState);

private:
    bool DarkTheme;
    int  DarkThemeState;
};

#endif // UIHELPER_H
