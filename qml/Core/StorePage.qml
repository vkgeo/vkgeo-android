import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import "Misc"

import "../Util.js" as UtilScript

Page {
    id: storePage

    header: Rectangle {
        height: Math.max(storePage.safeAreaTopMargin, storePage.bannerViewHeight) +
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
                text:                qsTr("Store")
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
        height: storePage.safeAreaBottomMargin
        color:  "lightsteelblue"
    }

    property int safeAreaTopMargin:    0
    property int safeAreaBottomMargin: 0
    property int bannerViewHeight:     AdMobHelper.bannerViewHeight

    StackView.onStatusChanged: {
        if (StackView.status === StackView.Activating ||
            StackView.status === StackView.Active) {
            safeAreaTopMargin    = UIHelper.safeAreaTopMargin();
            safeAreaBottomMargin = UIHelper.safeAreaBottomMargin();
        }
    }

    Flickable {
        id:                   storeFlickable
        anchors.fill:         parent
        anchors.topMargin:    UtilScript.pt(16)
        anchors.bottomMargin: UtilScript.pt(16)
        contentWidth:         storeLayout.width
        contentHeight:        storeLayout.height
        clip:                 true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        ColumnLayout {
            id:      storeLayout
            width:   storeFlickable.width
            spacing: UtilScript.pt(16)

            Rectangle {
                height:             UtilScript.pt(64)
                color:              "lightsteelblue"
                radius:             UtilScript.pt(8)
                visible:            !mainWindow.enableTrackedFriends
                Layout.leftMargin:  UtilScript.pt(16)
                Layout.rightMargin: UtilScript.pt(16)
                Layout.fillWidth:   true
                Layout.alignment:   Qt.AlignVCenter

                RowLayout {
                    anchors.fill:    parent
                    anchors.margins: UtilScript.pt(16)
                    spacing:         UtilScript.pt(4)

                    Text {
                        text:                qsTr("Tracked friends")
                        color:               "white"
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

                    VKButton {
                        width:            UtilScript.pt(80)
                        height:           UtilScript.pt(32)
                        text:             store.getPrice(trackedFriendsProduct.status,
                                                         trackedFriendsProduct.price)
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                        onClicked: {
                            trackedFriendsProduct.purchase();
                        }
                    }
                }
            }

            Rectangle {
                height:             UtilScript.pt(64)
                color:              "lightsteelblue"
                radius:             UtilScript.pt(8)
                visible:            !mainWindow.increaseTrackingLimits
                Layout.leftMargin:  UtilScript.pt(16)
                Layout.rightMargin: UtilScript.pt(16)
                Layout.fillWidth:   true
                Layout.alignment:   Qt.AlignVCenter

                RowLayout {
                    anchors.fill:    parent
                    anchors.margins: UtilScript.pt(16)
                    spacing:         UtilScript.pt(4)

                    Text {
                        text:                qsTr("Tracking limits x 3")
                        color:               "white"
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

                    VKButton {
                        width:            UtilScript.pt(80)
                        height:           UtilScript.pt(32)
                        text:             store.getPrice(increasedLimitsProduct.status,
                                                         increasedLimitsProduct.price)
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                        onClicked: {
                            increasedLimitsProduct.purchase();
                        }
                    }
                }
            }

            Rectangle {
                height:             UtilScript.pt(64)
                color:              "lightsteelblue"
                radius:             UtilScript.pt(8)
                Layout.leftMargin:  UtilScript.pt(16)
                Layout.rightMargin: UtilScript.pt(16)
                Layout.fillWidth:   true
                Layout.alignment:   Qt.AlignVCenter

                RowLayout {
                    anchors.fill:    parent
                    anchors.margins: UtilScript.pt(16)
                    spacing:         UtilScript.pt(4)

                    Text {
                        text:                qsTr("Restore purchases")
                        color:               "white"
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

                    VKButton {
                        width:            UtilScript.pt(80)
                        height:           UtilScript.pt(32)
                        text:             qsTr("OK")
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                        onClicked: {
                            store.restorePurchases();
                        }
                    }
                }
            }
        }
    }
}
