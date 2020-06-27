import QtQuick 2.12
import QtQuick.Controls 2.5
import UIHelper 1.0
import VKHelper 1.0

import "Core/Dialog"

ApplicationWindow {
    id:      mainWindow
    title:   qsTr("Friends on Map")
    visible: true

    readonly property int screenDpi:           UIHelper.screenDpi
    readonly property int vkAuthState:         VKHelper.authState

    readonly property string sharedKey:        CryptoHelper.sharedKey

    readonly property var sharedKeysOfFriends: CryptoHelper.sharedKeysOfFriends

    property bool componentCompleted:          false
    property bool enableEncryption:            false

    property string configuredTheme:           ""
    property string adMobConsent:              ""

    property var loginPage:                    null

    onScreenDpiChanged: {
        if (mainStackView.depth > 0 && typeof mainStackView.currentItem.bannerViewHeight === "number") {
            AdMobHelper.showBannerView();
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

    onSharedKeyChanged: {
        if (componentCompleted) {
            AppSettings.sharedKey = sharedKey;
        }
    }

    onSharedKeysOfFriendsChanged: {
        if (componentCompleted) {
            AppSettings.sharedKeysOfFriends = sharedKeysOfFriends;
        }
    }

    onComponentCompletedChanged: {
        if (componentCompleted) {
            if (vkAuthState === VKAuthState.StateNotAuthorized) {
                openLoginPage();
            } else if (vkAuthState === VKAuthState.StateAuthorized) {
                closeLoginPage();
            }

            AppSettings.sharedKey           = sharedKey;
            AppSettings.sharedKeysOfFriends = sharedKeysOfFriends;
        }
    }

    onEnableEncryptionChanged: {
        AppSettings.enableEncryption = enableEncryption;

        updateFeatures();
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
        if (adMobConsent === "PERSONALIZED" || adMobConsent === "NON_PERSONALIZED") {
            AdMobHelper.setPersonalization(adMobConsent === "PERSONALIZED");

            AdMobHelper.initAds();
        }

        if (mainStackView.depth > 0 && typeof mainStackView.currentItem.bannerViewHeight === "number") {
            AdMobHelper.showBannerView();
        } else {
            AdMobHelper.hideBannerView();
        }

        VKHelper.encryptionEnabled      = enableEncryption;
        VKHelper.maxTrustedFriendsCount = 15;
        VKHelper.maxTrackedFriendsCount = 15;

        if (configuredTheme === "LIGHT") {
            UIHelper.configuredTheme = UITheme.ThemeLight;
        } else if (configuredTheme === "DARK") {
            UIHelper.configuredTheme = UITheme.ThemeDark;
        } else {
            UIHelper.configuredTheme = UITheme.ThemeAuto;
        }
    }

    function showInterstitial() {
        AdMobHelper.showInterstitial();
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
                    AdMobHelper.showBannerView();
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
        if (AppSettings.sharedKey !== "") {
            CryptoHelper.sharedKey = AppSettings.sharedKey;
        } else {
            CryptoHelper.regenerateSharedKey();
        }

        CryptoHelper.sharedKeysOfFriends = AppSettings.sharedKeysOfFriends;

        enableEncryption = AppSettings.enableEncryption;
        configuredTheme  = AppSettings.configuredTheme;
        adMobConsent     = AppSettings.adMobConsent;

        updateFeatures();

        var component = Qt.createComponent("Core/MainPage.qml");

        if (component.status === Component.Ready) {
            mainStackView.push(component);
        } else {
            console.error(component.errorString());
        }

        if (adMobConsent !== "PERSONALIZED" && adMobConsent !== "NON_PERSONALIZED") {
            adMobConsentDialog.open();
        }

        componentCompleted = true;
    }
}
