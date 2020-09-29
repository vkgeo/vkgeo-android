import QtQuick 2.12
import QtQuick.Controls 2.5
import QtPurchasing 1.0
import UIHelper 1.0
import VKHelper 1.0

import "Core/Dialog"

ApplicationWindow {
    id:      mainWindow
    title:   qsTr("Friends on Map")
    visible: true

    readonly property int vkAuthState:         VKHelper.authState

    readonly property string publicKey:        CryptoHelper.publicKey
    readonly property string privateKey:       CryptoHelper.privateKey

    readonly property var publicKeysOfFriends: CryptoHelper.publicKeysOfFriends

    property bool componentCompleted:          false
    property bool enableEncryption:            false
    property bool enableTrackedFriends:        false
    property bool increaseTrackingLimits:      false

    property string configuredTheme:           ""

    property var loginPage:                    null

    onVkAuthStateChanged: {
        if (componentCompleted) {
            if (vkAuthState === VKAuthState.StateNotAuthorized) {
                openLoginPage();
            } else if (vkAuthState === VKAuthState.StateAuthorized) {
                closeLoginPage();
            }
        }
    }

    onPublicKeyChanged: {
        if (componentCompleted) {
            AppSettings.publicKey = publicKey;
        }
    }

    onPrivateKeyChanged: {
        if (componentCompleted) {
            AppSettings.privateKey = privateKey;
        }
    }

    onPublicKeysOfFriendsChanged: {
        if (componentCompleted) {
            AppSettings.publicKeysOfFriends = publicKeysOfFriends;
        }
    }

    onComponentCompletedChanged: {
        if (componentCompleted) {
            if (vkAuthState === VKAuthState.StateNotAuthorized) {
                openLoginPage();
            } else if (vkAuthState === VKAuthState.StateAuthorized) {
                closeLoginPage();
            }

            AppSettings.publicKey           = publicKey;
            AppSettings.privateKey          = privateKey;
            AppSettings.publicKeysOfFriends = publicKeysOfFriends;
        }
    }

    onEnableEncryptionChanged: {
        AppSettings.enableEncryption = enableEncryption;

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

    onConfiguredThemeChanged: {
        AppSettings.configuredTheme = configuredTheme;

        updateFeatures();
    }

    function openLoginPage() {
        if (!loginPage) {
            var component = Qt.createComponent("Core/LoginPage.qml");

            if (component.status === Component.Ready) {
                loginPage = mainStackView.push(component);
            } else {
                console.error(component.errorString());
            }
        }
    }

    function closeLoginPage() {
        if (loginPage) {
            mainStackView.pop(loginPage);
            mainStackView.pop();

            loginPage = null;
        }
    }

    function updateFeatures() {
        VKHelper.encryptionEnabled = enableEncryption;

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
                mainWindow.enableTrackedFriends = true;

                transaction.finalize();
            }

            onPurchaseRestored: {
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
                mainWindow.increaseTrackingLimits = true;

                transaction.finalize();
            }

            onPurchaseRestored: {
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

                if (item) {
                    item.focus = false;
                }
            }

            if (depth > 0) {
                currentItem.forceActiveFocus();
            }
        }
    }

    MultiPointTouchArea {
        anchors.fill: parent
        z:            1
        enabled:      mainStackView.busy
    }

    Component.onCompleted: {
        if (CryptoHelper.validateKeyPair(AppSettings.publicKey, AppSettings.privateKey)) {
            CryptoHelper.publicKey  = AppSettings.publicKey;
            CryptoHelper.privateKey = AppSettings.privateKey;
        } else {
            CryptoHelper.regenerateKeyPair();
        }

        CryptoHelper.publicKeysOfFriends = AppSettings.publicKeysOfFriends;

        enableEncryption       = AppSettings.enableEncryption;
        enableTrackedFriends   = AppSettings.enableTrackedFriends;
        increaseTrackingLimits = AppSettings.increaseTrackingLimits;
        configuredTheme        = AppSettings.configuredTheme;

        updateFeatures();

        var component = Qt.createComponent("Core/MainPage.qml");

        if (component.status === Component.Ready) {
            mainStackView.push(component);
        } else {
            console.error(component.errorString());
        }

        componentCompleted = true;
    }
}
