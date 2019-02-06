import QtQuick 2.12

import "../../Util.js" as UtilScript

Rectangle {
    id:      toast
    color:   "lightsteelblue"
    radius:  UtilScript.pt(8)
    visible: false

    property string text: ""

    onVisibleChanged: {
        if (visible) {
            toastAnimation.start();
        }
    }

    Text {
        anchors.fill:        parent
        anchors.margins:     UtilScript.pt(2)
        text:                toast.text
        color:               "white"
        font.pointSize:      16
        font.family:         "Helvetica"
        font.bold:           true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter
        wrapMode:            Text.Wrap
        fontSizeMode:        Text.Fit
        minimumPointSize:    8
    }

    MouseArea {
        anchors.fill: parent
    }

    SequentialAnimation {
        id: toastAnimation

        NumberAnimation {
            target:   toast
            property: "opacity"
            from:     0.0
            to:       1.0
            duration: 250
        }

        PauseAnimation {
            duration: 1000
        }

        NumberAnimation {
            target:   toast
            property: "opacity"
            from:     1.0
            to:       0.0
            duration: 250
        }

        ScriptAction {
            script: {
                toast.visible = false;
            }
        }
    }
}
