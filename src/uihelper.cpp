#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "uihelper.h"

UIHelper::UIHelper(QObject *parent) : QObject(parent)
{
}

UIHelper &UIHelper::GetInstance()
{
    static UIHelper instance;

    return instance;
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
