#ifndef BATTERYHELPER_H
#define BATTERYHELPER_H

#include <QtCore/QObject>
#include <QtCore/QString>

class BatteryHelper : public QObject
{
    Q_OBJECT

private:
    explicit BatteryHelper(QObject *parent = nullptr);
    ~BatteryHelper() noexcept override = default;

public:
    BatteryHelper(const BatteryHelper&) = delete;
    BatteryHelper(BatteryHelper&&) noexcept = delete;

    BatteryHelper &operator=(const BatteryHelper&) = delete;
    BatteryHelper &operator=(BatteryHelper&&) noexcept = delete;

    static BatteryHelper &GetInstance();

    Q_INVOKABLE QString getBatteryStatus();
    Q_INVOKABLE int getBatteryLevel();
};

#endif // BATTERYHELPER_H
