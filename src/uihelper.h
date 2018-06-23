#ifndef UIHELPER_H
#define UIHELPER_H

#include <QtCore/QObject>

class UIHelper : public QObject
{
    Q_OBJECT

public:
    explicit UIHelper(QObject *parent = 0);
    virtual ~UIHelper();

    Q_INVOKABLE int safeAreaTopMargin();
    Q_INVOKABLE int safeAreaBottomMargin();
};

#endif // UIHELPER_H
