import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import VKHelper 1.0

import "Misc"

import "../Util.js" as UtilScript

Page {
    id: loginPage

    background: Rectangle {
        color: UIHelper.darkTheme ? "black" : "white"
    }

    ColumnLayout {
        anchors.fill:         parent
        anchors.topMargin:    UtilScript.pt(16)
        anchors.bottomMargin: UtilScript.pt(16)
        spacing:              UtilScript.pt(32)

        Rectangle {
            color:             "transparent"
            Layout.fillWidth:  true
            Layout.fillHeight: true
        }

        Text {
            leftPadding:          UtilScript.pt(16)
            rightPadding:         UtilScript.pt(16)
            text:                 qsTr("Sign in with your VK account")
            color:                UIHelper.darkTheme ? "white" : "black"
            font.pointSize:       32
            font.family:          "Helvetica"
            font.bold:            true
            horizontalAlignment:  Text.AlignHCenter
            wrapMode:             Text.Wrap
            fontSizeMode:         Text.Fit
            minimumPointSize:     8
            Layout.maximumHeight: parent.height / 2
            Layout.fillWidth:     true
            Layout.alignment:     Qt.AlignVCenter
        }

        Rectangle {
            width:            UtilScript.pt(280)
            height:           UtilScript.pt(140)
            color:            "transparent"
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Image {
                anchors.fill: parent
                source:       "qrc:/resources/images/login/button_login.png"
                fillMode:     Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        VKHelper.login();
                    }
                }
            }
        }

        Rectangle {
            color:             "transparent"
            Layout.fillWidth:  true
            Layout.fillHeight: true
        }

        VKButton {
            width:            UtilScript.pt(280)
            height:           UtilScript.pt(64)
            text:             qsTr("Privacy policy")
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            onClicked: {
                Qt.openUrlExternally(qsTr("https://vkgeo.sourceforge.io/en/privacy.php"));
            }
        }
    }
}
