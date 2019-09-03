#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "uihelper.h"

UIHelper::UIHelper(QObject *parent) : QObject(parent)
{
    DarkTheme       = false;
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
    ConfiguredTheme = theme;

    emit configuredThemeChanged(ConfiguredTheme);

    if (ConfiguredTheme == UITheme::ThemeLight) {
        DarkTheme = false;
    } else if (ConfiguredTheme == UITheme::ThemeDark) {
        DarkTheme = true;
    } else {
        DarkTheme = false;
    }

    emit darkThemeChanged(DarkTheme);
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
