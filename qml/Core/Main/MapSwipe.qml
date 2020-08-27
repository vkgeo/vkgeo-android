import QtQuick 2.12
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import QtPositioning 5.12
import QtLocation 5.12

import "../../Util.js" as UtilScript

Rectangle {
    id:    mapSwipe
    color: "transparent"

    signal profilePageRequested(string userId)

    function updateMapItemsStates() {
        for (var i = 0; i < map.mapItems.length; i++) {
            map.mapItems[i].updateState();
        }
    }

    function locateItemOnMap(user_id) {
        for (var i = 0; i < map.mapItems.length; i++) {
            var map_item = map.mapItems[i];

            if (user_id === map_item.userId) {
                map.trackMapItem(map_item);

                break;
            }
        }
    }

    Map {
        id:           map
        anchors.fill: parent

        readonly property int autoActionRepetitionsCount: 10

        readonly property real centerBearing:             0.0
        readonly property real centerTilt:                0.0
        readonly property real centerZoomLevel:           16.0

        property bool wasTouched:                         false
        property bool wasCenterOnMyMapItem:               false
        property bool autoAction:                         false

        property var myMapItem:                           null
        property var trackedMapItem:                      null

        plugin: Plugin {
            name: "osm"

            PluginParameter {
                name:  "osm.useragent"
                value: "VKGeo"
            }

            PluginParameter {
                name:  "osm.mapping.highdpi_tiles"
                value: "true"
            }
        }

        onBearingChanged: {
            if (!autoAction) {
                wasTouched = true;

                trackMapItem(null);
            }
        }

        onCenterChanged: {
            if (!autoAction) {
                wasTouched = true;

                trackMapItem(null);
            }
        }

        onTiltChanged: {
            if (!autoAction) {
                wasTouched = true;

                trackMapItem(null);
            }
        }

        onZoomLevelChanged: {
            if (!autoAction) {
                wasTouched = true;

                trackMapItem(null);
            }
        }

        onCopyrightLinkActivated: {
            Qt.openUrlExternally(link);
        }

        function trackMapItem(map_item) {
            if (trackedMapItem !== null) {
                trackedMapItem.coordinateChanged.disconnect(centerOnTrackedMapItem);
            }

            trackedMapItem = map_item;

            if (trackedMapItem !== null) {
                trackedMapItem.coordinateChanged.connect(centerOnTrackedMapItem);
            }

            centerOnTrackedMapItem();
        }

        function centerOnTrackedMapItem() {
            if (trackedMapItem !== null) {
                autoAction = true;

                for (var i = 0; i < autoActionRepetitionsCount; i++) {
                    center    = trackedMapItem.coordinate;
                    bearing   = centerBearing;
                    tilt      = centerTilt;
                    zoomLevel = centerZoomLevel;
                }

                autoAction = false;
            }
        }

        function centerOnMyMapItemOnce() {
            if (!wasCenterOnMyMapItem && myMapItem !== null) {
                autoAction = true;

                for (var i = 0; i < autoActionRepetitionsCount; i++) {
                    center    = myMapItem.coordinate;
                    bearing   = centerBearing;
                    tilt      = centerTilt;
                    zoomLevel = centerZoomLevel;
                }

                wasCenterOnMyMapItem = true;

                autoAction = false;
            }
        }

        function showAllMapItems() {
            autoAction = true;

            for (var i = 0; i < autoActionRepetitionsCount; i++) {
                fitViewportToVisibleMapItems();
            }

            autoAction = false;
        }
    }

    Image {
        anchors.left:         parent.left
        anchors.bottom:       parent.bottom
        anchors.leftMargin:   UtilScript.dp(UIHelper.screenDpi, 8)
        anchors.bottomMargin: UtilScript.dp(UIHelper.screenDpi, 32)
        z:                    1
        width:                UtilScript.dp(UIHelper.screenDpi, 48)
        height:               UtilScript.dp(UIHelper.screenDpi, 48)
        source:               "qrc:/resources/images/main/button_show_all.png"
        fillMode:             Image.PreserveAspectFit

        MouseArea {
            anchors.fill: parent

            onClicked: {
                map.trackMapItem(null);
                map.showAllMapItems();
            }
        }
    }

    Image {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     UtilScript.dp(UIHelper.screenDpi, 32)
        z:                        1
        width:                    UtilScript.dp(UIHelper.screenDpi, 48)
        height:                   UtilScript.dp(UIHelper.screenDpi, 48)
        source:                   enabled ? "qrc:/resources/images/main/button_update.png" :
                                            "qrc:/resources/images/main/button_update_disabled.png"
        fillMode:                 Image.PreserveAspectFit
        enabled:                  map.myMapItem !== null && map.myMapItem.visible

        MouseArea {
            anchors.fill: parent

            onClicked: {
                updateMessageDialog.open();
            }
        }
    }

    Image {
        anchors.right:        parent.right
        anchors.bottom:       parent.bottom
        anchors.rightMargin:  UtilScript.dp(UIHelper.screenDpi, 8)
        anchors.bottomMargin: UtilScript.dp(UIHelper.screenDpi, 32)
        z:                    1
        width:                UtilScript.dp(UIHelper.screenDpi, 48)
        height:               UtilScript.dp(UIHelper.screenDpi, 48)
        source:               enabled ? "qrc:/resources/images/main/button_track.png" :
                                        "qrc:/resources/images/main/button_track_disabled.png"
        fillMode:             Image.PreserveAspectFit
        enabled:              map.myMapItem !== null && map.myMapItem.visible

        MouseArea {
            anchors.fill: parent

            onClicked: {
                map.trackMapItem(map.myMapItem);
            }
        }
    }

    MessageDialog {
        id:              updateMessageDialog
        title:           qsTr("Update location data")
        text:            qsTr("Do you want to update location data in your VK profile now?")
        standardButtons: StandardButton.Yes | StandardButton.No

        onYes: {
            VKHelper.sendDataImmediately();
        }
    }

    Connections {
        target: VKHelper

        onLocationUpdated: {
            if (VKHelper.locationValid && map.myMapItem !== null) {
                map.myMapItem.coordinate = QtPositioning.coordinate(VKHelper.latitude, VKHelper.longitude);
                map.myMapItem.updateTime = VKHelper.updateTime;

                if (!map.wasTouched && map.trackedMapItem === null) {
                    map.centerOnMyMapItemOnce();
                }
            }
        }

        onFriendsUpdated: {
            var tracked_map_item_id = null;

            if (map.trackedMapItem !== null) {
                tracked_map_item_id = map.trackedMapItem.userId;
            }

            map.trackMapItem(null);

            for (var i = map.mapItems.length - 1; i >= 0; i--) {
                var map_item = map.mapItems[i];

                map.removeMapItem(map_item);

                if (map_item !== map.myMapItem) {
                    map_item.destroy();
                }
            }

            var friends_list = VKHelper.getFriendsList();

            var component = Qt.createComponent("VKMapItem.qml");

            if (component.status === Component.Ready) {
                for (var j = 0; j < friends_list.length; j++) {
                    var frnd = friends_list[j];

                    if (frnd.trusted || frnd.tracked) {
                        var new_map_item = component.createObject(map, {"userId": frnd.userId, "photoUrl": frnd.photoUrl});

                        new_map_item.profilePageRequested.connect(mapSwipe.profilePageRequested);

                        map.addMapItem(new_map_item);

                        if (new_map_item.userId === tracked_map_item_id) {
                            map.trackMapItem(new_map_item);
                        }
                    }
                }
            } else {
                console.error(component.errorString());
            }

            map.addMapItem(map.myMapItem);

            if (tracked_map_item_id === "") {
                map.trackMapItem(map.myMapItem);
            }

            if (map.mapItems.length > 1 && Math.random() < 0.10) {
                GPlayHelper.requestReview();
            }
        }

        onTrackedFriendDataUpdated: {
            for (var i = 0; i < map.mapItems.length; i++) {
                var map_item = map.mapItems[i];

                if (friendUserId === map_item.userId) {
                    if (typeof friendData.update_time === "number" && isFinite(friendData.update_time) &&
                        typeof friendData.latitude    === "number" && isFinite(friendData.latitude) &&
                        typeof friendData.longitude   === "number" && isFinite(friendData.longitude)) {
                        map_item.coordinate = QtPositioning.coordinate(friendData.latitude, friendData.longitude);
                        map_item.updateTime = friendData.update_time;
                    } else {
                        if (map_item === map.trackedMapItem) {
                            map.trackMapItem(null);
                        }

                        map_item.coordinate = QtPositioning.coordinate();
                        map_item.updateTime = 0;
                    }

                    break;
                }
            }

            if (!map.wasTouched && map.trackedMapItem === null) {
                map.showAllMapItems();
            }
        }
    }

    Component.onCompleted: {
        var component = Qt.createComponent("VKMapItem.qml");

        if (component.status === Component.Ready) {
            map.myMapItem = component.createObject(map);

            map.myMapItem.userId   = "";
            map.myMapItem.photoUrl = Qt.binding(function() { return VKHelper.photoUrl; });

            map.myMapItem.profilePageRequested.connect(profilePageRequested);

            map.addMapItem(map.myMapItem);
        } else {
            console.error(component.errorString());
        }
    }
}
