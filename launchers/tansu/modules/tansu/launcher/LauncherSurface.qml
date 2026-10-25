import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../../services"
import "../../common/functions/PhoneMath.js" as PM
import "../../common/functions/FlipMath.js" as FM
import "../phone"
import "../wallpaperSelector"

// The launcher phone: the shell's home screen and wallpaper switcher,
// as ONE phone that lives in the bottom-left corner of the screen and is the
// same 2.5D body as the bar style's Quick Panel phone (PhoneBody.qml): the same
// size, the same pose, the same pull-out.
//
//   - it rises from below the screen edge with a bounce and a pocket tilt that
//     rings out as it lands
//   - it stays up with its lower part below the screen edge (`peek`, the same
//     "How much of the phone shows" setting as the Quick Panel)
//   - moving the mouse away does NOT close it; click outside it, press the
//     launcher key again, or pick an app. It then drops back out of sight with
//     a little pull up first
//
// Its screens:
//   Home / Apps  LauncherFace.qml: search, your pinned apps, and every
//                installed app A to Z, plus the extras cards.
//   Wallpapers   WallpaperFace.qml: the wheel / grid gallery. The same phone rolls a
//                quarter turn (FlipMath.js, WallpaperStage.qml) into the flat
//                landscape one, still in the corner.
// Wallpapers need the whole screen of the phone, so for them it
// rises the rest of the way (`riseK`) and sits fully on screen in the corner;
// going back to Home lowers it to its peeking spot again.
//
// Ryoku seam: as a launcher variant this surface is hosted by the shell's own
// launcher Scope (Main.qml), not a private controller: the Scope drives
// visibility and the monitor, and the surface asks it to close. It opens on the
// monitor the shell pointed at.
//
// One of the files that talks to the system.
Scope {
    id: root

    required property var host

    property var source: null

    readonly property bool open: root.host.openRequested
    readonly property bool shown: root.host.shown
    readonly property var targetScreen: root.host.hostScreen
    readonly property bool clickOutside: SettingsService.clickOutside

    readonly property string query: face.query

    property real peek: SettingsService.get("panel.peek") / 100

    property real barHeight: 63
    property real edgeMargin: 10
    property real maxScale: 1
    property real headroom: 44
    property real cornerGap: 24

    property real bounce: 34
    property real tiltRoll: 12
    property real tiltPitch: 10
    property real tiltYaw: -6

    // How far (px) the phone sits below its resting spot: 0 at rest, huge while
    // it has never been shown; negative during the overshoot. 1 = turned the way
    // it is in the pocket, 0 = upright.
    property real lift: 100000
    property real tilt: 1
    property real exitPeak: 0
    property real exitPeakMs: 130
    property real exitDrop: 0

    readonly property real riseTarget: root.wallpapersOpen ? 1 : 0
    property real riseK: riseTarget
    Behavior on riseK {
        enabled: win.visible
        NumberAnimation {
            id: riseAnim
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    readonly property bool animating: enterAnim.running || exitAnim.running || exitDelay.running
                                      || riseAnim.running

    property bool wallpapersOpen: false
    property real flip: 0
    property real wob: 0
    property int ringSign: -1
    property int flipMs: 200
    readonly property var flipCurve: [0.30, 0.0, 0.20, 1.0, 1.0, 1.0]
    property real flipDip: 0.12
    property real flipWobble: 2.5
    property int flipRingMs: 380
    readonly property bool flipping: flipPrep.running || flipAnim.running
    property string wallpaperTarget: "desktop"

    function close() {
        root.host.hide()
    }

    function dropDistance() {
        // Only `shownHeight` of the scene shows above the edge: that far down
        // is already out of sight.
        const portrait = win.shownHeight
        const land = root.flip > 0.02 ? win.landFull : 0
        return Math.ceil(Math.max(portrait, land)) + 2
    }

    // Starts this far out of sight, so the window's first frame already shows
    // the phone instead of a sliver at the screen edge.
    readonly property real enterFrom: root.dropDistance() * 0.84

    onOpenChanged: {
        if (open) {
            exitDelay.stop()
            exitAnim.stop()
            root.resetTurn()
            face.reset()
            if (root.lift > root.enterFrom)
                root.lift = root.enterFrom
            enterAnim.restart()
            focusTimer.restart()
        } else {
            enterAnim.stop()
            // A small pull up first, unless it's still on its way up.
            const rising = root.lift > 20
            root.exitPeak = rising ? root.lift : -root.bounce * 0.7
            root.exitPeakMs = rising ? 1 : 130
            root.exitDrop = root.dropDistance()
            if (phone.crisp)
                exitDelay.restart()
            else
                exitAnim.restart()
        }
    }

    ParallelAnimation {
        id: enterAnim

        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "lift"
                to: -root.bounce
                duration: 280
                easing.type: Easing.OutQuart
            }
            // The settle never goes below the resting spot (it would drag the
            // phone's lower part under the screen edge for a moment), so the
            // bounce stays upward only.
            NumberAnimation {
                target: root
                property: "lift"
                to: 0
                duration: 170
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: root
                property: "lift"
                to: -root.bounce * 0.14
                duration: 110
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "lift"
                to: 0
                duration: 110
                easing.type: Easing.InQuad
            }
        }

        NumberAnimation {
            target: root
            property: "tilt"
            to: 0
            duration: 820
            easing.type: Easing.OutElastic
            easing.amplitude: 1
            easing.period: 0.4
        }
    }

    Timer {
        id: exitDelay
        interval: 40
        onTriggered: {
            if (!root.open)
                exitAnim.restart()
        }
    }

    ParallelAnimation {
        id: exitAnim

        onFinished: {
            root.host.closing = false
            root.lift = 100000
            root.tilt = 1
            root.resetTurn()
        }

        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "lift"
                to: root.exitPeak
                duration: root.exitPeakMs
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "lift"
                to: root.exitDrop
                duration: 340
                easing.type: Easing.InCubic
            }
        }

        NumberAnimation {
            target: root
            property: "tilt"
            to: 1
            duration: 440
            easing.type: Easing.InQuad
        }
    }

    function resetTurn() {
        flipPrep.stop()
        flipAnim.stop()
        ring.stop()
        root.wob = 0
        root.flip = 0
        root.wallpapersOpen = false
    }

    function turnTo(p) {
        ring.stop()
        root.wob = 0
        flipAnim.stop()
        flipAnim.to = p
        flipPrep.restart()
    }

    function openWallpapers() {
        if (!root.open || root.wallpapersOpen)
            return
        root.wallpapersOpen = true
        root.turnTo(1)
    }

    function leaveWallpapers() {
        if (!root.wallpapersOpen)
            return
        root.wallpapersOpen = false
        root.turnTo(0)
    }


    Timer {
        id: flipPrep
        interval: 40
        onTriggered: {
            root.ringSign = flipAnim.to > 0.5 ? -1 : 1
            flipAnim.restart()
            ring.restart()
        }
    }

    NumberAnimation {
        id: flipAnim
        target: root
        property: "flip"
        to: 1
        duration: root.flipMs
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.flipCurve
        onFinished: turnFocus.restart()
    }

    Timer {
        id: turnFocus
        interval: 70
        onTriggered: root.giveKeys()
    }

    SequentialAnimation {
        id: ring

        PauseAnimation {
            duration: Math.round(root.flipMs * 0.62)
        }

        NumberAnimation {
            target: root
            property: "wob"
            to: root.ringSign * root.flipWobble
            duration: root.flipRingMs * 0.42
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: root
            property: "wob"
            to: -root.ringSign * root.flipWobble * 0.1
            duration: root.flipRingMs * 0.38
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: root
            property: "wob"
            to: 0
            duration: root.flipRingMs * 0.2
            easing.type: Easing.InOutSine
        }
    }

    Timer {
        id: focusTimer
        interval: 140
        onTriggered: root.giveKeys()
    }

    function giveKeys() {
        if (!root.open)
            return
        if (root.wallpapersOpen)
            wallStage.focusKeys()
        else
            face.focusSearch()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: win.visible
    }

    Connections {
        target: WallpaperService

        function onFolderPickingChanged() {
            if (WallpaperService.folderPicking && root.wallpapersOpen)
                root.close()
        }
    }

    HyprlandFocusGrab {
        id: grab
        windows: [win]
        onCleared: {
            if (!root.clickOutside) {
                grab.active = false
                grabDelay.restart()
                return
            }
            root.close()
        }
    }

    readonly property bool grabWanted: open && win.visible

    onGrabWantedChanged: {
        if (grabWanted) {
            grabDelay.restart()
        } else {
            grabDelay.stop()
            grab.active = false
        }
    }

    Timer {
        id: grabDelay
        interval: 80
        onTriggered: grab.active = root.grabWanted
    }

    // A full-screen layer surface under the phone: compositors without the
    // focus-grab protocol (niri) get click-outside from it instead.
    PanelWindow {
        id: dismissWin

        property bool wanted: root.open && root.clickOutside
        property bool mapped: false

        screen: root.targetScreen
        visible: mapped
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "tansu-launcher-dismiss"
        WlrLayershell.layer: WlrLayer.Top
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onWantedChanged: Qt.callLater(function () {
            dismissWin.mapped = dismissWin.wanted;
        })

        MouseArea {
            anchors.fill: parent
            onPressed: Qt.callLater(root.close)
        }
    }

    // ===== the window =====
    // Sits on the bottom-left corner of the screen and is only as big as the
    // phone needs for everything it does in the corner (the peek, the full rise,
    // the turn into the landscape Wallpapers, the pull-out's overshoot). Its size
    // is worked out once, up front, because a window that is resized while it
    // animates stutters. Only the phone itself takes the mouse (`mask`).
    PanelWindow {
        id: win

        screen: root.targetScreen
        visible: root.shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "tansu-launcher"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors {
            left: true
            bottom: true
        }

        // The window reaches `bleed` px past the bottom of the screen, so the
        // compositor's own open animation lifting the surface a few px can never
        // show a gap under the phone (see QuickPanel.qml for the long story).
        readonly property real bleed: Math.max(24, Math.ceil(shownHeight * 0.04))
        margins.bottom: -Math.ceil(bleed)

        mask: Region {
            item: hitRect
        }

        readonly property real uiScale: ShellScale.forScreen(root.targetScreen)
        readonly property real pixelRatio: root.targetScreen ? root.targetScreen.devicePixelRatio : 1
        readonly property real monitorW: root.targetScreen ? root.targetScreen.width : 1920
        readonly property real monitorH: root.targetScreen ? root.targetScreen.height : 1080

        readonly property real gapPx: Math.round(root.cornerGap * uiScale)
        readonly property real edgeMarginPx: root.edgeMargin * uiScale

        // As big as the Quick Panel's phone: shrunk to fit the screen's height
        // (never past maxScale), times the monitor's scale, but never so big that
        // the whole phone would not fit under the top of the screen.
        readonly property real fit: {
            const room = monitorH - root.barHeight - 4 - root.edgeMargin - root.headroom
            const natural = Math.max(0.3, Math.min(root.maxScale, room / phone.implicitHeight))
            const tall = phone.swing.top + phone.implicitHeight
            const cap = (monitorH - (root.barHeight + root.headroom) * uiScale) / Math.max(1, tall)
            return Math.max(0.3, Math.min(natural * uiScale, Math.max(natural, cap)))
        }

        // The Wallpapers phone's size: the same as the phone's own (so a pill is
        // the same size on screen everywhere), never wider than the monitor.
        readonly property real lfit: {
            const lw = Math.max(1, wallStage.phone.implicitWidth)
            return Math.max(0.3, Math.min(fit, (monitorW - 2 * gapPx - 8) / lw))
        }

        readonly property real pscale: FM.quickScale(root.flip, fit, lfit, root.flipDip)

        readonly property real shownHeight: phone.implicitHeight * fit * Math.min(1, Math.max(0.2, root.peek))
        readonly property real fullBody: phone.implicitHeight * fit + edgeMarginPx
        readonly property real riseNeeded: Math.max(0, fullBody - shownHeight)
        readonly property real px0: gapPx + (phone.swing.left + phone.screenCenterX) * fit
        readonly property real pu0: shownHeight - phone.screenCenterY * fit

        readonly property real landFull: wallStage.phone.implicitHeight * lfit + edgeMarginPx
        readonly property real px1: gapPx + (wallStage.phone.swing.left + wallStage.phone.screenCenterX) * lfit
        readonly property real pu1: landFull - wallStage.phone.screenCenterY * lfit

        readonly property var turnRoom: {
            const sp = wallStage.phone
            const qcx = phone.screenCenterX, qcy = phone.screenCenterY
            const scx = sp.screenCenterX, scy = sp.screenCenterY
            const uStart = pu0 + riseNeeded
            let needU = 0, needX = 0
            for (let i = -4; i <= 24; i++) {
                const p = i / 20
                const A = FM.quickScale(p, fit, lfit, root.flipDip)
                const As = A / FM.SIZE_RATIO
                const x = px0 + (px1 - px0) * p
                const u = uStart + (pu1 - uStart) * p
                const yw = phone.yaw + (wallStage.yaw - phone.yaw) * p
                const pt = phone.pitch + (wallStage.pitch - phone.pitch) * p
                const bq = PM.boundsFor(phone.faceWidth, phone.faceHeight, phone.thickness, phone.cornerRadius,
                                        yw, pt, phone.roll + FM.quickRoll(p), phone.perspective, phone.pose)
                const bs = PM.boundsFor(sp.faceWidth, sp.faceHeight, sp.thickness, sp.cornerRadius,
                                        yw, pt, sp.roll + FM.settingsRoll(p), sp.perspective, sp.pose)
                needU = Math.max(needU, u + (qcy - bq.minY) * A, u + (scy - bs.minY) * As)
                needX = Math.max(needX, x + (bq.maxX - qcx) * A, x + (bs.maxX - scx) * As)
            }
            return { u: needU, x: needX }
        }

        readonly property real topU: Math.min(monitorH, Math.ceil(Math.max(
            fullBody + phone.swing.top * fit,
            landFull + wallStage.phone.swing.top * lfit,
            turnRoom.u) + root.headroom * uiScale))
        readonly property real winW: Math.min(monitorW, Math.ceil(Math.max(
            px0 + (phone.implicitWidth + phone.swing.right - phone.screenCenterX) * fit,
            px1 + (wallStage.phone.implicitWidth + wallStage.phone.swing.right
                   - wallStage.phone.screenCenterX) * lfit,
            turnRoom.x) + 4))

        implicitWidth: winW
        implicitHeight: topU + Math.ceil(bleed)

        readonly property real riseUp: riseNeeded * root.riseK
        readonly property real portraitU: pu0 + riseUp
        readonly property real pivotU: portraitU + (pu1 - portraitU) * root.flip
        readonly property real pivotXRaw: px0 + (px1 - px0) * root.flip
        readonly property real pivotYRaw: topU - pivotU + root.lift

        function faceCutoffAt(x) {
            const m = PM.baseFor(phone.faceWidth, phone.faceHeight, phone.thickness,
                                 phone.yaw, phone.pitch, phone.roll,
                                 phone.perspective, phone.pose)
            const Y = shownHeight / fit
            const den = Y * m[13] - m[5]
            if (Math.abs(den) < 1e-9)
                return phone.faceHeight
            return Math.min(phone.faceHeight, (m[4] * x + m[7] - Y * (m[12] * x + m[15])) / den)
        }
        readonly property real faceVisibleBottom: Math.min(faceCutoffAt(0), faceCutoffAt(phone.faceWidth))

        readonly property bool settled: root.open && root.lift === 0 && root.tilt === 0 && !root.animating
                                        && root.flip === 0 && !root.flipping && !root.wallpapersOpen
        readonly property real gridPx: Math.max(1, pixelRatio)
        readonly property real sceneX: pivotXRaw - phone.screenCenterX * fit - (phone.layerSwing.left + 8) * fit
        readonly property real sceneY: pivotYRaw - phone.screenCenterY * fit - (phone.layerSwing.top + 8) * fit

        readonly property real snapX: settled ? Math.round(sceneX * gridPx) / gridPx - sceneX : 0
        readonly property real snapY: settled ? Math.round(sceneY * gridPx) / gridPx - sceneY : 0

        Item {
            id: hitRect

            readonly property bool land: root.wallpapersOpen || root.flip > 0.02
            readonly property real w: land ? wallStage.phone.implicitWidth * win.lfit
                                           : phone.implicitWidth * win.fit
            readonly property real topY: land ? (win.topU - win.landFull)
                                             : win.topU - win.shownHeight - win.riseUp

            x: land ? (win.px1 - wallStage.phone.screenCenterX * win.lfit)
                    : win.px0 - phone.screenCenterX * win.fit
            y: topY
            width: root.open ? w : 0
            height: root.open ? Math.max(0, win.topU + Math.ceil(win.bleed) - topY) : 0
        }

        Item {
            id: pivot

            x: win.pivotXRaw + win.snapX
            y: win.pivotYRaw + win.snapY

            PhoneBody {
                id: phone

                x: -phone.screenCenterX * win.pscale
                y: -phone.screenCenterY * win.pscale
                transformOrigin: Item.TopLeft
                scale: win.pscale

                opacity: FM.quickAlpha(root.flip)
                visible: opacity > 0.001
                enabled: root.flip === 0 && !root.flipping

                windowShown: win.visible

                moving: root.animating || !win.visible || root.flipping
                turnRoll: root.flipping ? -90 : 0

                rollOffset: root.tilt * root.tiltRoll + FM.quickRoll(root.flip) + root.wob
                pitchOffset: root.tilt * root.tiltPitch + (wallStage.pitch - phone.pitch) * root.flip + root.wob * 0.5
                yawOffset: root.tilt * root.tiltYaw + (wallStage.yaw - phone.yaw) * root.flip
                swingRoll: root.tiltRoll
                swingPitch: root.tiltPitch
                swingYaw: root.tiltYaw

                renderScale: win.fit * win.pixelRatio

                LauncherFace {
                    id: face

                    source: root.source
                    renderScale: phone.renderScale
                    screenName: root.targetScreen ? root.targetScreen.name : ""
                    visibleBottom: win.faceVisibleBottom
                    clockText: Qt.formatDateTime(clock.date, SettingsService.flag("time.use24h") ? "HH:mm" : "hh:mmAP")
                    dateText: Qt.formatDate(clock.date, "ddd, d  MMM")

                    onAppActivated: app => {
                        root.close()
                        root.source.launch(app)
                    }
                    onCloseRequested: root.close()
                    onWallpapersRequested: root.openWallpapers()
                    onDoneRequested: root.close()
                    onPickerRequested: root.close()
                    onJumpRequested: n => {
                        if (n === 3)
                            root.openWallpapers()
                    }
                }
            }
        }

        WallpaperStage {
            id: wallStage

            active: win.visible
            fit: win.lfit
            centerX: win.pivotXRaw
            centerY: win.pivotYRaw
            pixelRatio: win.pixelRatio

            flip: root.flip
            quickFit: win.fit
            dipDepth: root.flipDip
            wob: root.wob

            pop: 1
            alpha: 1
            tilt: root.tilt
            tiltYaw: root.tiltYaw
            tiltPitch: root.tiltPitch
            tiltRoll: root.tiltRoll

            moving: root.animating || root.flipping || !win.visible
            turning: root.flipping

            initialTarget: root.wallpaperTarget
            screenName: root.targetScreen ? root.targetScreen.name : ""
            clockText: Qt.formatDateTime(clock.date, SettingsService.flag("time.use24h") ? "HH:mm" : "hh:mmAP")
            dateText: Qt.formatDate(clock.date, "ddd, d  MMM")

            onCloseRequested: root.leaveWallpapers()
        }
    }
}
