#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "storehelper.h"

StoreHelper::StoreHelper(QObject *parent) : QObject(parent)
{
}

StoreHelper &StoreHelper::GetInstance()
{
    static StoreHelper instance;

    return instance;
}

QString StoreHelper::getPackageName() const
{
    QAndroidJniObject j_package_name = QtAndroid::androidActivity().callObjectMethod<jstring>("getPackageName");

    return j_package_name.toString();
}
