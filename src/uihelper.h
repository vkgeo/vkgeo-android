#ifndef UIHELPER_H
#define UIHELPER_H

#include <QtCore/QObject>

class UIHelper : public QObject
{
    Q_OBJECT

public:
    explicit UIHelper(QObject *parent = nullptr);
    virtual ~UIHelper();

    Q_INVOKABLE int getScreenDPI();
};

#endif // UIHELPER_H
