#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "uihelper.h"

UIHelper::UIHelper(QObject *parent) : QObject(parent)
{
    DarkTheme       = QtAndroid::androidActivity().callMethod<jboolean>("getNightModeStatus");
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

int UIHelper::getScreenDPI()
{
    return QtAndroid::androidActivity().callMethod<jint>("getScreenDPI");
}

void UIHelper::showAppSettings()
{
    QtAndroid::androidActivity().callMethod<void>("showAppSettings");
}

void UIHelper::sendInvitation(const QString &text)
{
    QAndroidJniObject j_text = QAndroidJniObject::fromString(text);

    QtAndroid::androidActivity().callMethod<void>("sendInvitation", "(Ljava/lang/String;)V", j_text.object<jstring>());
}

void UIHelper::handleDeviceConfigurationUpdate()
{
    if (ConfiguredTheme != UITheme::ThemeLight &&
        ConfiguredTheme != UITheme::ThemeDark) {
        bool dark_theme = QtAndroid::androidActivity().callMethod<jboolean>("getNightModeStatus");

        if (DarkTheme != dark_theme) {
            DarkTheme = dark_theme;

            emit darkThemeChanged(DarkTheme);
        }
    }
}
