#include <QtAndroidExtras/QAndroidJniObject>

#include "uihelper.h"

UIHelper::UIHelper(QObject *parent) : QObject(parent)
{
}

UIHelper::~UIHelper()
{
}

int UIHelper::screenDPI()
{
    return QAndroidJniObject::callStaticMethod<jint>("com/derevenetz/oleg/vkgeo/VKGeoActivity",
                                                     "getScreenDPI");
}
