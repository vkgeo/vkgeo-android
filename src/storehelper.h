#ifndef STOREHELPER_H
#define STOREHELPER_H

#include <QtCore/QObject>

class StoreHelper : public QObject
{
    Q_OBJECT

public:
    explicit StoreHelper(QObject *parent = 0);
    virtual ~StoreHelper();

    Q_INVOKABLE void requestReview();
};

#endif // STOREHELPER_H
