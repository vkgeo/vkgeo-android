import QtQuick 2.12
import QtGraphicalEffects 1.0
import QtPositioning 5.12
import QtLocation 5.12

import "../../Util.js" as UtilScript

MapQuickItem {
    id:          vkMapItem
    width:       sourceItem.width
    height:      sourceItem.height
    anchorPoint: Qt.point(width / 2, height / 2)
    visible:     false

    readonly property int dataTimeout: 24 * 60 * 60

    property bool dataObsolete:        false

    property double updateTime:        0.0

    property string userId:            ""
    property string photoUrl:          ""

    signal profilePageRequested(string userId)

    sourceItem: Rectangle {
        width:  UtilScript.dp(UIHelper.screenDpi, 48)
        height: UtilScript.dp(UIHelper.screenDpi, 48)
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
            width:    UtilScript.dp(UIHelper.screenDpi, 16)
            height:   UtilScript.dp(UIHelper.screenDpi, 16)
            source:   "qrc:/resources/images/main/avatar_obsolete_data_label.png"
            fillMode: Image.PreserveAspectFit
            visible:  vkMapItem.dataObsolete

            readonly property real angle: Math.PI / 4
        }

        MouseArea {
            anchors.fill: parent
            z:            2

            onClicked: {
                vkMapItem.profilePageRequested(vkMapItem.userId);
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
        if ((new Date()).getTime() / 1000 - updateTime > dataTimeout) {
            dataObsolete = true;
        } else {
            dataObsolete = false;
        }
    }

    Component.onCompleted: {
        updateState();
    }
}
