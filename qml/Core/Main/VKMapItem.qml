import QtQuick 2.9
import QtGraphicalEffects 1.0
import QtPositioning 5.8
import QtLocation 5.9

import "../../Util.js" as UtilScript

MapQuickItem {
    id:          vkMapItem
    width:       sourceItem.width
    height:      sourceItem.height
    anchorPoint: Qt.point(width / 2, height / 2)
    visible:     false

    property bool dataObsolete: false

    property int dataTimeout:   12 * 60 * 60

    property real updateTime:   0.0

    property string userId:     ""
    property string photoUrl:   ""

    signal openProfilePage(string user_id)

    sourceItem: Rectangle {
        width:  UtilScript.pt(48)
        height: UtilScript.pt(48)
        color:  "transparent"

        OpacityMask {
            id:           opacityMask
            anchors.fill: parent

            source: Image {
                width:    opacityMask.width
                height:   opacityMask.height
                source:   vkMapItem.photoUrl
                fillMode: Image.PreserveAspectCrop
                visible:  false
            }

            maskSource: Image {
                width:    opacityMask.width
                height:   opacityMask.height
                source:   "qrc:/resources/images/main/avatar_mask.png"
                fillMode: Image.PreserveAspectFit
                visible:  false
            }
        }

        Image {
            x:        opacityMask.width  / 2 + opacityMask.width  / 2 * Math.sin(angle) - width  / 2
            y:        opacityMask.height / 2 + opacityMask.height / 2 * Math.cos(angle) - height / 2
            z:        1
            width:    UtilScript.pt(16)
            height:   UtilScript.pt(16)
            source:   "qrc:/resources/images/main/avatar_obsolete_data_label.png"
            fillMode: Image.PreserveAspectFit
            visible:  vkMapItem.dataObsolete

            property real angle: Math.PI / 4
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                vkMapItem.openProfilePage(vkMapItem.userId);
            }
        }
    }

    onCoordinateChanged: {
        visible = true;
    }

    onUpdateTimeChanged: {
        updateState();
    }

    function updateState() {
        if ((new Date()).getTime() / 1000 > updateTime + dataTimeout) {
            dataObsolete = true;
        } else {
            dataObsolete = false;
        }
    }

    Component.onCompleted: {
        updateState();
    }
}
