#ifndef ANDROIDGW_H
#define ANDROIDGW_H

#include <QtCore/QtGlobal>
#include <QtCore/QObject>
#include <QtCore/QString>

class AndroidGW : public QObject
{
    Q_OBJECT

private:
    explicit AndroidGW(QObject *parent = nullptr);
    ~AndroidGW() noexcept override = default;

public:
    AndroidGW(const AndroidGW&) = delete;
    AndroidGW(AndroidGW&&) noexcept = delete;

    AndroidGW& operator=(const AndroidGW&) = delete;
    AndroidGW& operator=(AndroidGW&&) noexcept = delete;

    static AndroidGW &GetInstance();

signals:
    void setBannerViewHeight(int height);

    void setAuthState(int state);
    void processResponse(const QString &response, const QString &resp_request_str);
    void processError(const QString &error_message, const QString &err_request_str);
    void processLocationUpdate(qreal latitude, qreal longitude);
    void processBatteryStatusUpdate(const QString &status, int level);
};

#endif // ANDROIDGW_H
