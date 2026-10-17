pragma ComponentBehavior: Bound

import QtQuick

// Seasonal effects drawn over the companion: snow, bats, petals, leaves, glints.
// Each particle is one small pixel sprite from assets/particles.png (see
// content/SeasonDefs.qml, generated) moved by a looping animation; positions are
// snapped to the sprite's pixel grid so everything stays crisp. Nothing runs
// when `animate` is false (reduced motion, hidden widget).
Item {
    id: fx

    property string season: ""
    property int pixelScale: 3
    property bool animate: true

    readonly property SeasonDefs defs: SeasonDefs {}
    readonly property var list: season !== "" && defs.fx[season] ? defs.fx[season] : []
    readonly property int cellPx: 48 * pixelScale

    clip: true

    Repeater {
        model: fx.animate ? fx.list : []

        delegate: Item {
            id: p

            required property var modelData
            readonly property var spr: fx.defs.sprites[modelData.p]
            readonly property int px: fx.pixelScale
            readonly property bool flipped: modelData.kind === "fly" && modelData.x1 < modelData.x0

            // raw (unsnapped) position in sprite pixels and animation phase
            property real rx: modelData.x !== undefined ? modelData.x : (modelData.x0 !== undefined ? modelData.x0 : 0)
            property real ry: modelData.y !== undefined ? modelData.y : -8
            property real swing: 0
            property real fr: 0
            readonly property int frame: Math.max(0, Math.min(spr.frames - 1, Math.floor(fr)))

            width: spr.w * px
            height: spr.h * px
            x: Math.round(rx + swing) * px
            y: Math.round(ry) * px
            opacity: modelData.kind === "twinkle" ? glow : 1
            property real glow: 0

            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/particles.png")
                smooth: false
                mipmap: false
                mirror: p.flipped
                fillMode: Image.Stretch
                sourceClipRect: Qt.rect(p.frame * fx.defs.cellW, p.spr.row * fx.defs.cellH, p.spr.w, p.spr.h)
            }

            // start after the particle's own delay so they never move in lockstep
            Timer {
                interval: p.modelData.delay || 1
                running: true
                onTriggered: {
                    switch (p.modelData.kind) {
                    case "fall": fall.start(); sway.start(); tumble.start(); break;
                    case "fly": fly.start(); bob.start(); flap.start(); break;
                    case "twinkle": twinkle.start(); grow.start(); break;
                    case "bob": bobSun.start(); flip.start(); break;
                    }
                }
            }

            // fall: top to bottom while swaying side to side
            NumberAnimation { id: fall; target: p; property: "ry"; from: -6; to: 50
                duration: p.modelData.dur || 6000; loops: Animation.Infinite }
            SequentialAnimation { id: sway; loops: Animation.Infinite
                NumberAnimation { target: p; property: "swing"; from: -(p.modelData.sway || 2); to: (p.modelData.sway || 2)
                    duration: (p.modelData.dur || 6000) / 3; easing.type: Easing.InOutSine }
                NumberAnimation { target: p; property: "swing"; from: (p.modelData.sway || 2); to: -(p.modelData.sway || 2)
                    duration: (p.modelData.dur || 6000) / 3; easing.type: Easing.InOutSine }
            }
            NumberAnimation { id: tumble; target: p; property: "fr"; from: 0; to: p.spr.frames - 0.001
                duration: 900 * p.spr.frames; loops: Animation.Infinite }

            // fly: across the sprite with a little vertical bobbing and wing flaps
            NumberAnimation { id: fly; target: p; property: "rx"; from: p.modelData.x0 || 0; to: p.modelData.x1 || 0
                duration: p.modelData.dur || 8000; loops: Animation.Infinite }
            SequentialAnimation { id: bob; loops: Animation.Infinite
                NumberAnimation { target: p; property: "ry"; from: p.modelData.y || 0; to: (p.modelData.y || 0) + (p.modelData.bob || 2)
                    duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { target: p; property: "ry"; from: (p.modelData.y || 0) + (p.modelData.bob || 2); to: p.modelData.y || 0
                    duration: 700; easing.type: Easing.InOutSine }
            }
            NumberAnimation { id: flap; target: p; property: "fr"; from: 0; to: p.spr.frames - 0.001
                duration: 260 * p.spr.frames; loops: Animation.Infinite }

            // twinkle: fade in/out in place, growing from a dot to a cross
            SequentialAnimation { id: twinkle; loops: Animation.Infinite
                NumberAnimation { target: p; property: "glow"; from: 0; to: 1; duration: (p.modelData.dur || 1800) * 0.35 }
                NumberAnimation { target: p; property: "glow"; from: 1; to: 0; duration: (p.modelData.dur || 1800) * 0.35 }
                PauseAnimation { duration: (p.modelData.dur || 1800) * 0.3 }
            }
            SequentialAnimation { id: grow; loops: Animation.Infinite
                NumberAnimation { target: p; property: "fr"; from: 0; to: p.spr.frames - 0.001; duration: (p.modelData.dur || 1800) * 0.35 }
                NumberAnimation { target: p; property: "fr"; from: p.spr.frames - 0.001; to: 0; duration: (p.modelData.dur || 1800) * 0.35 }
                PauseAnimation { duration: (p.modelData.dur || 1800) * 0.3 }
            }

            // bob: a small corner sun that breathes
            SequentialAnimation { id: bobSun; loops: Animation.Infinite
                NumberAnimation { target: p; property: "ry"; from: p.modelData.y || 0; to: (p.modelData.y || 0) + 1
                    duration: p.modelData.dur || 1600; easing.type: Easing.InOutSine }
                NumberAnimation { target: p; property: "ry"; from: (p.modelData.y || 0) + 1; to: p.modelData.y || 0
                    duration: p.modelData.dur || 1600; easing.type: Easing.InOutSine }
            }
            NumberAnimation { id: flip; target: p; property: "fr"; from: 0; to: p.spr.frames - 0.001
                duration: 1400; loops: Animation.Infinite }
        }
    }
}
