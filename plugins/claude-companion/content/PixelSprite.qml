import QtQuick

// One sheet, one Image: the visible cell is picked with sourceClipRect, so a
// frame change is a rect update, never a file load. A single-shot Timer is armed
// per frame (each frame carries its own duration), so a still pose costs no
// wakeups and nothing runs while hidden or when motion is reduced.
Item {
    id: sp

    property string anim: "idle"
    property string season: ""           // "" = the plain sheet
    property bool sheetMissing: false
    onSeasonChanged: sheetMissing = false
    property int pixelScale: 3
    property bool animate: true          // false = hold the first frame
    property alias frameIndex: sp.step   // for the debug overlay

    readonly property SpriteDefs defs: SpriteDefs {}
    readonly property var def: defs.anims[anim] || defs.anims.idle
    readonly property int count: def.frames.length
    property int step: 0
    readonly property int cell: def.frames[Math.min(step, count - 1)][0]
    readonly property int fps: Math.round(1000 / Math.max(1, def.frames[Math.min(step, count - 1)][1]))

    implicitWidth: defs.cellW * pixelScale
    implicitHeight: defs.cellH * pixelScale

    onAnimChanged: { step = 0; _arm(); }
    onAnimateChanged: { if (!animate) step = 0; _arm(); }
    onVisibleChanged: _arm()
    Component.onCompleted: _arm()

    function _arm() {
        timer.stop();
        if (!animate || !visible || count < 2) return;
        if (!def.loop && step >= count - 1) return;     // one-shot: hold the last frame
        timer.interval = def.frames[step][1];
        timer.start();
    }

    Timer {
        id: timer
        repeat: false
        onTriggered: {
            const last = sp.count - 1;
            sp.step = sp.step < last ? sp.step + 1 : (sp.def.loop ? 0 : last);
            sp._arm();
        }
    }

    Image {
        width: sp.implicitWidth
        height: sp.implicitHeight
        source: Qt.resolvedUrl(sp.season !== "" && !sp.sheetMissing
            ? "../assets/season-" + sp.season + ".png" : "../assets/sprites.png")
        onStatusChanged: if (status === Image.Error && sp.season !== "") sp.sheetMissing = true
        smooth: false
        mipmap: false
        cache: true
        asynchronous: false
        fillMode: Image.Stretch
        sourceClipRect: Qt.rect((sp.cell % sp.defs.cols) * sp.defs.cellW,
                                Math.floor(sp.cell / sp.defs.cols) * sp.defs.cellH,
                                sp.defs.cellW, sp.defs.cellH)
    }
}
