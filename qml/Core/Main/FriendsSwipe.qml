import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

import "../Misc"

import "../../Util.js" as UtilScript

Item {
    id: friendsSwipe

    property var friendsList: []

    signal locateFriendOnMap(string user_id)

    function updateFriends() {
        friendsList = VKHelper.getFriendsList();

        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            frnd.dataAvailable     = false;
            frnd.updateTime        = 0;
            frnd.locationAvailable = false;
            frnd.latitude          = 0;
            frnd.longitude         = 0;
            frnd.batteryStatus     = "";
            frnd.batteryLevel      = 0;

            friendsList[i] = frnd;
        }

        updateModel();
    }

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

    function trackedFriendDataAvailable(user_id, data) {
        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            if (user_id === frnd.userId) {
                if (typeof data.update_time === "number" && isFinite(data.update_time)) {
                    frnd.dataAvailable = true;
                    frnd.updateTime    = data.update_time;

                    if (typeof data.latitude  === "number" && isFinite(data.latitude) &&
                        typeof data.longitude === "number" && isFinite(data.longitude)) {
                        frnd.locationAvailable = true;
                        frnd.latitude          = data.latitude;
                        frnd.longitude         = data.longitude;
                    }

                    if (typeof data.battery_status === "string" &&
                        typeof data.battery_level  === "number" && isFinite(data.battery_level)) {
                        frnd.batteryStatus = data.battery_status;
                        frnd.batteryLevel  = data.battery_level;
                    }
                }

                friendsList[i] = frnd;

                break;
            }
        }

        for (var j = 0; j < friendsListModel.count; j++) {
            var model_frnd = friendsListModel.get(j);

            if (user_id === model_frnd.userId) {
                if (typeof data.update_time === "number" && isFinite(data.update_time)) {
                    friendsListModel.set(j, {"dataAvailable" : true,
                                             "updateTime"    : data.update_time});

                    if (typeof data.latitude  === "number" && isFinite(data.latitude) &&
                        typeof data.longitude === "number" && isFinite(data.longitude)) {
                        friendsListModel.set(j, {"locationAvailable" : true,
                                                 "latitude"          : data.latitude,
                                                 "longitude"         : data.longitude});
                    }

                    if (typeof data.battery_status === "string" &&
                        typeof data.battery_level  === "number" && isFinite(data.battery_level)) {
                        friendsListModel.set(j, {"batteryStatus" : data.battery_status,
                                                 "batteryLevel"  : data.battery_level});
                    }
                }

                break;
            }
        }
    }

    function openProfilePage(user_id) {
        var component = Qt.createComponent("../ProfilePage.qml");

        if (component.status === Component.Ready) {
            if (user_id === "") {
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
                for (var i = 0; i < friendsListModel.count; i++) {
                    var frnd = friendsListModel.get(i);

                    if (user_id === frnd.userId) {
                        var profile_page = mainStackView.push(component);

                        profile_page.userId            = frnd.userId;
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

                        profile_page.locateOnMap.connect(friendsSwipe.locateFriendOnMap);

                        break;
                    }
                }
            }
        } else {
            console.log(component.errorString());
        }
    }

    ColumnLayout {
        anchors.fill:      parent
        anchors.topMargin: UtilScript.pt(4)
        spacing:           UtilScript.pt(4)

        RowLayout {
            spacing:           UtilScript.pt(4)
            Layout.leftMargin: UtilScript.pt(8)
            Layout.fillWidth:  true
            Layout.alignment:  Qt.AlignVCenter

            Rectangle {
                width:            filterTextField.implicitHeight
                height:           filterTextField.implicitHeight
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

                onRefresh: {
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
                    height:       UtilScript.pt(80)
                    color:        "white"
                    clip:         true
                    border.width: UtilScript.pt(1)
                    border.color: "lightsteelblue"

                    property var listView: ListView.view

                    RowLayout {
                        anchors.fill:        parent
                        anchors.leftMargin:  UtilScript.pt(16)
                        anchors.rightMargin: UtilScript.pt(16)
                        spacing:             UtilScript.pt(8)

                        Rectangle {
                            width:            UtilScript.pt(64)
                            height:           UtilScript.pt(64)
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
                                width:    UtilScript.pt(16)
                                height:   UtilScript.pt(16)
                                source:   "qrc:/resources/images/main/avatar_online_label.png"
                                fillMode: Image.PreserveAspectFit
                                visible:  online

                                property real angle: -Math.PI / 4
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    friendDelegate.listView.openProfilePage(userId);
                                }
                            }
                        }

                        Text {
                            text:                "%1 %2".arg(firstName).arg(lastName)
                            color:               "black"
                            font.pointSize:      16
                            font.family:         "Helvetica"
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment:   Text.AlignVCenter
                            wrapMode:            Text.Wrap
                            fontSizeMode:        Text.Fit
                            minimumPointSize:    8
                            Layout.fillWidth:    true
                            Layout.fillHeight:   true
                        }

                        Rectangle {
                            width:            UtilScript.pt(48)
                            height:           UtilScript.pt(48)
                            color:            "transparent"
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                            Image {
                                anchors.fill: parent
                                source:       buttonToShow(locationAvailable)
                                fillMode:     Image.PreserveAspectFit
                                visible:      locationAvailable || trusted || tracked

                                function buttonToShow(location_available) {
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
                                            friendDelegate.listView.locateFriendOnMap(userId);
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

                function locateFriendOnMap(user_id) {
                    friendsSwipe.locateFriendOnMap(user_id);
                }
            }
        }
    }

    Component.onCompleted: {
        VKHelper.friendsUpdated.connect(updateFriends);
        VKHelper.trackedFriendDataUpdated.connect(trackedFriendDataAvailable);
    }
}
