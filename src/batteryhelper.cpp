#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "batteryhelper.h"

BatteryHelper::BatteryHelper(QObject *parent) : QObject(parent)
{
}

BatteryHelper::~BatteryHelper()
{
}

QString BatteryHelper::getBatteryStatus()
{
    QAndroidJniObject str_object = QtAndroid::androidActivity().callObjectMethod<jstring>("getBatteryStatus");

    return str_object.toString();
}

int BatteryHelper::getBatteryLevel()
{
    return QtAndroid::androidActivity().callMethod<jint>("getBatteryLevel");
}
