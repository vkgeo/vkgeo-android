import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import UIHelper 1.0

import "../Dialog"
import "../Misc"

import "../../Util.js" as UtilScript

Rectangle {
    id:    settingsSwipe
    color: "transparent"

    function handleBackKey() {
        if (themeSelectionDialog.visible) {
            themeSelectionDialog.close();

            return true;
        } else {
            return false;
        }
    }

    Toast {
        id:              friendsListUpdatedToast
        anchors.top:     parent.top
        anchors.left:    parent.left
        anchors.right:   parent.right
        anchors.margins: UtilScript.dp(UIHelper.screenDpi, 4)
        z:               1
        height:          UtilScript.dp(UIHelper.screenDpi, 48)
        text:            qsTr("Settings has been updated successfully")
    }

    Toast {
        id:              friendsListUpdateFailedToast
        anchors.top:     parent.top
        anchors.left:    parent.left
        anchors.right:   parent.right
        anchors.margins: UtilScript.dp(UIHelper.screenDpi, 4)
        z:               1
        height:          UtilScript.dp(UIHelper.screenDpi, 48)
        text:            qsTr("Failed to update settings, please try again later")
        backgroundColor: "red"
    }

    Toast {
        id:              joiningVKGeoGroupCompletedToast
        anchors.top:     parent.top
        anchors.left:    parent.left
        anchors.right:   parent.right
        anchors.margins: UtilScript.dp(UIHelper.screenDpi, 4)
        z:               1
        height:          UtilScript.dp(UIHelper.screenDpi, 48)
        text:            qsTr("You have successfully joined the group")
    }

    Toast {
        id:              joiningVKGeoGroupFailedToast
        anchors.top:     parent.top
        anchors.left:    parent.left
        anchors.right:   parent.right
        anchors.margins: UtilScript.dp(UIHelper.screenDpi, 4)
        z:               1
        height:          UtilScript.dp(UIHelper.screenDpi, 48)
        text:            qsTr("Failed to join group, please try again later")
        backgroundColor: "red"
    }

    Flickable {
        id:                   settingsFlickable
        anchors.fill:         parent
        anchors.topMargin:    UtilScript.dp(UIHelper.screenDpi, 16)
        anchors.bottomMargin: UtilScript.dp(UIHelper.screenDpi, 16)
        contentWidth:         settingsLayout.width
        contentHeight:        settingsLayout.height
        clip:                 true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        ColumnLayout {
            id:      settingsLayout
            width:   settingsFlickable.width
            spacing: UtilScript.dp(UIHelper.screenDpi, 16)

            Text {
                leftPadding:         UtilScript.dp(UIHelper.screenDpi, 16)
                rightPadding:        UtilScript.dp(UIHelper.screenDpi, 16)
                text:                qsTr("You can see the location of trusted friends, if they also treat you as a trusted friend, and they <b>can see your location</b>.")
                color:               UIHelper.darkTheme ? "white"     : "black"
                linkColor:           UIHelper.darkTheme ? "lightblue" : "blue"
                font.pixelSize:      UtilScript.dp(UIHelper.screenDpi, 16)
                font.family:         "Helvetica"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPixelSize:    UtilScript.dp(UIHelper.screenDpi, 8)
                textFormat:          Text.StyledText
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter
            }

            Text {
                leftPadding:         UtilScript.dp(UIHelper.screenDpi, 16)
                rightPadding:        UtilScript.dp(UIHelper.screenDpi, 16)
                text:                textText(VKHelper.maxTrustedFriendsCount)
                color:               UIHelper.darkTheme ? "white" : "black"
                font.pixelSize:      UtilScript.dp(UIHelper.screenDpi, 16)
                font.family:         "Helvetica"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPixelSize:    UtilScript.dp(UIHelper.screenDpi, 8)
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter

                function textText(max_count) {
                    if (max_count > 0) {
                        return qsTr("Currently you can have up to %1 trusted friends.").arg(max_count);
                    } else {
                        return qsTr("Currently you can't have trusted friends.");
                    }
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Trusted friends list")
                enabled:          VKHelper.friendsCount > 0 && VKHelper.maxTrustedFriendsCount > 0
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    var component = Qt.createComponent("../TrustedFriendsPage.qml");

                    if (component.status === Component.Ready) {
                        mainStackView.push(component);

                        if (Math.random() < 0.30) {
                            mainWindow.showInterstitial();
                        }
                    } else {
                        console.log(component.errorString());
                    }
                }
            }

            ToolSeparator {
                orientation:      Qt.Horizontal
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                leftPadding:         UtilScript.dp(UIHelper.screenDpi, 16)
                rightPadding:        UtilScript.dp(UIHelper.screenDpi, 16)
                text:                qsTr("You can see the location of tracked friends, if they treat you as a trusted friend, but they <b>cannot see your location</b>.")
                color:               UIHelper.darkTheme ? "white"     : "black"
                linkColor:           UIHelper.darkTheme ? "lightblue" : "blue"
                font.pixelSize:      UtilScript.dp(UIHelper.screenDpi, 16)
                font.family:         "Helvetica"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPixelSize:    UtilScript.dp(UIHelper.screenDpi, 8)
                textFormat:          Text.StyledText
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter
            }

            Text {
                leftPadding:         UtilScript.dp(UIHelper.screenDpi, 16)
                rightPadding:        UtilScript.dp(UIHelper.screenDpi, 16)
                text:                textText(VKHelper.maxTrackedFriendsCount)
                color:               UIHelper.darkTheme ? "white" : "black"
                font.pixelSize:      UtilScript.dp(UIHelper.screenDpi, 16)
                font.family:         "Helvetica"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPixelSize:    UtilScript.dp(UIHelper.screenDpi, 8)
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter

                function textText(max_count) {
                    if (max_count > 0) {
                        return qsTr("Currently you can have up to %1 tracked friends.").arg(max_count);
                    } else {
                        return qsTr("Currently you can't have tracked friends.");
                    }
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Tracked friends list")
                enabled:          VKHelper.friendsCount > 0 && VKHelper.maxTrackedFriendsCount > 0
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    var component = Qt.createComponent("../TrackedFriendsPage.qml");

                    if (component.status === Component.Ready) {
                        mainStackView.push(component);

                        if (Math.random() < 0.30) {
                            mainWindow.showInterstitial();
                        }
                    } else {
                        console.log(component.errorString());
                    }
                }
            }

            ToolSeparator {
                orientation:      Qt.Horizontal
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             buttonText(mainWindow.configuredTheme)
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    themeSelectionDialog.open();
                }

                function buttonText(configured_theme) {
                    var theme_name = "";

                    if (configured_theme === "LIGHT") {
                        theme_name = qsTr("light");
                    } else if (configured_theme === "DARK") {
                        theme_name = qsTr("dark");
                    } else {
                        theme_name = qsTr("auto");
                    }

                    return qsTr("Interface theme: %1").arg(theme_name);
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Ad privacy settings")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    adMobConsentDialog.open();
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Additional settings")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    UIHelper.showAppSettings();
                }
            }

            ToolSeparator {
                orientation:      Qt.Horizontal
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Support")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    var support_url = qsTr("https://vkgeo.sourceforge.io/");

                    if (support_url.startsWith("http://") || support_url.startsWith("https://")) {
                        Qt.openUrlExternally(support_url);
                    } else if (!Qt.openUrlExternally("vk://vk.com/%1".arg(support_url))) {
                        Qt.openUrlExternally("https://m.vk.com/%1".arg(support_url));
                    }
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Join VKGeo Friends on Map group")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    joinVKGeoGroupMessageDialog.open();
                }
            }

            ToolSeparator {
                orientation:      Qt.Horizontal
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("View my VK profile")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    var component = Qt.createComponent("../ProfilePage.qml");

                    if (component.status === Component.Ready) {
                        var my_profile_page = mainStackView.push(component);

                        my_profile_page.userId            = VKHelper.userId;
                        my_profile_page.online            = false;
                        my_profile_page.dataAvailable     = false;
                        my_profile_page.locationAvailable = false;
                        my_profile_page.firstName         = VKHelper.firstName;
                        my_profile_page.lastName          = VKHelper.lastName;
                        my_profile_page.bigPhotoUrl       = VKHelper.bigPhotoUrl;
                        my_profile_page.screenName        = "id%1".arg(VKHelper.userId);
                        my_profile_page.status            = "";
                        my_profile_page.batteryStatus     = "";
                    } else {
                        console.log(component.errorString());
                    }
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Log out of VK")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    VKHelper.logout();
                }
            }
        }
    }

    ThemeSelectionDialog {
        id: themeSelectionDialog

        onAutoThemeSelected: {
            mainWindow.configuredTheme = "";
        }

        onLightThemeSelected: {
            mainWindow.configuredTheme = "LIGHT";
        }

        onDarkThemeSelected: {
            mainWindow.configuredTheme = "DARK";
        }
    }

    MessageDialog {
        id:              joinVKGeoGroupMessageDialog
        title:           qsTr("Join group")
        text:            qsTr("Do you want to join the VKGeo Friends on Map group?")
        standardButtons: StandardButton.Yes | StandardButton.No

        onYes: {
            VKHelper.joinGroup("166101702");
        }
    }

    Connections {
        target: VKHelper

        onTrustedFriendsListUpdated: {
            friendsListUpdatedToast.visible = true;
        }

        onTrustedFriendsListUpdateFailed: {
            friendsListUpdateFailedToast.visible = true;
        }

        onTrackedFriendsListUpdated: {
            friendsListUpdatedToast.visible = true;
        }

        onTrackedFriendsListUpdateFailed: {
            friendsListUpdateFailedToast.visible = true;
        }

        onJoiningGroupCompleted: {
            joiningVKGeoGroupCompletedToast.visible = true;
        }

        onJoiningGroupFailed: {
            joiningVKGeoGroupFailedToast.visible = true;
        }
    }
}
