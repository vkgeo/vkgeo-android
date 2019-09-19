import QtQuick 2.12

import "../../Util.js" as UtilScript

Image {
    id:       refreshControl
    width:    UtilScript.pt(UIHelper.screenDpi, 32)
    height:   UtilScript.pt(UIHelper.screenDpi, 32)
    source:   "qrc:/resources/images/misc/refresh.png"
    fillMode: Image.PreserveAspectFit
    rotation: controlRotation(height, listViewOriginY, listViewContentY, shiftDenominator, refreshAnimation.running)
    opacity:  controlOpacity(height, listViewOriginY, listViewContentY, shiftDenominator)
    visible:  listViewContentY < listViewOriginY

    readonly property int refreshTimeout: 500

    property real listViewOriginY:        0.0
    property real listViewContentY:       0.0
    property real shiftDenominator:       2.0

    signal refreshRequested()

    onOpacityChanged: {
        if (opacity >= 1.0) {
            if (!refreshAnimation.running) {
                refreshTimer.start();
            }
        } else {
            refreshTimer.stop();
        }
    }

    onVisibleChanged: {
        if (!visible) {
            refreshAnimation.stop();
        }
    }

    function controlRotation(height, list_view_origin_y, list_view_content_y, shift_denominator, animation_running) {
        if (animation_running) {
            return rotation;
        } else if (height > 0 && list_view_content_y < list_view_origin_y && shift_denominator > 0) {
            return 360 * ((list_view_origin_y - list_view_content_y) / height) / shift_denominator;
        } else {
            return 0;
        }
    }

    function controlOpacity(height, list_view_origin_y, list_view_content_y, shift_denominator) {
        if (height > 0 && list_view_content_y < list_view_origin_y && shift_denominator > 0) {
            return Math.min(1.0, 1.0 * ((list_view_origin_y - list_view_content_y) / height) / shift_denominator);
        } else {
            return 0.0;
        }
    }

    NumberAnimation {
        id:       refreshAnimation
        target:   refreshControl
        property: "rotation"
        from:     0
        to:       360
        duration: 500
        loops:    Animation.Infinite
    }

    Timer {
        id:       refreshTimer
        interval: refreshControl.refreshTimeout

        onTriggered: {
            refreshAnimation.start();

            refreshControl.refreshRequested();
        }
    }
}
