#ifndef STOREHELPER_H
#define STOREHELPER_H

#include <QtCore/QObject>
#include <QtCore/QString>

class StoreHelper : public QObject
{
    Q_OBJECT

public:
    explicit StoreHelper(QObject *parent = nullptr);
    ~StoreHelper() override = default;

    Q_INVOKABLE QString getPackageName();
};

#endif // STOREHELPER_H
