#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "storehelper.h"

StoreHelper::StoreHelper(QObject *parent) : QObject(parent)
{
}

QString StoreHelper::getPackageName()
{
    QAndroidJniObject j_package_name = QtAndroid::androidActivity().callObjectMethod<jstring>("getPackageName");

    return j_package_name.toString();
}
