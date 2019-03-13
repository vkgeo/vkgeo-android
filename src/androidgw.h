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
    void processResponse(const QString &response, const QString &resp_request_str);
    void processError(const QString &error_message, const QString &err_request_str);
    void processLocationUpdate(qreal latitude, qreal longitude);
    void processBatteryStatusUpdate(const QString &status, int level);

private:
    static AndroidGW *Instance;
};

#endif // ANDROIDGW_H
