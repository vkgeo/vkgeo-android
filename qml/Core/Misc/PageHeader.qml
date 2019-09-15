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
        height:           pageHeader.bannerViewHeight
        color:            UIHelper.darkTheme ? "midnightblue" : "lightsteelblue"
        visible:          pageHeader.bannerViewHeight > 0
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        height:           UtilScript.pt(48)
        color:            "steelblue"
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            anchors.fill:        parent
            anchors.leftMargin:  UtilScript.pt(8)
            anchors.rightMargin: UtilScript.pt(8)
            spacing:             UtilScript.pt(4)

            VKBackButton {
                width:            UtilScript.pt(32)
                height:           UtilScript.pt(32)
                visible:          pageHeader.backButtonVisible
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    pageHeader.backClicked();
                }
            }

            Rectangle {
                width:             UtilScript.pt(32)
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
                width:            UtilScript.pt(32)
                height:           UtilScript.pt(32)
                visible:          pageHeader.doneButtonVisible
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    pageHeader.doneClicked();
                }
            }

            Rectangle {
                width:             UtilScript.pt(32)
                color:             "transparent"
                visible:           !pageHeader.doneButtonVisible
                Layout.fillHeight: true
                Layout.alignment:  Qt.AlignHCenter
            }
        }
    }
}
