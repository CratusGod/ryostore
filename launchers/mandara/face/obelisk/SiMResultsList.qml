/* SiMResultsList.qml — The Obelisk Result Surface
 * ===============================================
 * The rack (the captain's design): a horizontal strip of icon
 * tiles above the lens. Two graces ride it now —
 *
 *   · THE LOUPE (2026-10-25, his pick): the strip stays icons
 *     only, except the tile under the hand — it opens into a
 *     pill, icon at its left, the name lettered beside it and
 *     the descriptor beneath, while its neighbours stay shut
 *     and glide aside. The tile speaks for itself; the old
 *     caption line is retired. (A fan of arcing tiles stood
 *     here for an hour the same day — tried, judged, gone by
 *     his word; the waterline below was kept.)
 *
 *   · THE WATERLINE: every tile throws a reflection at its
 *     foot, dissolving downward; the touched tile's reflection
 *     runs with prism light, and a floor glow travels the
 *     line to pool beneath the selection.
 */
import QtQuick
import Qt5Compat.GraphicalEffects
import shell.services
import "../tw" as TW

Item {
    id: root

    // ── Props ────────────────────────────────────────────────────
    property var controller: null
    property color morphColor: TW.SiMOrchestrator.prismaticColor

    implicitHeight: 94
    visible: controller && controller.searchQuery.length > 0 && controller.flatModel.length > 0

    // The entry under the hand / the selection, resolved flat.
    readonly property var activeEntry: {
        if (!controller || controller.activeIdx < 0) return null
        var m = controller.flatModel[controller.activeIdx]
        return (m && !m.isHeader) ? m : null
    }

    // What the loupe says about an entry: its name is the label;
    // this is the "what's what" — the descriptor behind it.
    // Descriptors are string-capped here (her author's word):
    // a width binding alone did not hold the line against a
    // pasted wall of letters — a cut string cannot trail.
    function describe(entry) {
        if (!entry) return ""
        var d = entry.item ? entry.item.data : null
        if (entry.item.category === "apps" && d)
            return d.comment || d.genericName || d.id || ""
        if (entry.item.category === "files" && d) {
            var p = d.path || ""
            return p.length > 40 ? "…" + p.slice(-39) : p
        }
        if (entry.item.category === "rashin" && d) {
            var s = d.seed || ""
            return s ? (s.length > 28 ? s.slice(0, 28) + "…" : s)
                     : "open the compass window"
        }
        if (entry.item.category === "actions" && d) {
            if (d.rune && d.rune.desc) return d.rune.desc
            if (d.isRom) return "the " + (d.romId || "") + " ROM"
            if (d.cmd) return d.cmd.length > 28 ? d.cmd.slice(0, 28) + "…" : d.cmd
        }
        return ""
    }

    // ── The rack ─────────────────────────────────────────────────
    Connections {
        target: root.controller
        function onActiveIdxChanged() {
            if (root.controller.activeIdx >= 0)
                _rack.positionViewAtIndex(root.controller.activeIdx, ListView.Contain)
        }
    }

    // The waterline's shared fade — reflections are born at the
    // tile's foot and dissolve downward.
    Rectangle {
        id: _reflMask
        width: 54; height: 26
        visible: false
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.85) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }

    // The floor light — a prismatic glow pooled on the waterline
    // that travels to sit beneath the opened tile. Its centre is
    // read from the tile herself, so the loupe's width is honest.
    readonly property real _activeCenterX: {
        if (!controller || controller.activeIdx < 0) return width / 2
        var it = _rack.itemAtIndex(controller.activeIdx)
        if (!it) return width / 2
        return _rack.x + it.x - _rack.contentX + it.width / 2
    }
    Rectangle {
        x: root._activeCenterX - width / 2
        y: 62
        width: 190; height: 30; radius: 15
        color: Qt.alpha(root.morphColor, 0.07)
        opacity: root.activeEntry ? 1 : 0
        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
    Rectangle {
        x: root._activeCenterX - width / 2
        y: 66
        width: 110; height: 22; radius: 11
        color: Qt.alpha(root.morphColor, 0.13)
        opacity: root.activeEntry ? 1 : 0
        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    ListView {
        id: _rack
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, Math.max(1, contentWidth))
        height: 86
        orientation: ListView.Horizontal
        clip: true
        spacing: 8
        interactive: false
        model: controller ? controller.flatModel : []

        delegate: Item {
            id: _tile
            required property var modelData
            required property int index

            readonly property bool isHeader: modelData.isHeader
            readonly property bool isActive: controller && index === controller.activeIdx
            readonly property var  item:     modelData.item
            readonly property string iconSource: isHeader ? ""
                : Icons.path(item.icon || "application-x-executable", "")
            // Rune glyphs ride the icon field as characters; the
            // material names May used ("grid_view", "bolt") are not
            // glyphs — those tiles take the star.
            readonly property string glyph: {
                if (!item || !item.icon) return "✦"
                var s = String(item.icon)
                return (s.length <= 2) ? s : "✦"
            }

            // The loupe: shut at 54, open at 200 — the pill
            // widens and the strip glides around her.
            width: isHeader ? 0 : (isActive ? 200 : 54)
            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            height: 64
            visible: !isHeader

            Rectangle {
                id: _tileFace
                anchors.left: parent.left
                anchors.top: parent.top
                width: parent.width
                height: 54
                radius: 15
                color: isActive ? Qt.alpha(root.morphColor, 0.16)
                                : Qt.alpha("#0a0a12", 0.55)
                border.width: isActive ? 1.5 : 1
                border.color: isActive ? Qt.alpha(root.morphColor, 0.85)
                                       : Qt.alpha("#ffffff", 0.10)
                opacity: isActive ? 1.0 : 0.78

                Behavior on opacity { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Image {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30; height: 30
                    source: _tile.iconSource
                    sourceSize: Qt.size(30, 30)
                    fillMode: Image.PreserveAspectFit
                    visible: source !== ""
                }
                Text {
                    x: 12
                    width: 30
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: _tile.glyph
                    visible: _tile.iconSource === ""
                    color: isActive ? "#ffffff" : Qt.alpha("#ffffff", 0.75)
                    font.pixelSize: 20
                }

                // The loupe's lettering — name over descriptor,
                // fading in as the pill opens.
                Column {
                    x: 52
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 62
                    spacing: 1
                    opacity: _tile.isActive ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    Text {
                        width: parent.width
                        text: _tile.item ? _tile.item.label : ""
                        color: "#ffffff"
                        font.family: TW.TransparentWorld.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: _tile.item ? root.describe({ "item": _tile.item }) : ""
                        color: TW.TransparentWorld.textDim
                        font.family: TW.TransparentWorld.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }

            // ── The Waterline: her reflection, born at the
            // tile's foot and dissolving downward; the touched
            // tile's reflection runs with prism light. The
            // reflection widens with the loupe.
            Item {
                anchors.top: _tileFace.bottom
                anchors.topMargin: 3
                anchors.left: _tileFace.left
                width: _tileFace.width; height: 26
                opacity: isActive ? 0.9 : 0.45
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: _reflMask }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(root.morphColor, isActive ? 0.20 : 0.04)
                }
                Image {
                    x: 12
                    y: -3
                    width: 30; height: 30
                    source: _tile.iconSource
                    sourceSize: Qt.size(30, 30)
                    fillMode: Image.PreserveAspectFit
                    visible: source !== ""
                    transform: Scale { origin.x: 15; origin.y: 15; yScale: -1 }
                }
                Text {
                    x: 12
                    width: 30
                    horizontalAlignment: Text.AlignHCenter
                    y: -3
                    text: _tile.glyph
                    visible: _tile.iconSource === ""
                    color: Qt.alpha("#ffffff", 0.8)
                    font.pixelSize: 20
                    transform: Scale { origin.x: 15; origin.y: 10; yScale: -1 }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: !isHeader
                onEntered: controller.activeIdx = index
                onClicked: { controller.activeIdx = index; controller.executeSelected() }
            }
        }
    }
}
