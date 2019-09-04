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
    AndroidGW(const AndroidGW &) = delete;
    AndroidGW(AndroidGW &&) noexcept = delete;

    AndroidGW &operator=(const AndroidGW &) = delete;
    AndroidGW &operator=(AndroidGW &&) noexcept = delete;

    static AndroidGW &GetInstance();

signals:
    void deviceConfigurationChanged();
    void bannerViewHeightChanged(int bannerViewHeight);
    void authStateChanged(int authState);
    void vkRequestCompleted(const QString &response, const QString &request);
    void vkRequestFailed(const QString &errorMessage, const QString &request);
    void locationUpdated(qreal latitude, qreal longitude);
    void batteryStatusUpdated(const QString &status, int level);
};

#endif // ANDROIDGW_H
