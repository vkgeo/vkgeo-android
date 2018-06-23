import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import QtPositioning 5.8
import QtGraphicalEffects 1.0

import "../Misc"

import "../../Util.js" as UtilScript

Item {
    id: friendsSwipe

    property int nearbyDistance: 500
    property var friendsList:    []

    signal locateFriendOnMap(string user_id)

    function updateFriends() {
        friendsList = VKHelper.getFriendsList();

        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            frnd.invited           = false;
            frnd.nearby            = false;
            frnd.locationAvailable = false;
            frnd.updateTime        = 0;
            frnd.latitude          = 0;
            frnd.longitude         = 0;

            friendsList[i] = frnd;
        }

        updateModel();
    }

    function updateModel() {
        friendsListModel.clear();

        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            if ("%1 %2".arg(frnd.firstName).arg(frnd.lastName).toUpperCase()
                       .includes(filterTextField.text.toUpperCase())) {
                friendsListModel.append(frnd);
            }
        }
    }

    function trackedFriendLocationAvailable(user_id, update_time, latitude, longitude) {
        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            if (user_id === frnd.userId) {
                frnd.locationAvailable = true;
                frnd.updateTime        = update_time;
                frnd.latitude          = latitude;
                frnd.longitude         = longitude;

                if (VKHelper.locationValid) {
                    var my_coordinate = QtPositioning.coordinate(VKHelper.locationLatitude, VKHelper.locationLongitude);

                    if (my_coordinate.distanceTo(QtPositioning.coordinate(frnd.latitude, frnd.longitude)) < nearbyDistance) {
                        if (!frnd.nearby) {
                            frnd.nearby = true;

                            NotificationHelper.showNotification("FRIENDS_NEARBY", qsTr("New friends nearby"),
                                                                                  qsTr("%1 is nearby")
                                                                                      .arg("%1 %2".arg(frnd.firstName)
                                                                                                  .arg(frnd.lastName)));
                        }
                    } else {
                        frnd.nearby = false;
                    }
                }

                friendsList[i] = frnd;

                break;
            }
        }

        for (var j = 0; j < friendsListModel.count; j++) {
            var model_frnd = friendsListModel.get(j);

            if (user_id === model_frnd.userId) {
                friendsListModel.set(j, { "locationAvailable" : true,
                                          "updateTime"        : update_time,
                                          "latitude"          : latitude,
                                          "longitude"         : longitude });

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
                my_profile_page.locationAvailable = false;
                my_profile_page.firstName         = VKHelper.firstName;
                my_profile_page.lastName          = VKHelper.lastName;
                my_profile_page.bigPhotoUrl       = VKHelper.bigPhotoUrl;
                my_profile_page.screenName        = "id%1".arg(VKHelper.userId);
                my_profile_page.status            = "";
            } else {
                for (var i = 0; i < friendsListModel.count; i++) {
                    var frnd = friendsListModel.get(i);

                    if (user_id === frnd.userId) {
                        var profile_page = mainStackView.push(component);

                        profile_page.userId            = frnd.userId;
                        profile_page.online            = frnd.online;
                        profile_page.locationAvailable = frnd.locationAvailable;
                        profile_page.updateTime        = frnd.updateTime;
                        profile_page.firstName         = frnd.firstName;
                        profile_page.lastName          = frnd.lastName;
                        profile_page.bigPhotoUrl       = frnd.bigPhotoUrl;
                        profile_page.screenName        = frnd.screenName;
                        profile_page.status            = frnd.status;

                        profile_page.locateOnMap.connect(friendsSwipe.locateFriendOnMap);

                        break;
                    }
                }
            }
        } else {
            console.log(component.errorString());
        }
    }

    function inviteFriend(user_id) {
        VKHelper.sendMessage(user_id, qsTr("I invite you to install the VKGeo app and join the community: %1")
                                          .arg("https://itunes.apple.com/app/id1381218973"));

        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            if (user_id === frnd.userId) {
                frnd.invited = true;

                friendsList[i] = frnd;

                break;
            }
        }

        for (var j = 0; j < friendsListModel.count; j++) {
            var model_frnd = friendsListModel.get(j);

            if (user_id === model_frnd.userId) {
                friendsListModel.set(j, { "invited" : true });

                break;
            }
        }

        invitationToast.visible = true;
    }

    Toast {
        id:              invitationToast
        anchors.top:     parent.top
        anchors.left:    parent.left
        anchors.right:   parent.right
        anchors.margins: UtilScript.pt(4)
        height:          UtilScript.pt(48)
        z:               1
        text:            qsTr("Invitation sent")
    }

    ColumnLayout {
        anchors.fill:      parent
        anchors.topMargin: UtilScript.pt(4)
        spacing:           UtilScript.pt(4)

        FilterTextField {
            id:               filterTextField
            placeholderText:  qsTr("Quick search")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            onTextChanged: {
                friendsSwipe.updateModel();
            }
        }

        Rectangle {
            color:             "transparent"
            Layout.fillWidth:  true
            Layout.fillHeight: true

            Image {
                id:                       refreshImage
                anchors.top:              parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width:                    UtilScript.pt(64)
                height:                   UtilScript.pt(64)
                z:                        1
                source:                   "qrc:/resources/images/main/refresh.png"
                fillMode:                 Image.PreserveAspectFit
                rotation:                 calculateRotation(height, listViewOriginY, listViewContentY,
                                                            refreshImageAnimation.running)
                visible:                  listViewContentY < listViewOriginY

                property bool timerStarted:     false
                property real listViewOriginY:  friendsListView.originY
                property real listViewContentY: friendsListView.contentY

                onVisibleChanged: {
                    if (!visible) {
                        refreshImageAnimation.stop();
                    }
                }

                onListViewContentYChanged: {
                    if (listViewOriginY - listViewContentY > height) {
                        if (!timerStarted) {
                            timerStarted = true;

                            refreshTimer.start();
                        }
                    } else {
                        timerStarted = false;

                        refreshTimer.stop();
                    }
                }

                function calculateRotation(height, list_view_origin_y, list_view_content_y, animation_running) {
                    if (animation_running) {
                        return rotation;
                    } else if (height > 0 && list_view_content_y < list_view_origin_y) {
                        return 360 * ((list_view_origin_y - list_view_content_y) / height);
                    } else {
                        return 0;
                    }
                }

                PropertyAnimation {
                    id:       refreshImageAnimation
                    target:   refreshImage
                    property: "rotation"
                    from:     0
                    to:       360
                    duration: 500
                    loops:    Animation.Infinite
                }

                Timer {
                    id:       refreshTimer
                    interval: 500

                    onTriggered: {
                        refreshImageAnimation.start();

                        VKHelper.updateFriends();
                    }
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

                                property real angle: Math.PI / 4
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

                        Image {
                            width:            UtilScript.pt(48)
                            height:           UtilScript.pt(48)
                            source:           buttonToShow(locationAvailable, trusted, tracked, invited)
                            fillMode:         Image.PreserveAspectFit
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                            function buttonToShow(location_available, trusted, tracked, invited) {
                                if (location_available) {
                                    return "qrc:/resources/images/main/button_show_on_map.png";
                                } else if (trusted || tracked) {
                                    if (invited) {
                                        return "qrc:/resources/images/main/button_invite_tracked_done.png";
                                    } else {
                                        return "qrc:/resources/images/main/button_invite_tracked.png";
                                    }
                                } else {
                                    if (invited) {
                                        return "qrc:/resources/images/main/button_invite_other_done.png";
                                    } else {
                                        return "qrc:/resources/images/main/button_invite_other.png";
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    if (locationAvailable) {
                                        friendDelegate.listView.locateFriendOnMap(userId);
                                    } else if (!invited) {
                                        friendDelegate.listView.inviteFriend(userId);
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

                function inviteFriend(user_id) {
                    inviteMessageDialog.userId = user_id;

                    inviteMessageDialog.open();
                }
            }
        }
    }

    MessageDialog {
        id:              inviteMessageDialog
        title:           qsTr("Invite friend")
        icon:            StandardIcon.Question
        text:            qsTr("Do you want to send an invitation to this friend?")
        standardButtons: StandardButton.Yes | StandardButton.No

        property string userId: ""

        onYes: {
            friendsSwipe.inviteFriend(userId);
        }
    }

    Component.onCompleted: {
        VKHelper.friendsUpdated.connect(updateFriends);
        VKHelper.trackedFriendLocationUpdated.connect(trackedFriendLocationAvailable);
    }
}
