import QtQuick
import Quickshell.Widgets
import "../../../modules/common"

// The Apps screen's wallpaper, drawn the way you picture an LCD: your wallpaper at
// full brightness, seen through a fine pixel mesh (three thin red / green / blue
// stripes to a pixel, dark lines between them), with a little backlight falloff at
// the edges and one soft reflection across the glass.
//
// It is only a picture: it sits UNDER the Apps screen (LauncherFace.qml puts it at
// z -10) and nothing here takes the mouse. It is the shape of the phone's screen
// (the PhoneBody's glass: `inset` in from the face's edge, corners to match), so it
// never reaches the bezel.
//
// Static on purpose. The Apps screen is drawn into one big layer that is only moved
// while nothing in it changes (see LauncherFace's `reveal` note), and a picture that
// never changes keeps it that way: no flicker, no shimmer, no animation here.
//
// Every layer is plain shapes plus one tiny tiled image (assets/images/lcd-mesh.png,
// 24x24 texels = one LCD pixel). No shader, nothing to compile.
ClippingRectangle {
    id: lcd

    property string path: ""
    property real renderScale: 1
    property bool active: true

    property real pitch: 8
    property real washTop: 0.10
    property real washBody: 0.04
    property real edgeDark: 0.06
    property real edgeSize: 34
    property real glare: 0.16
    property real meshStrength: 1

    readonly property real inset: Theme.phoneScreenInset
    radius: Math.max(0, Theme.phoneCornerRadius - lcd.inset)
    color: "transparent"

    visible: lcd.path !== ""

    Image {
        id: wall

        anchors.fill: parent
        source: lcd.active && lcd.path !== "" ? "file://" + lcd.path : ""
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        smooth: true
        sourceSize.height: Math.min(2400, Math.ceil(lcd.height * lcd.renderScale))
    }

    // ===== which ink reads over the picture =====
    // The same measuring as the Quick screen's banner (QuickPanelFace.qml,
    // `bannerSampler`): a thumbnail one tenth the size of the screen is read for how
    // bright the picture is under the clock + date (top-left) and under the speed
    // readout (top-right). Darker than 0.30 (linear light) and white ink wins, otherwise
    // the navy one. LauncherFace.qml picks the colour from these two. It reads the
    // picture that is already decoded (`wall`), so it costs no second load, and it only
    // paints when the picture changes. Until it has, the ink stays the navy one.
    property bool darkLeft: false
    property bool darkRight: false

    Canvas {
        id: sampler

        width: 62
        height: 118
        opacity: 0
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate

        readonly property url src: wall.status === Image.Ready ? wall.source : ""

        onSrcChanged: {
            if (src.toString() !== "")
                requestPaint()
        }

        function brightness(ctx, x, y, w, h) {
            const d = ctx.getImageData(x, y, w, h).data
            let sum = 0
            let n = 0
            for (let i = 0; i < d.length; i += 4) {
                if (d[i + 3] === 0)
                    continue
                const r = Math.pow(d[i] / 255, 2.2)
                const g = Math.pow(d[i + 1] / 255, 2.2)
                const b = Math.pow(d[i + 2] / 255, 2.2)
                sum += 0.2126 * r + 0.7152 * g + 0.0722 * b
                n++
            }
            return n > 0 ? sum / n : 1
        }

        onPaint: {
            if (src.toString() === "")
                return
            const iw = wall.implicitWidth
            const ih = wall.implicitHeight
            if (iw <= 0 || ih <= 0)
                return

            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            let dw = width
            let dh = width * ih / iw
            if (dh < height) {
                dh = height
                dw = height * iw / ih
            }
            ctx.drawImage(wall, (width - dw) / 2, (height - dh) / 2, dw, dh)

            lcd.darkLeft = brightness(ctx, 5, 2, 12, 5) < 0.30
            lcd.darkRight = brightness(ctx, 42, 2, 15, 5) < 0.30
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.pSurface, lcd.washTop) }
            GradientStop { position: 0.3; color: Qt.alpha(Theme.pSurface, lcd.washBody) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.pSurface, lcd.washBody) }
        }
    }

    readonly property color edgeTint: Qt.rgba(0.24, 0.24, 0.39, lcd.edgeDark)
    readonly property color edgeClear: Qt.rgba(0.24, 0.24, 0.39, 0)

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: lcd.edgeSize
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: lcd.edgeTint }
            GradientStop { position: 1.0; color: lcd.edgeClear }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: lcd.edgeSize
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: lcd.edgeClear }
            GradientStop { position: 1.0; color: lcd.edgeTint }
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: lcd.edgeSize
        gradient: Gradient {
            GradientStop { position: 0.0; color: lcd.edgeTint }
            GradientStop { position: 1.0; color: lcd.edgeClear }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: lcd.edgeSize
        gradient: Gradient {
            GradientStop { position: 0.0; color: lcd.edgeClear }
            GradientStop { position: 1.0; color: lcd.edgeTint }
        }
    }

    Item {
        id: meshScaler

        readonly property real k: lcd.pitch / 24

        width: lcd.width / meshScaler.k
        height: lcd.height / meshScaler.k
        scale: meshScaler.k
        transformOrigin: Item.TopLeft
        opacity: lcd.meshStrength
        visible: lcd.meshStrength > 0.001

        Image {
            anchors.fill: parent
            source: "file://" + Directories.asset("images/lcd-mesh.png")
            fillMode: Image.Tile
            smooth: true
            mipmap: true
        }
    }

    Rectangle {
        visible: lcd.glare > 0.001
        width: lcd.width * 2.2
        height: 190
        x: lcd.width / 2 - width / 2
        y: lcd.height * 0.2 - height / 2
        rotation: -20
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, lcd.glare) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }
}
