#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "uihelper.h"

UIHelper::UIHelper(QObject *parent) : QObject(parent)
{
    DarkTheme       = QtAndroid::androidActivity().callMethod<jboolean>("getNightModeStatus");
    ScreenDpi       = QtAndroid::androidActivity().callMethod<jint>("getScreenDpi");
    ConfiguredTheme = UITheme::ThemeAuto;
}

UIHelper &UIHelper::GetInstance()
{
    static UIHelper instance;

    return instance;
}

bool UIHelper::darkTheme() const
{
    return DarkTheme;
}

int UIHelper::screenDpi() const
{
    return ScreenDpi;
}

int UIHelper::configuredTheme() const
{
    return ConfiguredTheme;
}

void UIHelper::setConfiguredTheme(int theme)
{
    if (ConfiguredTheme != theme) {
        ConfiguredTheme = theme;

        emit configuredThemeChanged(ConfiguredTheme);

        bool dark_theme;

        if (ConfiguredTheme == UITheme::ThemeLight) {
            dark_theme = false;
        } else if (ConfiguredTheme == UITheme::ThemeDark) {
            dark_theme = true;
        } else {
            dark_theme = QtAndroid::androidActivity().callMethod<jboolean>("getNightModeStatus");
        }

        if (DarkTheme != dark_theme) {
            DarkTheme = dark_theme;

            emit darkThemeChanged(DarkTheme);
        }
    }
}

void UIHelper::showAppSettings() const
{
    QtAndroid::androidActivity().callMethod<void>("showAppSettings");
}

void UIHelper::sendInvitation(const QString &text) const
{
    QAndroidJniObject j_text = QAndroidJniObject::fromString(text);

    QtAndroid::androidActivity().callMethod<void>("sendInvitation", "(Ljava/lang/String;)V", j_text.object<jstring>());
}

void UIHelper::handleDeviceConfigurationUpdate()
{
    int screen_dpi = QtAndroid::androidActivity().callMethod<jint>("getScreenDpi");

    if (ScreenDpi != screen_dpi) {
        ScreenDpi = screen_dpi;

        emit screenDpiChanged(ScreenDpi);
    }

    if (ConfiguredTheme != UITheme::ThemeLight &&
        ConfiguredTheme != UITheme::ThemeDark) {
        bool dark_theme = QtAndroid::androidActivity().callMethod<jboolean>("getNightModeStatus");

        if (DarkTheme != dark_theme) {
            DarkTheme = dark_theme;

            emit darkThemeChanged(DarkTheme);
        }
    }
}
