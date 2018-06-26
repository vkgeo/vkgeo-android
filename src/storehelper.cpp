#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "storehelper.h"

StoreHelper::StoreHelper(QObject *parent) : QObject(parent)
{
}

StoreHelper::~StoreHelper()
{
}

QString StoreHelper::getPackageName()
{
    QAndroidJniObject str_object = QtAndroid::androidActivity().callObjectMethod<jstring>("getPackageName");

    return str_object.toString();
}
