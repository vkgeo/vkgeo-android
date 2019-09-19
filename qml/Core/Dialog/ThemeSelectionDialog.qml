import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "../Misc"

import "../../Util.js" as UtilScript

Popup {
    id:               themeSelectionDialog
    anchors.centerIn: Overlay.overlay
    padding:          UtilScript.pt(UIHelper.screenDpi, 8)
    modal:            true
    closePolicy:      Popup.NoAutoClose

    signal autoThemeSelected()
    signal lightThemeSelected()
    signal darkThemeSelected()
    signal cancelled()

    background: Rectangle {
        color:        UIHelper.darkTheme ? "black" : "white"
        radius:       UtilScript.pt(UIHelper.screenDpi, 8)
        border.width: UtilScript.pt(UIHelper.screenDpi, 2)
        border.color: "steelblue"
    }

    contentItem: Rectangle {
        implicitWidth:  UtilScript.pt(UIHelper.screenDpi, 300)
        implicitHeight: UtilScript.pt(UIHelper.screenDpi, 300)
        color:          "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing:      UtilScript.pt(UIHelper.screenDpi, 8)

            VKButton {
                implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 64)
                text:             qsTr("Auto")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    themeSelectionDialog.autoThemeSelected();
                    themeSelectionDialog.close();
                }
            }

            VKButton {
                implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 64)
                text:             qsTr("Light theme")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    themeSelectionDialog.lightThemeSelected();
                    themeSelectionDialog.close();
                }
            }

            VKButton {
                implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 64)
                text:             qsTr("Dark theme")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    themeSelectionDialog.darkThemeSelected();
                    themeSelectionDialog.close();
                }
            }

            VKButton {
                implicitWidth:    UtilScript.pt(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.pt(UIHelper.screenDpi, 64)
                text:             qsTr("Cancel")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    themeSelectionDialog.cancelled();
                    themeSelectionDialog.close();
                }
            }
        }
    }
}
