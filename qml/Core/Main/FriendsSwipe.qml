import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import "../Misc"

import "../../Util.js" as UtilScript

Rectangle {
    id:    friendsSwipe
    color: "transparent"

    property var friendsList: []

    signal locationOnMapRequested(string userId)

    function updateModel() {
        friendsListModel.clear();

        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            if ("%1 %2".arg(frnd.firstName).arg(frnd.lastName).toUpperCase()
                       .includes(filterTextField.filterText.toUpperCase())) {
                friendsListModel.append(frnd);
            }
        }
    }

    function openProfilePage(user_id) {
        var component = Qt.createComponent("../ProfilePage.qml");

        if (component.status === Component.Ready) {
            if (user_id === "") {
                var my_profile_page = mainStackView.push(component);

                my_profile_page.userId            = VKHelper.userId;
                my_profile_page.editable          = false;
                my_profile_page.online            = false;
                my_profile_page.dataAvailable     = false;
                my_profile_page.locationAvailable = false;
                my_profile_page.firstName         = VKHelper.firstName;
                my_profile_page.lastName          = VKHelper.lastName;
                my_profile_page.bigPhotoUrl       = VKHelper.bigPhotoUrl;
                my_profile_page.screenName        = "id%1".arg(VKHelper.userId);
                my_profile_page.status            = "";
                my_profile_page.batteryStatus     = "";
                my_profile_page.encryptionKey     = "";
            } else {
                for (var i = 0; i < friendsListModel.count; i++) {
                    var frnd = friendsListModel.get(i);

                    if (user_id === frnd.userId) {
                        var profile_page = mainStackView.push(component);

                        profile_page.userId            = frnd.userId;
                        profile_page.editable          = true;
                        profile_page.online            = frnd.online;
                        profile_page.dataAvailable     = frnd.dataAvailable;
                        profile_page.locationAvailable = frnd.locationAvailable;
                        profile_page.batteryLevel      = frnd.batteryLevel;
                        profile_page.latitude          = frnd.latitude;
                        profile_page.longitude         = frnd.longitude;
                        profile_page.updateTime        = frnd.updateTime;
                        profile_page.firstName         = frnd.firstName;
                        profile_page.lastName          = frnd.lastName;
                        profile_page.bigPhotoUrl       = frnd.bigPhotoUrl;
                        profile_page.screenName        = frnd.screenName;
                        profile_page.status            = frnd.status;
                        profile_page.batteryStatus     = frnd.batteryStatus;
                        profile_page.encryptionKey     = CryptoHelper.getFriendEncryptionKey(frnd.userId);

                        profile_page.locationOnMapRequested.connect(friendsSwipe.locationOnMapRequested);

                        break;
                    }
                }
            }
        } else {
            console.error(component.errorString());
        }
    }

    ColumnLayout {
        anchors.fill:      parent
        anchors.topMargin: UtilScript.dp(UIHelper.screenDpi, 4)
        spacing:           UtilScript.dp(UIHelper.screenDpi, 4)

        RowLayout {
            spacing:           UtilScript.dp(UIHelper.screenDpi, 4)
            Layout.leftMargin: UtilScript.dp(UIHelper.screenDpi, 8)
            Layout.fillWidth:  true
            Layout.alignment:  Qt.AlignVCenter

            Rectangle {
                implicitWidth:    filterTextField.implicitHeight
                implicitHeight:   filterTextField.implicitHeight
                color:            "transparent"
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Image {
                    anchors.fill: parent
                    source:       "qrc:/resources/images/main/button_invite.png"
                    fillMode:     Image.PreserveAspectFit

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            UIHelper.sendInvitation(qsTr("I invite you to install the VKGeo Friends on Map app and join the community: https://vkgeo.sourceforge.io/"));
                        }
                    }
                }
            }

            FilterTextField {
                id:               filterTextField
                placeholderText:  qsTr("Quick search")
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                onFilterTextChanged: {
                    friendsSwipe.updateModel();
                }
            }
        }

        Rectangle {
            color:             "transparent"
            Layout.fillWidth:  true
            Layout.fillHeight: true

            RefreshControl {
                anchors.horizontalCenter: parent.horizontalCenter
                y:                        (listViewOriginY - listViewContentY) / 2 - height / 2
                z:                        1
                listViewOriginY:          friendsListView.originY
                listViewContentY:         friendsListView.contentY

                onRefreshRequested: {
                    VKHelper.updateFriends();
                }
            }

            ListView {
                id:           friendsListView
                anchors.fill: parent
                orientation:  ListView.Vertical
                clip:         true

                model: ListModel {
                    id: friendsListModel
                }

                delegate: Rectangle {
                    id:           friendDelegate
                    width:        listView.width
                    height:       UtilScript.dp(UIHelper.screenDpi, 80)
                    color:        "transparent"
                    clip:         true
                    border.width: UtilScript.dp(UIHelper.screenDpi, 1)
                    border.color: UIHelper.darkTheme ? "midnightblue" : "lightsteelblue"

                    readonly property var listView: ListView.view

                    RowLayout {
                        anchors.fill:        parent
                        anchors.leftMargin:  UtilScript.dp(UIHelper.screenDpi, 16)
                        anchors.rightMargin: UtilScript.dp(UIHelper.screenDpi, 16)
                        spacing:             UtilScript.dp(UIHelper.screenDpi, 8)

                        Rectangle {
                            implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 64)
                            implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                            color:            "transparent"
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                            OpacityMask {
                                id:           opacityMask
                                anchors.fill: parent

                                source: Image {
                                    width:    opacityMask.width
                                    height:   opacityMask.height
                                    source:   photoUrl
                                    fillMode: Image.PreserveAspectCrop
                                    visible:  false
                                }

                                maskSource: Image {
                                    width:    opacityMask.width
                                    height:   opacityMask.height
                                    source:   "qrc:/resources/images/main/avatar_mask.png"
                                    fillMode: Image.PreserveAspectFit
                                    visible:  false
                                }
                            }

                            Image {
                                x:        opacityMask.width  / 2 + opacityMask.width  / 2 * Math.sin(angle) - width  / 2
                                y:        opacityMask.height / 2 + opacityMask.height / 2 * Math.cos(angle) - height / 2
                                z:        1
                                width:    UtilScript.dp(UIHelper.screenDpi, 16)
                                height:   UtilScript.dp(UIHelper.screenDpi, 16)
                                source:   "qrc:/resources/images/main/avatar_online_label.png"
                                fillMode: Image.PreserveAspectFit
                                visible:  online

                                readonly property real angle: -Math.PI / 4
                            }

                            MouseArea {
                                anchors.fill: parent
                                z:            2

                                onClicked: {
                                    friendDelegate.listView.openProfilePage(userId);
                                }
                            }
                        }

                        Text {
                            text:                "%1 %2".arg(firstName).arg(lastName)
                            color:               UIHelper.darkTheme ? "white" : "black"
                            font.pixelSize:      UtilScript.dp(UIHelper.screenDpi, 16)
                            font.family:         "Helvetica"
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment:   Text.AlignVCenter
                            wrapMode:            Text.Wrap
                            fontSizeMode:        Text.Fit
                            minimumPixelSize:    UtilScript.dp(UIHelper.screenDpi, 8)
                            textFormat:          Text.PlainText
                            Layout.fillWidth:    true
                            Layout.fillHeight:   true
                        }

                        Rectangle {
                            implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 48)
                            implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 48)
                            color:            "transparent"
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                            Image {
                                anchors.fill: parent
                                source:       imageSource(locationAvailable)
                                fillMode:     Image.PreserveAspectFit
                                visible:      locationAvailable || trusted || tracked

                                function imageSource(location_available) {
                                    if (location_available) {
                                        return "qrc:/resources/images/main/button_show_on_map.png";
                                    } else {
                                        return "qrc:/resources/images/main/button_tracked_friend.png";
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: {
                                        if (locationAvailable) {
                                            friendDelegate.listView.locateOnMap(userId);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOn
                }

                function openProfilePage(user_id) {
                    friendsSwipe.openProfilePage(user_id);
                }

                function locateOnMap(user_id) {
                    friendsSwipe.locationOnMapRequested(user_id);
                }
            }
        }
    }

    Connections {
        target: VKHelper

        onFriendsUpdated: {
            friendsSwipe.friendsList = VKHelper.getFriendsList();

            for (var i = 0; i < friendsSwipe.friendsList.length; i++) {
                var frnd = friendsSwipe.friendsList[i];

                frnd.dataAvailable     = false;
                frnd.updateTime        = 0;
                frnd.locationAvailable = false;
                frnd.latitude          = 0;
                frnd.longitude         = 0;
                frnd.batteryStatus     = "";
                frnd.batteryLevel      = 0;

                friendsSwipe.friendsList[i] = frnd;
            }

            friendsSwipe.updateModel();
        }

        onTrackedFriendDataUpdated: {
            for (var i = 0; i < friendsSwipe.friendsList.length; i++) {
                var frnd = friendsSwipe.friendsList[i];

                if (friendUserId === frnd.userId) {
                    if (typeof friendData.update_time === "number" && isFinite(friendData.update_time)) {
                        frnd.dataAvailable = true;
                        frnd.updateTime    = friendData.update_time;

                        if (typeof friendData.latitude  === "number" && isFinite(friendData.latitude) &&
                            typeof friendData.longitude === "number" && isFinite(friendData.longitude)) {
                            frnd.locationAvailable = true;
                            frnd.latitude          = friendData.latitude;
                            frnd.longitude         = friendData.longitude;
                        }

                        if (typeof friendData.battery_status === "string" &&
                            typeof friendData.battery_level  === "number" && isFinite(friendData.battery_level)) {
                            frnd.batteryStatus = friendData.battery_status;
                            frnd.batteryLevel  = friendData.battery_level;
                        }
                    }

                    friendsSwipe.friendsList[i] = frnd;

                    break;
                }
            }

            for (var j = 0; j < friendsListModel.count; j++) {
                var model_frnd = friendsListModel.get(j);

                if (friendUserId === model_frnd.userId) {
                    if (typeof friendData.update_time === "number" && isFinite(friendData.update_time)) {
                        friendsListModel.set(j, {"dataAvailable" : true,
                                                 "updateTime"    : friendData.update_time});

                        if (typeof friendData.latitude  === "number" && isFinite(friendData.latitude) &&
                            typeof friendData.longitude === "number" && isFinite(friendData.longitude)) {
                            friendsListModel.set(j, {"locationAvailable" : true,
                                                     "latitude"          : friendData.latitude,
                                                     "longitude"         : friendData.longitude});
                        }

                        if (typeof friendData.battery_status === "string" &&
                            typeof friendData.battery_level  === "number" && isFinite(friendData.battery_level)) {
                            friendsListModel.set(j, {"batteryStatus" : friendData.battery_status,
                                                     "batteryLevel"  : friendData.battery_level});
                        }
                    }

                    break;
                }
            }
        }
    }
}
