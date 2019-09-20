import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "../../Util.js" as UtilScript

ColumnLayout {
    id:      pageHeader
    spacing: 0

    property bool backButtonVisible: true
    property bool doneButtonVisible: true

    property int bannerViewHeight:   0

    property string text:            ""

    signal backClicked()
    signal doneClicked()

    Rectangle {
        implicitHeight:   pageHeader.bannerViewHeight
        color:            UIHelper.darkTheme ? "midnightblue" : "lightsteelblue"
        visible:          pageHeader.bannerViewHeight > 0
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 48)
        color:            "steelblue"
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            anchors.fill:        parent
            anchors.leftMargin:  UtilScript.dp(UIHelper.screenDpi, 8)
            anchors.rightMargin: UtilScript.dp(UIHelper.screenDpi, 8)
            spacing:             UtilScript.dp(UIHelper.screenDpi, 4)

            VKBackButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 32)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 32)
                visible:          pageHeader.backButtonVisible
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    pageHeader.backClicked();
                }
            }

            Rectangle {
                implicitWidth:     UtilScript.dp(UIHelper.screenDpi, 32)
                color:             "transparent"
                visible:           !pageHeader.backButtonVisible
                Layout.fillHeight: true
                Layout.alignment:  Qt.AlignHCenter
            }

            Text {
                text:                pageHeader.text
                color:               "white"
                font.pixelSize:      UtilScript.dp(UIHelper.screenDpi, 16)
                font.family:         "Helvetica"
                font.bold:           true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                wrapMode:            Text.Wrap
                fontSizeMode:        Text.Fit
                minimumPixelSize:    UtilScript.dp(UIHelper.screenDpi, 8)
                Layout.fillWidth:    true
                Layout.fillHeight:   true
            }

            VKDoneButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 32)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 32)
                visible:          pageHeader.doneButtonVisible
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    pageHeader.doneClicked();
                }
            }

            Rectangle {
                implicitWidth:     UtilScript.dp(UIHelper.screenDpi, 32)
                color:             "transparent"
                visible:           !pageHeader.doneButtonVisible
                Layout.fillHeight: true
                Layout.alignment:  Qt.AlignHCenter
            }
        }
    }
}
