import QtQuick 2.12
import QtQuick.Controls 2.5
import QtPositioning 5.12
import VKHelper 1.0

import "Main"

import "../Util.js" as UtilScript

Page {
    id: mainPage

    header: Rectangle {
        height: mainPage.bannerViewHeight
        color:  UIHelper.darkTheme ? "midnightblue" : "lightsteelblue"
    }

    background: Rectangle {
        color: UIHelper.darkTheme ? "black" : "white"
    }

    footer: TabBar {
        id: tabBar

        background: Rectangle {
            color: UIHelper.darkTheme ? "midnightblue" : "lightsteelblue"
        }

        TabButton {
            id:             mapTabButton
            implicitHeight: UtilScript.dp(UIHelper.screenDpi, 48)

            background: Rectangle {
                color: tabBar.currentIndex === 0 ? "steelblue" : (UIHelper.darkTheme ? "midnightblue" :
                                                                                       "lightsteelblue")
            }

            contentItem: Image {
                source:   "qrc:/resources/images/main/tab_map.png"
                fillMode: Image.PreserveAspectFit
            }
        }

        TabButton {
            id:             peopleTabButton
            implicitHeight: UtilScript.dp(UIHelper.screenDpi, 48)

            background: Rectangle {
                color: tabBar.currentIndex === 1 ? "steelblue" : (UIHelper.darkTheme ? "midnightblue" :
                                                                                       "lightsteelblue")
            }

            contentItem: Image {
                source:   "qrc:/resources/images/main/tab_people.png"
                fillMode: Image.PreserveAspectFit
            }
        }

        TabButton {
            id:             settingsTabButton
            implicitHeight: UtilScript.dp(UIHelper.screenDpi, 48)

            background: Rectangle {
                color: tabBar.currentIndex === 2 ? "steelblue" : (UIHelper.darkTheme ? "midnightblue" :
                                                                                       "lightsteelblue")
            }

            contentItem: Image {
                source:   "qrc:/resources/images/main/tab_settings.png"
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    readonly property bool appInForeground: Qt.application.state === Qt.ApplicationActive
    readonly property bool pageActive:      StackView.status === StackView.Active

    readonly property int bannerViewHeight: AdMobHelper.bannerViewHeight
    readonly property int vkAuthState:      VKHelper.authState

    property bool componentCompleted:       false

    onVkAuthStateChanged: {
        if (vkAuthState === VKAuthState.StateAuthorized && componentCompleted) {
            VKHelper.updateFriends();
        }
    }

    onComponentCompletedChanged: {
        if (vkAuthState === VKAuthState.StateAuthorized && componentCompleted) {
            VKHelper.updateFriends();
        }
    }

    Keys.onReleased: {
        if (event.key === Qt.Key_Back && settingsSwipe.handleBackKey()) {
            event.accepted = true;
        }
    }

    SwipeView {
        anchors.fill: parent
        currentIndex: tabBar.currentIndex
        interactive:  false

        MapSwipe {
            id: mapSwipe

            onProfilePageRequested: {
                friendsSwipe.openProfilePage(userId);
            }
        }

        FriendsSwipe {
            id: friendsSwipe

            onLocationOnMapRequested: {
                mapSwipe.locateItemOnMap(userId);

                tabBar.setCurrentIndex(0);
            }
        }

        SettingsSwipe {
            id: settingsSwipe
        }
    }

    PositionSource {
        id:                          positionSource
        updateInterval:              1000
        preferredPositioningMethods: PositionSource.AllPositioningMethods
        active:                      mainPage.appInForeground

        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                VKHelper.updateLocation(position.coordinate.latitude,
                                        position.coordinate.longitude);

                VKHelper.updateBatteryStatus(BatteryHelper.getBatteryStatus(),
                                             BatteryHelper.getBatteryLevel());
            }
        }
    }

    Timer {
        id:       updateTimer
        running:  mainPage.appInForeground
        interval: 1000
        repeat:   true

        onTriggered: {
            VKHelper.updateTrackedFriendsData(false);

            mapSwipe.updateMapItemsStates();
        }
    }

    Timer {
        id:       backgroundLocationPermissionRequestTimer
        running:  mainPage.appInForeground && mainPage.pageActive && !wasRequested
        interval: 5000
        repeat:   true

        property bool wasRequested: false

        onTriggered: {
            if (UIHelper.hasFineLocationPermission()) {
                UIHelper.requestBackgroundLocationPermission();

                wasRequested = true;
            }
        }
    }

    Connections {
        target: VKHelper

        onDataSent: {
            VKHelper.updateTrackedFriendsData(true);
        }

        onFriendsUpdated: {
            VKHelper.updateTrackedFriendsData(true);
        }
    }

    Component.onCompleted: {
        componentCompleted = true;
    }
}
