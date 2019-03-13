#ifndef ANDROIDGW_H
#define ANDROIDGW_H

#include <QtCore/QtGlobal>
#include <QtCore/QObject>
#include <QtCore/QString>

class AndroidGW : public QObject
{
    Q_OBJECT

public:
    explicit AndroidGW(QObject *parent = nullptr);
    ~AndroidGW() override = default;

    static AndroidGW *instance();

signals:
    void setBannerViewHeight(int height);

    void setAuthState(int state);
    void processResponse(QString response, QString resp_request_str);
    void processError(QString error_message, QString err_request_str);
    void processLocationUpdate(qreal latitude, qreal longitude);
    void processBatteryStatusUpdate(QString status, int level);

private:
    static AndroidGW *Instance;
};

#endif // ANDROIDGW_H
