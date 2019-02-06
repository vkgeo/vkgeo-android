import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "../../Util.js" as UtilScript

Pane {
    id: filterTextField

    background: Rectangle {
        color:        "white"
        radius:       UtilScript.pt(8)
        border.width: UtilScript.pt(1)
        border.color: "steelblue"
    }

    property string text:            textField.text
    property string placeholderText: ""

    RowLayout {
        anchors.fill: parent
        spacing:      UtilScript.pt(2)

        TextField {
            id:               textField
            placeholderText:  filterTextField.placeholderText
            inputMethodHints: Qt.ImhNoPredictiveText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            background: Rectangle {
                color: "transparent"
            }

            onEditingFinished: {
                focus = false;
            }
        }

        Image {
            sourceSize.width:  Math.min(textField.implicitWidth, textField.implicitHeight)
            sourceSize.height: Math.min(textField.implicitWidth, textField.implicitHeight)
            source:            "qrc:/resources/images/misc/button_clear.png"
            fillMode:          Image.PreserveAspectFit
            visible:           textField.text !== ""
            Layout.alignment:  Qt.AlignHCenter | Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    textField.clear();
                }
            }
        }
    }
}
