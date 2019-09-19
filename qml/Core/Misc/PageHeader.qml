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
        implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 48)
        color:            "steelblue"
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            anchors.fill:        parent
            anchors.leftMargin:  UtilScript.pt(UIHelper.screenDpi, 8)
            anchors.rightMargin: UtilScript.pt(UIHelper.screenDpi, 8)
            spacing:             UtilScript.pt(UIHelper.screenDpi, 4)

            VKBackButton {
                implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 32)
                implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 32)
                visible:          pageHeader.backButtonVisible
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    pageHeader.backClicked();
                }
            }

            Rectangle {
                implicitWidth:     UtilScript.pt(UIHelper.screenDpi, 32)
                color:             "transparent"
                visible:           !pageHeader.backButtonVisible
                Layout.fillHeight: true
                Layout.alignment:  Qt.AlignHCenter
            }

            Text {
                text:                pageHeader.text
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

            VKDoneButton {
                implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 32)
                implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 32)
                visible:          pageHeader.doneButtonVisible
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    pageHeader.doneClicked();
                }
            }

            Rectangle {
                implicitWidth:     UtilScript.pt(UIHelper.screenDpi, 32)
                color:             "transparent"
                visible:           !pageHeader.doneButtonVisible
                Layout.fillHeight: true
                Layout.alignment:  Qt.AlignHCenter
            }
        }
    }
}
