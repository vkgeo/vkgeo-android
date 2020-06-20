import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import "Misc"

import "../Util.js" as UtilScript

Page {
    id: trustedFriendsPage

    header: PageHeader {
        text: qsTr("Trusted friends")

        onBackClicked: {
            mainStackView.pop();
        }

        onDoneClicked: {
            var trusted_friends_list = [];

            for (var i = 0; i < trustedFriendsPage.friendsList.length; i++) {
                var frnd = trustedFriendsPage.friendsList[i];

                if (frnd.trusted) {
                    trusted_friends_list.push(frnd.userId);
                }
            }

            VKHelper.updateTrustedFriendsList(trusted_friends_list);

            mainStackView.pop();
        }
    }

    background: Rectangle {
        color: UIHelper.darkTheme ? "black" : "white"
    }

    property int trustedFriendsCount: 0

    property var friendsList:         []

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            mainStackView.pop();

            event.accepted = true;
        }
    }

    function updateModel() {
        trustedFriendsListModel.clear();

        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            if ("%1 %2".arg(frnd.firstName).arg(frnd.lastName).toUpperCase()
                       .includes(filterTextField.filterText.toUpperCase())) {
                trustedFriendsListModel.append(frnd);
            }
        }
    }

    function setTrust(user_id, trusted) {
        if (trustedFriendsCount < VKHelper.maxTrustedFriendsCount || !trusted) {
            for (var i = 0; i < friendsList.length; i++) {
                var frnd = friendsList[i];

                if (user_id === frnd.userId) {
                    frnd.trusted = trusted;

                    friendsList[i] = frnd;

                    break;
                }
            }

            for (var j = 0; j < trustedFriendsListModel.count; j++) {
                var model_frnd = trustedFriendsListModel.get(j);

                if (user_id === model_frnd.userId) {
                    trustedFriendsListModel.set(j, {"trusted": trusted});

                    break;
                }
            }

            if (trusted) {
                trustedFriendsCount++;
            } else {
                trustedFriendsCount--;
            }

            return true;
        } else {
            return false;
        }
    }

    ColumnLayout {
        anchors.fill:      parent
        anchors.topMargin: UtilScript.dp(UIHelper.screenDpi, 4)
        spacing:           UtilScript.dp(UIHelper.screenDpi, 4)

        FilterTextField {
            id:               filterTextField
            placeholderText:  qsTr("Quick search")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            onFilterTextChanged: {
                trustedFriendsPage.updateModel();
            }
        }

        ListView {
            orientation:       ListView.Vertical
            clip:              true
            Layout.fillWidth:  true
            Layout.fillHeight: true

            model: ListModel {
                id: trustedFriendsListModel
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

                    OpacityMask {
                        id:               opacityMask
                        implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 64)
                        implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

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

                    Switch {
                        checked:          trusted
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                        onToggled: {
                            if (!friendDelegate.listView.setTrust(userId, checked)) {
                                checked = !checked;
                            }
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
            }

            function setTrust(user_id, trusted) {
                return trustedFriendsPage.setTrust(user_id, trusted);
            }
        }
    }

    Component.onCompleted: {
        friendsList = VKHelper.getFriendsList();

        for (var i = 0; i < friendsList.length; i++) {
            var frnd = friendsList[i];

            if (frnd.trusted) {
                trustedFriendsCount++;
            }
        }

        updateModel();
    }
}
