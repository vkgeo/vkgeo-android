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
    QAndroidJniObject j_battery_status = QtAndroid::androidActivity().callObjectMethod<jstring>("getBatteryStatus");

    return j_battery_status.toString();
}

int BatteryHelper::getBatteryLevel()
{
    return QtAndroid::androidActivity().callMethod<jint>("getBatteryLevel");
}
