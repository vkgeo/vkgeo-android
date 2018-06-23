#ifndef NOTIFICATIONHELPER_H
#define NOTIFICATIONHELPER_H

#include <QtCore/QObject>
#include <QtCore/QString>

class NotificationHelper : public QObject
{
    Q_OBJECT

public:
    explicit NotificationHelper(QObject *parent = 0);
    virtual ~NotificationHelper();

    Q_INVOKABLE void initialize();
    Q_INVOKABLE void showNotification(QString id, QString title, QString body);

private:
    bool Initialized;
};

#endif // NOTIFICATIONHELPER_H
