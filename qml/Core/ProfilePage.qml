import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import "Misc"

import "../Util.js" as UtilScript

Page {
    id: profilePage

    header: PageHeader {
        bannerViewHeight:  profilePage.bannerViewHeight
        text:              qsTr("Profile info")
        doneButtonVisible: false

        onBackClicked: {
            mainStackView.pop();
        }
    }

    background: Rectangle {
        color: UIHelper.darkTheme ? "black" : "white"
    }

    readonly property int bannerViewHeight: AdMobHelper.bannerViewHeight

    property bool online:                   false
    property bool dataAvailable:            false
    property bool locationAvailable:        false

    property int batteryLevel:              0

    property real latitude:                 0.0
    property real longitude:                0.0

    property double updateTime:             0.0

    property string userId:                 ""
    property string firstName:              ""
    property string lastName:               ""
    property string bigPhotoUrl:            ""
    property string screenName:             ""
    property string status:                 ""
    property string batteryStatus:          ""

    signal locationOnMapRequested(string userId)

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            mainStackView.pop();

            event.accepted = true;
        }
    }

    Flickable {
        id:                   profileFlickable
        anchors.fill:         parent
        anchors.topMargin:    UtilScript.dp(UIHelper.screenDpi, 16)
        anchors.bottomMargin: UtilScript.dp(UIHelper.screenDpi, 16)
        contentWidth:         profileLayout.width
        contentHeight:        profileLayout.height
        clip:                 true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        ColumnLayout {
            id:      profileLayout
            width:   profileFlickable.width
            spacing: UtilScript.dp(UIHelper.screenDpi, 16)

            Rectangle {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 128)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 128)
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
                    width:    UtilScript.dp(UIHelper.screenDpi, 16)
                    height:   UtilScript.dp(UIHelper.screenDpi, 16)
                    source:   "qrc:/resources/images/main/avatar_online_label.png"
                    fillMode: Image.PreserveAspectFit
                    visible:  profilePage.online

                    readonly property real angle: -Math.PI / 4
                }

                Image {
                    x:        opacityMask.width  / 2 + opacityMask.width  / 2 * Math.sin(angle) - width  / 2
                    y:        opacityMask.height / 2 + opacityMask.height / 2 * Math.cos(angle) - height / 2
                    z:        1
                    width:    UtilScript.dp(UIHelper.screenDpi, 16)
                    height:   UtilScript.dp(UIHelper.screenDpi, 24)
                    source:   imageSource(profilePage.batteryStatus, profilePage.batteryLevel)
                    fillMode: Image.PreserveAspectFit
                    visible:  imageVisible(profilePage.batteryStatus)

                    readonly property real angle: Math.PI / 4

                    function imageSource(battery_status, battery_level) {
                        if (battery_level < 25) {
                            if (battery_status === "CHARGING") {
                                return "qrc:/resources/images/profile/avatar_battery_25_charging_label.png";
                            } else {
                                return "qrc:/resources/images/profile/avatar_battery_25_label.png";
                            }
                        } else if (battery_level < 50) {
                            if (battery_status === "CHARGING") {
                                return "qrc:/resources/images/profile/avatar_battery_50_charging_label.png";
                            } else {
                                return "qrc:/resources/images/profile/avatar_battery_50_label.png";
                            }
                        } else if (battery_level < 75) {
                            if (battery_status === "CHARGING") {
                                return "qrc:/resources/images/profile/avatar_battery_75_charging_label.png";
                            } else {
                                return "qrc:/resources/images/profile/avatar_battery_75_label.png";
                            }
                        } else {
                            if (battery_status === "CHARGING") {
                                return "qrc:/resources/images/profile/avatar_battery_100_charging_label.png";
                            } else {
                                return "qrc:/resources/images/profile/avatar_battery_100_label.png";
                            }
                        }
                    }

                    function imageVisible(battery_status) {
                        return (battery_status === "CHARGING" || battery_status === "DISCHARGING");
                    }
                }
            }

            Text {
                leftPadding:         UtilScript.dp(UIHelper.screenDpi, 16)
                rightPadding:        UtilScript.dp(UIHelper.screenDpi, 16)
                text:                "%1 %2".arg(profilePage.firstName).arg(profilePage.lastName)
                color:               UIHelper.darkTheme ? "white" : "black"
                font.pointSize:      24
                font.family:         "Helvetica"
                font.bold:           true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPointSize:    8
                textFormat:          Text.PlainText
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter
            }

            Text {
                leftPadding:         UtilScript.dp(UIHelper.screenDpi, 16)
                rightPadding:        UtilScript.dp(UIHelper.screenDpi, 16)
                text:                profilePage.status
                color:               UIHelper.darkTheme ? "white" : "black"
                font.pointSize:      16
                font.family:         "Helvetica"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPointSize:    8
                textFormat:          Text.PlainText
                visible:             profilePage.status !== ""
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter
            }

            Text {
                leftPadding:         UtilScript.dp(UIHelper.screenDpi, 16)
                rightPadding:        UtilScript.dp(UIHelper.screenDpi, 16)
                text:                qsTr("Last update at: %1").arg((new Date(profilePage.updateTime * 1000))
                                                                         .toLocaleString())
                color:               UIHelper.darkTheme ? "white" : "black"
                font.pointSize:      16
                font.family:         "Helvetica"
                font.italic:         true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPointSize:    8
                visible:             profilePage.dataAvailable
                Layout.fillWidth:    true
                Layout.alignment:    Qt.AlignVCenter
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Locate on map")
                visible:          profilePage.locationAvailable
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    profilePage.locationOnMapRequested(profilePage.userId);

                    mainStackView.pop();
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Get directions")
                visible:          profilePage.locationAvailable
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    Qt.openUrlExternally("https://www.google.com/maps/dir/?api=1&destination=%1"
                                         .arg(encodeURIComponent("%1,%2".arg(profilePage.latitude)
                                                                        .arg(profilePage.longitude))));
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
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
