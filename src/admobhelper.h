#ifndef ADMOBHELPER_H
#define ADMOBHELPER_H

#include <QtCore/QObject>
#include <QtCore/QString>

#ifdef __OBJC__
@class BannerViewDelegate;
@class InterstitialDelegate;
#endif

class AdMobHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool interstitialReady  READ interstitialReady)
    Q_PROPERTY(bool interstitialActive READ interstitialActive NOTIFY interstitialActiveChanged)
    Q_PROPERTY(int  bannerViewHeight   READ bannerViewHeight   NOTIFY bannerViewHeightChanged)

public:
    static const QString ADMOB_APP_ID,
                         ADMOB_BANNERVIEW_UNIT_ID,
                         ADMOB_INTERSTITIAL_UNIT_ID,
                         ADMOB_TEST_DEVICE_ID;

    explicit AdMobHelper(QObject *parent = 0);
    virtual ~AdMobHelper();

    bool interstitialReady() const;
    bool interstitialActive() const;
    int  bannerViewHeight() const;

    Q_INVOKABLE void initialize();
    Q_INVOKABLE void showBannerView();
    Q_INVOKABLE void hideBannerView();
    Q_INVOKABLE void showInterstitial();

    static void setInterstitialActive(bool active);
    static void setBannerViewHeight(int height);

signals:
    void interstitialActiveChanged(bool interstitialActive);
    void bannerViewHeightChanged(int bannerViewHeight);

private:
    bool                  Initialized, InterstitialActive;
    int                   BannerViewHeight;
    static AdMobHelper   *Instance;
#ifdef __OBJC__
    BannerViewDelegate   *BannerViewDelegateInstance;
    InterstitialDelegate *InterstitialDelegateInstance;
#else
    void                 *BannerViewDelegateInstance;
    void                 *InterstitialDelegateInstance;
#endif
};

#endif // ADMOBHELPER_H
