import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "../Misc"

import "../../Util.js" as UtilScript

Popup {
    id:               themeSelectionDialog
    anchors.centerIn: Overlay.overlay
    modal:            true
    closePolicy:      Popup.NoAutoClose

    signal autoThemeSelected()
    signal lightThemeSelected()
    signal darkThemeSelected()
    signal cancelled()

    contentItem: Rectangle {
        implicitWidth:  UtilScript.pt(300)
        implicitHeight: UtilScript.pt(300)
        color:          UIHelper.darkTheme ? "black" : "white"

        ColumnLayout {
            anchors.fill:         parent
            anchors.topMargin:    UtilScript.pt(8)
            anchors.bottomMargin: UtilScript.pt(8)
            spacing:              UtilScript.pt(8)

            VKButton {
                width:            UtilScript.pt(280)
                height:           UtilScript.pt(64)
                text:             qsTr("Auto")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    themeSelectionDialog.autoThemeSelected();
                    themeSelectionDialog.close();
                }
            }

            VKButton {
                width:            UtilScript.pt(280)
                height:           UtilScript.pt(64)
                text:             qsTr("Light theme")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    themeSelectionDialog.lightThemeSelected();
                    themeSelectionDialog.close();
                }
            }

            VKButton {
                width:            UtilScript.pt(280)
                height:           UtilScript.pt(64)
                text:             qsTr("Dark theme")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    themeSelectionDialog.darkThemeSelected();
                    themeSelectionDialog.close();
                }
            }

            VKButton {
                width:            UtilScript.pt(280)
                height:           UtilScript.pt(64)
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
