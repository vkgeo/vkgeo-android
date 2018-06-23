import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import "Misc"

import "../Util.js" as UtilScript

Page {
    id: profilePage

    header: Rectangle {
        height: Math.max(profilePage.safeAreaTopMargin, profilePage.bannerViewHeight) +
                headerControlsLayout.height
        color:  "lightsteelblue"

        RowLayout {
            id:                  headerControlsLayout
            anchors.bottom:      parent.bottom
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.leftMargin:  UtilScript.pt(8)
            anchors.rightMargin: UtilScript.pt(8)
            height:              UtilScript.pt(48)
            spacing:             UtilScript.pt(4)

            Rectangle {
                width:             UtilScript.pt(80)
                color:             "transparent"
                Layout.fillHeight: true
                Layout.alignment:  Qt.AlignHCenter
            }

            Text {
                text:                qsTr("Profile info")
                color:               "white"
                font.pointSize:      16
                font.family:         "Helvetica"
                font.bold:           true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPointSize:    8
                Layout.fillWidth:    true
                Layout.fillHeight:   true
            }

            VKButton {
                width:            UtilScript.pt(80)
                height:           UtilScript.pt(32)
                text:             qsTr("Close")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    mainStackView.pop();
                }
            }
        }
    }

    footer: Rectangle {
        height: profilePage.safeAreaBottomMargin
        color:  "lightsteelblue"
    }

    property bool online:              false
    property bool locationAvailable:   false

    property int safeAreaTopMargin:    0
    property int safeAreaBottomMargin: 0
    property int bannerViewHeight:     AdMobHelper.bannerViewHeight

    property real updateTime:          0.0

    property string userId:            ""
    property string firstName:         ""
    property string lastName:          ""
    property string bigPhotoUrl:       ""
    property string screenName:        ""
    property string status:            ""

    StackView.onStatusChanged: {
        if (StackView.status === StackView.Activating ||
            StackView.status === StackView.Active) {
            safeAreaTopMargin    = UIHelper.safeAreaTopMargin();
            safeAreaBottomMargin = UIHelper.safeAreaBottomMargin();
        }
    }

    signal locateOnMap(string user_id)

    Flickable {
        id:                   profileFlickable
        anchors.fill:         parent
        anchors.topMargin:    UtilScript.pt(16)
        anchors.bottomMargin: UtilScript.pt(16)
        contentWidth:         profileLayout.width
        contentHeight:        profileLayout.height
        clip:                 true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        ColumnLayout {
            id:      profileLayout
            width:   profileFlickable.width
            spacing: UtilScript.pt(16)

            Rectangle {
                width:            UtilScript.pt(128)
                height:           UtilScript.pt(128)
                color:            "transparent"
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                OpacityMask {
                    id:           opacityMask
                    anchors.fill: parent

                    source: Image {
                        width:    opacityMask.width
                        height:   opacityMask.height
                        source:   profilePage.bigPhotoUrl
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
                    visible:  profilePage.online

                    property real angle: Math.PI / 4
                }
            }

            Text {
                leftPadding:         UtilScript.pt(16)
                rightPadding:        UtilScript.pt(16)
                text:                "%1 %2".arg(profilePage.firstName).arg(profilePage.lastName)
                color:               "black"
                font.pointSize:      24
                font.family:         "Helvetica"
                font.bold:           true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPointSize:    8
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter
            }

            Text {
                leftPadding:         UtilScript.pt(16)
                rightPadding:        UtilScript.pt(16)
                text:                profilePage.status
                color:               "black"
                font.pointSize:      16
                font.family:         "Helvetica"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPointSize:    8
                visible:             profilePage.status !== ""
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter
            }

            Text {
                leftPadding:         UtilScript.pt(16)
                rightPadding:        UtilScript.pt(16)
                text:                qsTr("Location updated at: %1").arg((new Date(profilePage.updateTime * 1000))
                                                                              .toLocaleString())
                color:               "black"
                font.pointSize:      16
                font.family:         "Helvetica"
                font.italic:         true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPointSize:    8
                visible:             profilePage.locationAvailable
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter
            }

            VKButton {
                width:            UtilScript.pt(280)
                height:           UtilScript.pt(64)
                text:             qsTr("Locate on map")
                visible:          profilePage.locationAvailable
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    locateOnMap(profilePage.userId);

                    mainStackView.pop();
                }
            }

            VKButton {
                width:            UtilScript.pt(280)
                height:           UtilScript.pt(64)
                text:             qsTr("Open profile")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    if (!Qt.openUrlExternally("vk://vk.com/%1".arg(profilePage.screenName))) {
                        Qt.openUrlExternally("https://m.vk.com/%1".arg(profilePage.screenName));
                    }
                }
            }
        }
    }
}
