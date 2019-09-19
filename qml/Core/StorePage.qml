import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "Misc"

import "../Util.js" as UtilScript

Page {
    id: storePage

    header: PageHeader {
        bannerViewHeight:  storePage.bannerViewHeight
        text:              qsTr("Store")
        doneButtonVisible: false

        onBackClicked: {
            mainStackView.pop();
        }
    }

    background: Rectangle {
        color: UIHelper.darkTheme ? "black" : "white"
    }

    readonly property int bannerViewHeight: AdMobHelper.bannerViewHeight

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            mainStackView.pop();

            event.accepted = true;
        }
    }

    Flickable {
        id:                   storeFlickable
        anchors.fill:         parent
        anchors.topMargin:    UtilScript.pt(UIHelper.screenDpi, 16)
        anchors.bottomMargin: UtilScript.pt(UIHelper.screenDpi, 16)
        contentWidth:         storeLayout.width
        contentHeight:        storeLayout.height
        clip:                 true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        ColumnLayout {
            id:      storeLayout
            width:   storeFlickable.width
            spacing: UtilScript.pt(UIHelper.screenDpi, 16)

            Rectangle {
                implicitHeight:     UtilScript.pt(UIHelper.screenDpi, 64)
                color:              UIHelper.darkTheme ? "midnightblue" : "lightsteelblue"
                radius:             UtilScript.pt(UIHelper.screenDpi, 8)
                visible:            !mainWindow.enableTrackedFriends
                Layout.leftMargin:  UtilScript.pt(UIHelper.screenDpi, 16)
                Layout.rightMargin: UtilScript.pt(UIHelper.screenDpi, 16)
                Layout.fillWidth:   true
                Layout.alignment:   Qt.AlignVCenter

                RowLayout {
                    anchors.fill:    parent
                    anchors.margins: UtilScript.pt(UIHelper.screenDpi, 16)
                    spacing:         UtilScript.pt(UIHelper.screenDpi, 4)

                    Text {
                        text:                qsTr("Tracked friends")
                        color:               UIHelper.darkTheme ? "white" : "black"
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
                        implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 80)
                        implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 32)
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
                implicitHeight:     UtilScript.pt(UIHelper.screenDpi, 64)
                color:              UIHelper.darkTheme ? "midnightblue" : "lightsteelblue"
                radius:             UtilScript.pt(UIHelper.screenDpi, 8)
                visible:            !mainWindow.increaseTrackingLimits
                Layout.leftMargin:  UtilScript.pt(UIHelper.screenDpi, 16)
                Layout.rightMargin: UtilScript.pt(UIHelper.screenDpi, 16)
                Layout.fillWidth:   true
                Layout.alignment:   Qt.AlignVCenter

                RowLayout {
                    anchors.fill:    parent
                    anchors.margins: UtilScript.pt(UIHelper.screenDpi, 16)
                    spacing:         UtilScript.pt(UIHelper.screenDpi, 4)

                    Text {
                        text:                qsTr("Tracking limits x 3")
                        color:               UIHelper.darkTheme ? "white" : "black"
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
                        implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 80)
                        implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 32)
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
                implicitHeight:     UtilScript.pt(UIHelper.screenDpi, 64)
                color:              UIHelper.darkTheme ? "midnightblue" : "lightsteelblue"
                radius:             UtilScript.pt(UIHelper.screenDpi, 8)
                Layout.leftMargin:  UtilScript.pt(UIHelper.screenDpi, 16)
                Layout.rightMargin: UtilScript.pt(UIHelper.screenDpi, 16)
                Layout.fillWidth:   true
                Layout.alignment:   Qt.AlignVCenter

                RowLayout {
                    anchors.fill:    parent
                    anchors.margins: UtilScript.pt(UIHelper.screenDpi, 16)
                    spacing:         UtilScript.pt(UIHelper.screenDpi, 4)

                    Text {
                        text:                qsTr("Restore purchases")
                        color:               UIHelper.darkTheme ? "white" : "black"
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
                        implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 80)
                        implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 32)
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
