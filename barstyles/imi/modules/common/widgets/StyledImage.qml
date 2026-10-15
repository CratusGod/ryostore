import QtQuick
import "../../../services"
import ".."
import "."
import "../functions"

Image {
    id: root
    asynchronous: true

    Component.onCompleted: {
        if (typeof root.retainWhileLoading !== "undefined")
            root.retainWhileLoading = true;
    }

    visible: opacity > 0
    opacity: (status === Image.Ready) ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    property list<string> fallbacks: []
    property int currentFallbackIndex: 0

    onStatusChanged: {
        if (status === Image.Error && currentFallbackIndex < fallbacks.length) {
            source = fallbacks[currentFallbackIndex];
            currentFallbackIndex += 1;
        }
    }
}
