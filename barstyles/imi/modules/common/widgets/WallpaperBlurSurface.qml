import QtQuick
import Qt5Compat.GraphicalEffects
import ".."

Item {
    id: root

    property string wallpaperSource: ""
    property bool liveWallpaperActive: false
    property Item weSurfaceItem: null
    property real cornerRadius: Appearance.rounding?.verylarge ?? 30
    property int blurRadius: 48

    property real wallpaperWidth: 0
    property real wallpaperHeight: 0
    property real surfaceX: 0
    property real surfaceY: 0

    readonly property string wallpaperUrl: root.wallpaperSource
        ? "file://" + root.wallpaperSource.split('/').map(s => encodeURIComponent(s)).join('/')
        : ""

    readonly property int sampleStatus: wallpaperImage.status

    property Item maskItem: null

    readonly property Rectangle _mask: Rectangle {
        width: root.width
        height: root.height
        radius: root.cornerRadius
    }

    Image {
        id: wallpaperImage
        width: root.wallpaperWidth
        height: root.wallpaperHeight
        source: root.liveWallpaperActive ? "" : root.wallpaperUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }

    ShaderEffectSource {
        id: wallpaperSample
        anchors.fill: parent
        visible: false
        live: true
        hideSource: false
        sourceItem: root.liveWallpaperActive ? root.weSurfaceItem : wallpaperImage
        sourceRect: Qt.rect(root.surfaceX, root.surfaceY,
            Math.max(1, root.width), Math.max(1, root.height))
    }

    FastBlur {
        anchors.fill: parent
        source: wallpaperSample
        radius: root.blurRadius
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: root.maskItem ?? root._mask
        }
    }
}
