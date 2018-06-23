import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.0
import QtPurchasing 1.0
import VKHelper 1.0

import "Core"

Window {
    id:      mainWindow
    visible: true

    property bool disableAds:             false
    property bool enableTrackedFriends:   false
    property bool increaseTrackingLimits: false

    property int vkAuthState:             VKHelper.authState
    property var loginPage:               null

    onDisableAdsChanged: {
        setSetting("DisableAds", disableAds ? "true" : "false");

        updateFeatures();
    }

    onEnableTrackedFriendsChanged: {
        setSetting("EnableTrackedFriends", enableTrackedFriends ? "true" : "false");

        updateFeatures();
    }

    onIncreaseTrackingLimitsChanged: {
        setSetting("IncreaseTrackingLimits", increaseTrackingLimits ? "true" : "false");

        updateFeatures();
    }

    onVkAuthStateChanged: {
        if (vkAuthState === VKAuthState.StateNotAuthorized) {
            showLoginPage();
        }
    }

    function setSetting(key, value) {
        var db = LocalStorage.openDatabaseSync("VKGeoDB", "1.0", "VKGeoDB", 1000000);

        db.transaction(
                    function(tx) {
                        tx.executeSql("CREATE TABLE IF NOT EXISTS SETTINGS(KEY TEXT PRIMARY KEY, VALUE TEXT)");

                        tx.executeSql("REPLACE INTO SETTINGS (KEY, VALUE) VALUES (?, ?)", [key, value]);
                    }
        );
    }

    function getSetting(key, defaultValue) {
        var value = defaultValue;
        var db    = LocalStorage.openDatabaseSync("VKGeoDB", "1.0", "VKGeoDB", 1000000);

        db.transaction(
                    function(tx) {
                        tx.executeSql("CREATE TABLE IF NOT EXISTS SETTINGS(KEY TEXT PRIMARY KEY, VALUE TEXT)");

                        var res = tx.executeSql("SELECT VALUE FROM SETTINGS WHERE KEY=?", [key]);

                        if (res.rows.length !== 0) {
                            value = res.rows.item(0).VALUE;
                        }
                    }
        );

        return value;
    }

    function showLoginPage() {
        if (loginPage === null && mainStackView.depth > 0) {
            var component = Qt.createComponent("Core/LoginPage.qml");

            if (component.status === Component.Ready) {
                loginPage = mainStackView.push(component);
            } else {
                console.log(component.errorString());
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
        if (mainStackView.depth > 0 && mainStackView.currentItem.hasOwnProperty("bannerViewHeight")) {
            if (disableAds) {
                AdMobHelper.hideBannerView();
            } else {
                AdMobHelper.showBannerView();
            }
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
    }

    function showInterstitial() {
        if (!disableAds && AdMobHelper.interstitialReady) {
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
                    console.log(transaction.errorString);
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
                    console.log(transaction.errorString);
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
                var item = get(i, false);

                if (item !== null) {
                    item.focus = false;
                }
            }

            if (depth > 0) {
                currentItem.forceActiveFocus();

                if (currentItem.hasOwnProperty("bannerViewHeight")) {
                    if (mainWindow.disableAds) {
                        AdMobHelper.hideBannerView();
                    } else {
                        AdMobHelper.showBannerView();
                    }
                } else {
                    AdMobHelper.hideBannerView();
                }
            }
        }
    }

    MainPage {
        id: mainPage
    }

    MouseArea {
        id:           screenLockMouseArea
        anchors.fill: parent
        z:            100
        enabled:      mainStackView.busy
    }

    Component.onCompleted: {
        disableAds             = (getSetting("DisableAds",             "false") === "true");
        enableTrackedFriends   = (getSetting("EnableTrackedFriends",   "false") === "true");
        increaseTrackingLimits = (getSetting("IncreaseTrackingLimits", "false") === "true");

        updateFeatures();

        AdMobHelper.initialize();
        NotificationHelper.initialize();
        VKHelper.initialize();

        mainStackView.push(mainPage);

        if (vkAuthState === VKAuthState.StateNotAuthorized) {
            showLoginPage();
        }
    }
}
