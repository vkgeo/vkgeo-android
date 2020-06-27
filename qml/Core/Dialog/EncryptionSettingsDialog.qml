import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "../Misc"

import "../../Util.js" as UtilScript

Popup {
    id:               encryptionSettingsDialog
    anchors.centerIn: Overlay.overlay
    padding:          UtilScript.dp(UIHelper.screenDpi, 8)
    modal:            true
    closePolicy:      Popup.NoAutoClose

    property bool encryptionEnabled: false

    signal toggleEncryptionSelected()
    signal regenerateSharedKeySelected()
    signal resetKeystoreSelected()
    signal cancelled()

    background: Rectangle {
        color:        UIHelper.darkTheme ? "black" : "white"
        radius:       UtilScript.dp(UIHelper.screenDpi, 8)
        border.width: UtilScript.dp(UIHelper.screenDpi, 2)
        border.color: "steelblue"
    }

    contentItem: Rectangle {
        implicitWidth:  UtilScript.dp(UIHelper.screenDpi, 300)
        implicitHeight: UtilScript.dp(UIHelper.screenDpi, 300)
        color:          "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing:      UtilScript.dp(UIHelper.screenDpi, 8)

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             encryptionSettingsDialog.encryptionEnabled ? qsTr("Disable encryption") : qsTr("Enable encryption")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    encryptionSettingsDialog.toggleEncryptionSelected();
                    encryptionSettingsDialog.close();
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Regenerate the shared key")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    encryptionSettingsDialog.regenerateSharedKeySelected();
                    encryptionSettingsDialog.close();
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Reset the keystore")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    encryptionSettingsDialog.resetKeystoreSelected();
                    encryptionSettingsDialog.close();
                }
            }

            VKButton {
                implicitWidth:    UtilScript.dp(UIHelper.screenDpi, 280)
                implicitHeight:   UtilScript.dp(UIHelper.screenDpi, 64)
                text:             qsTr("Cancel")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                onClicked: {
                    encryptionSettingsDialog.cancelled();
                    encryptionSettingsDialog.close();
                }
            }
        }
    }
}
