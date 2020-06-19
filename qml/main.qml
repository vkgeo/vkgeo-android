import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.LocalStorage 2.12
import QtPurchasing 1.0
import UIHelper 1.0
import VKHelper 1.0

import "Core/Dialog"

ApplicationWindow {
    id:      mainWindow
    title:   qsTr("Friends on Map")
    visible: true

    readonly property int screenDpi:      UIHelper.screenDpi
    readonly property int vkAuthState:    VKHelper.authState

    property bool componentCompleted:     false
    property bool disableAds:             false
    property bool enableTrackedFriends:   false
    property bool increaseTrackingLimits: false
    property bool appRated:               false

    property string configuredTheme:      ""
    property string adMobConsent:         ""

    property var loginPage:               null

    onScreenDpiChanged: {
        if (mainStackView.depth > 0 && typeof mainStackView.currentItem.bannerViewHeight === "number") {
            if (disableAds) {
                AdMobHelper.hideBannerView();
            } else {
                AdMobHelper.showBannerView();
            }
        } else {
            AdMobHelper.hideBannerView();
        }
    }

    onVkAuthStateChanged: {
        if (componentCompleted) {
            if (vkAuthState === VKAuthState.StateNotAuthorized) {
                openLoginPage();
            } else if (vkAuthState === VKAuthState.StateAuthorized) {
                closeLoginPage();
            }
        }
    }

    onComponentCompletedChanged: {
        if (componentCompleted) {
            if (vkAuthState === VKAuthState.StateNotAuthorized) {
                openLoginPage();
            } else if (vkAuthState === VKAuthState.StateAuthorized) {
                closeLoginPage();
            }
        }
    }

    onDisableAdsChanged: {
        AppSettings.disableAds = disableAds;

        updateFeatures();
    }

    onEnableTrackedFriendsChanged: {
        AppSettings.enableTrackedFriends = enableTrackedFriends;

        updateFeatures();
    }

    onIncreaseTrackingLimitsChanged: {
        AppSettings.increaseTrackingLimits = increaseTrackingLimits;

        updateFeatures();
    }

    onAppRatedChanged: {
        AppSettings.appRated = appRated;
    }

    onConfiguredThemeChanged: {
        AppSettings.configuredTheme = configuredTheme;

        updateFeatures();
    }

    onAdMobConsentChanged: {
        AppSettings.adMobConsent = adMobConsent;

        updateFeatures();
    }

    function openLoginPage() {
        if (loginPage === null) {
            var component = Qt.createComponent("Core/LoginPage.qml");

            if (component.status === Component.Ready) {
                loginPage = mainStackView.push(component);
            } else {
                console.error(component.errorString());
            }
        }
    }

    function closeLoginPage() {
        if (loginPage !== null) {
            mainStackView.pop(loginPage);
            mainStackView.pop();

            loginPage = null;
        }
    }

    function updateFeatures() {
        if (!disableAds && (adMobConsent === "PERSONALIZED" || adMobConsent === "NON_PERSONALIZED")) {
            AdMobHelper.setPersonalization(adMobConsent === "PERSONALIZED");

            AdMobHelper.initAds();
        }

        if (mainStackView.depth > 0 && typeof mainStackView.currentItem.bannerViewHeight === "number") {
            if (disableAds) {
                AdMobHelper.hideBannerView();
            } else {
                AdMobHelper.showBannerView();
            }
        } else {
            AdMobHelper.hideBannerView();
        }

        if (increaseTrackingLimits) {
            VKHelper.maxTrustedFriendsCount = 15;
        } else {
            VKHelper.maxTrustedFriendsCount = 5;
        }

        if (enableTrackedFriends) {
            if (increaseTrackingLimits) {
                VKHelper.maxTrackedFriendsCount = 15;
            } else {
                VKHelper.maxTrackedFriendsCount = 5;
            }
        } else {
            VKHelper.maxTrackedFriendsCount = 0;
        }

        if (configuredTheme === "LIGHT") {
            UIHelper.configuredTheme = UITheme.ThemeLight;
        } else if (configuredTheme === "DARK") {
            UIHelper.configuredTheme = UITheme.ThemeDark;
        } else {
            UIHelper.configuredTheme = UITheme.ThemeAuto;
        }
    }

    function showInterstitial() {
        if (!disableAds) {
            AdMobHelper.showInterstitial();
        }
    }

    Store {
        id: store

        function getPrice(status, price) {
            if (status === Product.Registered) {
                var result = /([\d \.,]+)/.exec(price);

                if (Array.isArray(result) && result.length > 1) {
                    return result[1].trim();
                } else {
                    return qsTr("BUY");
                }
            } else {
                return qsTr("BUY");
            }
        }

        Product {
            id:         trackedFriendsProduct
            identifier: "vkgeo.unlockable.trackedfriends"
            type:       Product.Unlockable

            onPurchaseSucceeded: {
                mainWindow.disableAds           = true;
                mainWindow.enableTrackedFriends = true;

                transaction.finalize();
            }

            onPurchaseRestored: {
                mainWindow.disableAds           = true;
                mainWindow.enableTrackedFriends = true;

                transaction.finalize();
            }

            onPurchaseFailed: {
                if (transaction.failureReason === Transaction.ErrorOccurred) {
                    console.error(transaction.errorString);
                }

                transaction.finalize();
            }
        }

        Product {
            id:         increasedLimitsProduct
            identifier: "vkgeo.unlockable.increasedlimits"
            type:       Product.Unlockable

            onPurchaseSucceeded: {
                mainWindow.disableAds             = true;
                mainWindow.increaseTrackingLimits = true;

                transaction.finalize();
            }

            onPurchaseRestored: {
                mainWindow.disableAds             = true;
                mainWindow.increaseTrackingLimits = true;

                transaction.finalize();
            }

            onPurchaseFailed: {
                if (transaction.failureReason === Transaction.ErrorOccurred) {
                    console.error(transaction.errorString);
                }

                transaction.finalize();
            }
        }
    }

    StackView {
        id:           mainStackView
        anchors.fill: parent

        onCurrentItemChanged: {
            for (var i = 0; i < depth; i++) {
                var item = get(i, StackView.DontLoad);

                if (item !== null) {
                    item.focus = false;
                }
            }

            if (depth > 0) {
                currentItem.forceActiveFocus();

                if (typeof currentItem.bannerViewHeight === "number") {
                    if (mainWindow.disableAds) {
                        AdMobHelper.hideBannerView();
                    } else {
                        AdMobHelper.showBannerView();
                    }
                } else {
                    AdMobHelper.hideBannerView();
                }
            } else {
                AdMobHelper.hideBannerView();
            }
        }
    }

    MultiPointTouchArea {
        anchors.fill: parent
        z:            1
        enabled:      mainStackView.busy
    }

    AdMobConsentDialog {
        id: adMobConsentDialog

        onPersonalizedAdsSelected: {
            mainWindow.adMobConsent = "PERSONALIZED";
        }

        onNonPersonalizedAdsSelected: {
            mainWindow.adMobConsent = "NON_PERSONALIZED";
        }
    }

    Component.onCompleted: {
        disableAds             = AppSettings.disableAds;
        enableTrackedFriends   = AppSettings.enableTrackedFriends;
        increaseTrackingLimits = AppSettings.increaseTrackingLimits;
        appRated               = AppSettings.appRated;
        configuredTheme        = AppSettings.configuredTheme;
        adMobConsent           = AppSettings.adMobConsent;

        updateFeatures();

        var component = Qt.createComponent("Core/MainPage.qml");

        if (component.status === Component.Ready) {
            mainStackView.push(component);
        } else {
            console.error(component.errorString());
        }

        if (!disableAds && adMobConsent !== "PERSONALIZED" && adMobConsent !== "NON_PERSONALIZED") {
            adMobConsentDialog.open();
        }

        componentCompleted = true;
    }
}
