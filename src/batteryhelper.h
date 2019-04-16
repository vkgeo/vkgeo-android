#ifndef BATTERYHELPER_H
#define BATTERYHELPER_H

#include <QtCore/QObject>
#include <QtCore/QString>

class BatteryHelper : public QObject
{
    Q_OBJECT

public:
    explicit BatteryHelper(QObject *parent = nullptr);

    BatteryHelper(const BatteryHelper&) = delete;
    BatteryHelper(const BatteryHelper&&) noexcept = delete;

    BatteryHelper& operator=(const BatteryHelper&) = delete;
    BatteryHelper& operator=(const BatteryHelper&&) noexcept = delete;

    ~BatteryHelper() noexcept override = default;

    Q_INVOKABLE QString getBatteryStatus();
    Q_INVOKABLE int getBatteryLevel();
};

#endif // BATTERYHELPER_H
