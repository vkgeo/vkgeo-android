#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "uihelper.h"

UIHelper::UIHelper(QObject *parent) : QObject(parent)
{
    DarkTheme      = false;
    DarkThemeState = UIDarkThemeState::StateAuto;
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

int UIHelper::darkThemeState() const
{
    return DarkThemeState;
}

void UIHelper::setDarkThemeState(int state)
{
    DarkThemeState = state;

    emit darkThemeStateChanged(DarkThemeState);

    if (DarkThemeState == UIDarkThemeState::StateDisabled) {
        DarkTheme = false;
    } else if (DarkThemeState == UIDarkThemeState::StateEnabled) {
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
