import QtQuick 2.12

Rectangle {
    id:    vkDoneButton
    color: "transparent"

    signal clicked()

    Image {
        anchors.fill: parent
        source:       "qrc:/resources/images/misc/button_done.png"
        fillMode:     Image.PreserveAspectFit

        MouseArea {
            anchors.fill: parent

            onClicked: {
                vkDoneButton.clicked();
            }
        }
    }
}
