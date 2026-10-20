import QtQuick
import "../../../services"
import "../../common/functions/FlipMath.js" as FM
import "../../../modules/tansu/phone"

Item {
    id: root

    property string screenName: ""
    property string clockText: "00:00AM"
    property string dateText: "Sun, 20  Sep"
    property bool active: false
    property string initialTarget: "desktop"

    property real faceWidth: 1440
    property real faceHeight: 760
    property real cornerRadius: 92
    property real thickness: 135

    readonly property real yaw: 0
    readonly property real pitch: 0
    readonly property real roll: 0
    property real perspective: 6000

    property real popFrom: 0.55
    property real tiltYaw: -22
    property real tiltPitch: 14
    property real tiltRoll: 7

    property real fit: 1
    property real centerX: 0
    property real centerY: 0
    property real pixelRatio: 1

    property real flip: 1
    property real quickFit: 1
    property real quickYaw: 33
    property real quickPitch: 18
    property real dipDepth: 0.12

    property real pop: 1
    property real alpha: 1
    property real tilt: 0
    property real wob: 0

    property bool moving: false
    property bool turning: false

    readonly property alias phone: phone
    readonly property var face: faceLoader.item

    readonly property real shownOpacity: alpha * FM.settingsAlpha(flip)
    readonly property real turnSize: FM.quickScale(flip, quickFit, fit, dipDepth)
                                     / (FM.SIZE_RATIO * Math.max(0.0001, fit))

    signal closeRequested()

    function focusKeys() {
        if (root.face)
            root.face.forceActiveFocus()
    }

    function setTarget(which) {
        if (root.face)
            root.face.target = which === "lock" ? "lock" : "desktop"
    }

    readonly property bool settled: flip >= 1 && pop >= 1 && tilt === 0 && wob === 0 && !turning
    readonly property real gridPx: Math.max(1, pixelRatio)
    readonly property real sceneX: centerX - phone.screenCenterX * fit - (phone.layerSwing.left + 8) * fit
    readonly property real sceneY: centerY - phone.screenCenterY * fit - (phone.layerSwing.top + 8) * fit

    readonly property bool direct: settled && !moving && pop === 1
    readonly property real faceLeftDev: centerX * pixelRatio - phone.directW / 2
    readonly property real faceTopDev: centerY * pixelRatio - phone.directH / 2

    readonly property real snapX: direct ? (Math.round(faceLeftDev) - faceLeftDev) / pixelRatio
                                         : (settled ? Math.round(sceneX * gridPx) / gridPx - sceneX : 0)
    readonly property real snapY: direct ? (Math.round(faceTopDev) - faceTopDev) / pixelRatio
                                         : (settled ? Math.round(sceneY * gridPx) / gridPx - sceneY : 0)

    Item {
        id: pivot

        x: root.centerX + root.snapX
        y: root.centerY + root.snapY
        scale: (root.popFrom + (1 - root.popFrom) * root.pop) * root.turnSize
        opacity: root.shownOpacity
        visible: opacity > 0.001

        PhoneBody {
            id: phone

            landscape: true
            faceWidth: root.faceWidth
            faceHeight: root.faceHeight
            cornerRadius: root.cornerRadius
            thickness: root.thickness
            perspective: root.perspective
            yaw: root.yaw
            pitch: root.pitch
            roll: root.roll

            windowShown: root.active

            x: -phone.screenCenterX * root.fit
            y: -phone.screenCenterY * root.fit
            transformOrigin: Item.TopLeft
            scale: root.fit

            moving: root.moving
            turnRoll: root.turning ? 90 : 0
            flat: root.settled
            faceDirect: root.direct

            rollOffset: root.tilt * root.tiltRoll + FM.settingsRoll(root.flip) + root.wob
            pitchOffset: root.tilt * root.tiltPitch + (root.quickPitch - root.pitch) * (1 - root.flip) + root.wob * 0.5
            yawOffset: root.tilt * root.tiltYaw + (root.quickYaw - root.yaw) * (1 - root.flip)

            swingRoll: root.tiltRoll
            swingPitch: root.tiltPitch
            swingYaw: root.tiltYaw

            renderScale: root.fit * root.pixelRatio

            Loader {
                id: faceLoader

                width: root.faceWidth
                height: root.faceHeight
                active: root.active
                asynchronous: true

                onLoaded: root.setTarget(root.initialTarget)

                sourceComponent: Component {
                    WallpaperFace {
                        screenName: root.screenName
                        clockText: root.clockText
                        dateText: root.dateText
                        screenInset: phone.screenInset
                        cornerRadius: root.cornerRadius
                        renderScale: phone.renderScale

                        onCloseRequested: root.closeRequested()
                    }
                }
            }
        }
    }
}
