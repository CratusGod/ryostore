pragma Singleton
import QtQuick
import shell.services as Ryoku
import "../../services"

// Palette + sizing pulled straight from the Figma file. Workspace
// badge colors live in the real SVG exports now (assets/workspace-
// active-*.svg), not here — everything else that still needs QML
// styling (Active Window, Media, Weather, Clock) reads from this.
//
// Every colour is a Ryoku Material role, so the bar wears exactly the same
// palette as the rest of the shell (and the terminal): surface containers for
// fills, outline for lines, onSurface for ink, primary/secondary/tertiary for
// the accents.
QtObject {
    id: theme

    readonly property var pal: ThemeService.palette

    readonly property bool mono: pal.mono === true

    readonly property color colBorder: Ryoku.Theme.onSurface
    readonly property color colBg: Ryoku.Theme.surface
    readonly property color accentCyan: Ryoku.Theme.primary
    readonly property color accentMint: Ryoku.Theme.tertiary
    readonly property color textWhite: Ryoku.Theme.onSurface

    readonly property string mode: ThemeService.mode
    readonly property bool dark: ThemeService.dark
    readonly property bool darker: ThemeService.darker

    readonly property real wheelStep: 110

    function wheelPx(event, sideways) {
        const pd = event.pixelDelta
        const ad = event.angleDelta
        if (sideways) {
            if (pd.x !== 0 || pd.y !== 0)
                return Math.abs(pd.x) > Math.abs(pd.y) ? pd.x : pd.y
            return (Math.abs(ad.x) > Math.abs(ad.y) ? ad.x : ad.y) / 120 * wheelStep
        }
        return pd.y !== 0 ? pd.y : ad.y / 120 * wheelStep
    }
    readonly property real lightLineAlpha: 0.42
    readonly property real lightShadowAlpha: 0.30
    readonly property real lightChipAlpha: 0.14
    readonly property real darkRingTint: 0.08
    readonly property real darkShadowFactor: 1.3
    readonly property real darkerFactor: 1.4
    readonly property real darkerLineFactor: 1.35
    readonly property real darkerShadowFactor: 1.8
    readonly property real darkerRingLift: 2.0

    readonly property color surface: Ryoku.Theme.surfaceContainer
    readonly property color surfaceHover: Ryoku.Theme.surfaceContainerHigh
    readonly property color surfaceDivider: Ryoku.Theme.outlineVariant
    readonly property color ringWhite: Ryoku.Theme.surfaceContainerLow
    readonly property real cardRing: 0
    readonly property color surfaceRing: Ryoku.Theme.surfaceContainerLow
    readonly property color surfaceTint: Qt.rgba(Ryoku.Theme.primary.r, Ryoku.Theme.primary.g, Ryoku.Theme.primary.b, 0.16)
    readonly property color ink: Ryoku.Theme.onSurface
    readonly property color inkSub: Ryoku.Theme.onSurfaceVariant
    readonly property color paper: Ryoku.Theme.surfaceContainerLow
    readonly property color paperHover: Ryoku.Theme.surfaceContainerHigh
    readonly property color paperEdge: Ryoku.Theme.outlineVariant

    readonly property color line: Ryoku.Theme.outline

    readonly property color lineShadow: Qt.rgba(0, 0, 0, dark ? 0.45 : 0.20)

    readonly property color chipFill: Ryoku.Theme.surfaceContainerHigh
    readonly property color chipInk: Ryoku.Theme.onSurface

    readonly property color scrim: Qt.rgba(Ryoku.Theme.scrim.r, Ryoku.Theme.scrim.g, Ryoku.Theme.scrim.b, 0.55)

    readonly property bool classic: false
    readonly property color pSurface: surface
    readonly property color pSurfaceHover: surfaceHover
    readonly property color pSurfaceDivider: surfaceDivider
    readonly property color pSurfaceRing: surfaceRing
    readonly property color pRingWhite: ringWhite
    readonly property color pLine: line
    readonly property color pLineShadow: lineShadow
    readonly property color pInk: ink
    readonly property color pInkSub: inkSub

    function classicFor(item) {
        if (!classic)
            return false
        for (let p = item; p; p = p.parent)
            if (p.classicPanel === true)
                return true
        return false
    }

    readonly property color colDeep: pal.deep
    readonly property color colHoverTint: pal.hoverTint

    readonly property color phoneRimHighlight: pal.rimHi
    readonly property color phoneBezel: pal.bezel
    readonly property real phoneRimWidth: 10
    readonly property real phoneBezelWidth: 9
    readonly property real phoneScreenInset: phoneRimWidth + phoneBezelWidth
    readonly property real phoneCornerRadius: 100
    readonly property color phoneWallLight: pal.wallLight
    readonly property color phoneWallMid: pal.wallMid
    readonly property color phoneWallDark: pal.wallDark
    readonly property color phoneHardware: pal.hardware
    readonly property color phoneLens: pal.lens
    readonly property color phoneLensGlint: pal.glint

    readonly property var attributeColors: mono
        ? ["#e4e4e4", "#b0b0b0", "#f6f6f6", "#8c8c8c", "#cecece"]
        : ["#8EE3EF", "#FF9ECB", "#FFE066", "#B39DDB", "#A5E6A5"]

    readonly property int pillHeight: 36
    readonly property int radiusOuter: 13
    readonly property int radiusBadge: 15
    readonly property int borderWidth: 3
    readonly property real whiteLine: 2
    readonly property int shadowOffset: 4

    readonly property bool quickFlat: SettingsService.flag("quick.flat")

    readonly property int barVBody: 72
    readonly property int barVPillWidth: 52

    readonly property color colOuterRing: Ryoku.Theme.surfaceContainerLow
    readonly property int outerRingWidth: 4

    readonly property int barFloatInset: 16

    readonly property real capBarHeight: 39
    readonly property real capBarFace: 36
    readonly property real capRimWidth: 3
    readonly property real capShadowDy: 3
    readonly property real capEdgeGap: 8
    readonly property real capStrip: 55
    readonly property real capPadX: 7
    readonly property real capGap: 6
    readonly property real capDotFill: 12
    readonly property real capDotRing: 3
    readonly property real capDot: capDotFill + 2 * capDotRing
    readonly property real capDotActive: 28 + 2 * capDotRing
    readonly property real capChipHeight: 21
    readonly property real capClockSize: 14

    readonly property real capVChip: 40
    readonly property real capVPadX: 5
    readonly property real capVPadY: 8
    readonly property real capVBarFace: capVChip + 2 * (capRimWidth + capVPadX)
    readonly property real capStripV: capEdgeGap * 2 + capVBarFace

    readonly property color capBody: surface
    readonly property color capRim: line
    readonly property color capShade: lineShadow
    readonly property color capChip: Ryoku.Theme.surfaceContainerHighest
    readonly property color capInk: Ryoku.Theme.onSurface
    readonly property color capLit: accentCyan
    readonly property color capLitSoft: Qt.color(pal.glint)
    readonly property var capWsColors: mono
        ? attributeColors.map(c => Qt.color(c))
        : [capLit, capLitSoft, accentMint, Qt.color(pal.wallLight), Qt.color(pal.divider)]

    function capsuleFor(item) {
        for (let p = item; p; p = p.parent)
            if (p.capsuleBar === true)
                return true
        return false
    }

    function capsuleVerticalFor(item) {
        for (let p = item; p; p = p.parent)
            if (p.capsuleBar === true)
                return p.capsuleVertical === true
        return false
    }

    readonly property color irisColorWhite: "#ffffff"
    readonly property color irisColorPink: "#ff8fd6"
    readonly property color irisColorGreen: "#00ffcb"

    function transitionColors(p) {
        const classic = {
            white: Qt.color(irisColorWhite),
            pink: Qt.color(irisColorPink),
            cyan: Qt.color("#22e6d3"),
            green: Qt.color(irisColorGreen)
        }
        if (!p || !SettingsService.flag("wallpaper.themedTransition"))
            return classic
        const vs = ThemeService.baseGroups[0].c
        if (String(p.A).toLowerCase() === String(vs.A).toLowerCase()
                && String(p.B).toLowerCase() === String(vs.B).toLowerCase())
            return classic

        const a = Qt.color(p.A)
        const b = Qt.color(p.B)
        let cyan = a
        let pink = b
        if (a.hslHue >= 0 && b.hslHue >= 0) {
            const dh = Math.min(Math.abs(a.hslHue - b.hslHue), 1 - Math.abs(a.hslHue - b.hslHue))
            const dl = Math.abs(a.hslLightness - b.hslLightness)
            if (dh < 0.09 && dl < 0.14) {
                if (a.hslLightness > 0.45)
                    cyan = Qt.hsla(a.hslHue, a.hslSaturation, a.hslLightness - 0.10, 1)
                else
                    pink = Qt.hsla(b.hslHue, b.hslSaturation, Math.min(0.9, b.hslLightness + 0.2), 1)
            }
        }
        return {
            white: Qt.tint(Qt.color("#ffffff"), Qt.rgba(a.r, a.g, a.b, 0.1)),
            pink: pink,
            cyan: cyan,
            green: cyan
        }
    }

    readonly property string fontFamily: "Google Sans Flex"
    readonly property int fontSize: 16

    readonly property string iconFont: "Material Symbols Rounded"
    readonly property real iconFill: 0
    readonly property string iconStyle: SettingsService.get("appearance.iconStyle")
    readonly property real iconWeight: 400
    readonly property real settingsIconWeight: 600

    readonly property string fontStyleBold: "ExtraBold"

    readonly property int fontSizeTitle: 10
    readonly property int fontSizeSub: 7
    readonly property int fontSizeIdle: 12
    readonly property int fontSizeInfo: 12
    readonly property color colSubText: Qt.rgba(colBorder.r, colBorder.g, colBorder.b, 0.667)

    readonly property real settingsLean: 0
    readonly property int fontSizeMenu: 14
    readonly property int menuRowHeight: 32
    readonly property color colHover: Ryoku.Theme.surfaceContainerHigh
    readonly property color colDivider: Ryoku.Theme.outlineVariant
}
