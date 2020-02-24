#include <QtAndroidExtras/QtAndroid>
#include <QtAndroidExtras/QAndroidJniObject>

#include "batteryhelper.h"

BatteryHelper::BatteryHelper(QObject *parent) : QObject(parent)
{
}

BatteryHelper &BatteryHelper::GetInstance()
{
    static BatteryHelper instance;

    return instance;
}

QString BatteryHelper::getBatteryStatus() const
{
    QAndroidJniObject j_battery_status = QtAndroid::androidActivity().callObjectMethod<jstring>("getBatteryStatus");

    return j_battery_status.toString();
}

int BatteryHelper::getBatteryLevel() const
{
    return QtAndroid::androidActivity().callMethod<jint>("getBatteryLevel");
}
