import QtQuick 2.12

Rectangle {
    id:    vkBackButton
    color: "transparent"

    signal clicked()

    Image {
        anchors.fill: parent
        source:       "qrc:/resources/images/misc/button_back.png"
        fillMode:     Image.PreserveAspectFit

        MouseArea {
            anchors.fill: parent

            onClicked: {
                vkBackButton.clicked();
            }
        }
    }
}
