#include <QtAndroidExtras/QAndroidJniObject>

#include "admobhelper.h"

const QString AdMobHelper::ADMOB_APP_ID              ("ca-app-pub-2455088855015693~9304224395");
const QString AdMobHelper::ADMOB_BANNERVIEW_UNIT_ID  ("ca-app-pub-3940256099942544/6300978111");
const QString AdMobHelper::ADMOB_INTERSTITIAL_UNIT_ID("ca-app-pub-3940256099942544/1033173712");

AdMobHelper *AdMobHelper::Instance = NULL;

AdMobHelper::AdMobHelper(QObject *parent) : QObject(parent)
{
    Initialized      = false;
    BannerViewHeight = 0;
    Instance         = this;
}

AdMobHelper::~AdMobHelper()
{
}

bool AdMobHelper::interstitialReady() const
{
    if (Initialized) {
        return QAndroidJniObject::callStaticMethod<jboolean>("com/derevenetz/oleg/vkgeo/VKGeoActivity",
                                                             "interstitialReady");
    } else {
        return false;
    }
}

int AdMobHelper::bannerViewHeight() const
{
    return BannerViewHeight;
}

void AdMobHelper::initialize()
{
    if (!Initialized) {
        QAndroidJniObject j_app_id = QAndroidJniObject::fromString(ADMOB_APP_ID);

        QAndroidJniObject::callStaticMethod<void>("com/derevenetz/oleg/vkgeo/VKGeoActivity",
                                                  "initAds", "(Ljava/lang/String;)V", j_app_id.object<jstring>());

        Initialized = true;
    }
}

void AdMobHelper::showBannerView()
{
    if (Initialized) {
        QAndroidJniObject j_unit_id = QAndroidJniObject::fromString(ADMOB_BANNERVIEW_UNIT_ID);

        QAndroidJniObject::callStaticMethod<void>("com/derevenetz/oleg/vkgeo/VKGeoActivity",
                                                  "showBannerView", "(Ljava/lang/String;)V", j_unit_id.object<jstring>());
    }
}

void AdMobHelper::hideBannerView()
{
    if (Initialized) {
        QAndroidJniObject::callStaticMethod<void>("com/derevenetz/oleg/vkgeo/VKGeoActivity",
                                                  "hideBannerView");
    }
}

void AdMobHelper::showInterstitial()
{
    if (Initialized) {
        QAndroidJniObject::callStaticMethod<void>("com/derevenetz/oleg/vkgeo/VKGeoActivity",
                                                  "showInterstitial");
    }
}

void AdMobHelper::setBannerViewHeight(int height)
{
    Instance->BannerViewHeight = height;

    emit Instance->bannerViewHeightChanged(Instance->BannerViewHeight);
}
