/* LucidPortal.qml — Unified Horizontal Suggestion Stream
 * =====================================================
 * Single horizontal bar with intelligent grouping and dual-edge fade.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../tw" as TW

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────
    property var   items:       []
    property int   activeIdx:   -1
    property color morphColor:  TW.SiMOrchestrator.prismaticColor
    property int   maxVisible:  6
    property bool  showHotkeys: true
    property bool  showPreview: true
    property real  fadeWidth:   40

    signal itemSelected(var item)
    signal itemHovered(int idx)

    // ── Geometry ──────────────────────────────────────────────────────
    implicitHeight: 44
    visible: items.length > 0
    clip: false

    readonly property real itemHeight:   26
    readonly property real itemSpacing:  6

    function categoryColor(cat) {
        switch(cat) {
            case "rom":              return TW.TransparentWorld.accentSage
            case "macro":            return TW.TransparentWorld.accentForgeFold
            case "intel":            return TW.TransparentWorld.accentBlade
            case "system":           return TW.TransparentWorld.accentEye
            case "sovereign":        return TW.TransparentWorld.accentSovereign
            case "breathing":        return TW.TransparentWorld.accentShroud
            case "cognitive_direct": return TW.TransparentWorld.accentSage
            case "forge":            return TW.TransparentWorld.accentForgeFold
            default:                 return root.morphColor
        }
    }

    Item {
        id: scrollContainer
        anchors.fill: parent
        anchors.leftMargin:  root.fadeWidth
        anchors.rightMargin: root.fadeWidth
        clip: true

        Row {
            id: pillStream
            height: parent.height
            spacing: root.itemSpacing

            x: items.length <= maxVisible
               ? Math.max(0, (scrollContainer.width - implicitWidth) / 2)
               : -calculateScrollOffset()

            Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.25 } }

            function calculateScrollOffset() {
                if (activeIdx < 0) return 0
                var itemPos = 0
                for (var i = 0; i < activeIdx && i < repeater.count; i++) {
                    var it = repeater.itemAt(i)
                    itemPos += it ? (it.implicitWidth + root.itemSpacing) : (root.itemHeight + root.itemSpacing)
                }
                var activeWidth = repeater.itemAt(activeIdx) ? repeater.itemAt(activeIdx).implicitWidth : root.itemHeight
                var centerOffset = itemPos + activeWidth / 2 - scrollContainer.width / 2
                var maxScroll = Math.max(0, pillStream.implicitWidth - scrollContainer.width)
                return Math.max(0, Math.min(centerOffset, maxScroll))
            }

            Repeater {
                id: repeater
                model: root.items.length

                Rectangle {
                    id: _pill
                    required property int index
                    property var  item:     root.items[index] || {}
                    property bool isActive: index === root.activeIdx

                    property real _crystalProg: 0.0
                    property real _shimmerTime: 0.0

                    NumberAnimation on _crystalProg {
                        id: _crystalAnim
                        from: 0.0; to: 1.0; duration: 260
                        easing.type: Easing.OutCubic
                        running: false
                    }

                    Timer {
                        interval: 33; repeat: true
                        running:  _pill.isActive && _pill._crystalProg >= 1.0
                        onTriggered: _pill._shimmerTime += 0.033
                    }

                    onIsActiveChanged: {
                        if (isActive) {
                            _crystalProg = 0.0
                            _crystalAnim.restart()
                        }
                    }

                    implicitWidth:  _contentRow.implicitWidth + 24
                    height:         root.itemHeight
                    radius:         height / 2

                    readonly property color itemColor: item.color
                        ? Qt.color(item.color)
                        : root.categoryColor(item.category)

                    color: isActive
                        ? Qt.rgba(itemColor.r, itemColor.g, itemColor.b,
                                  0.10 + _crystalProg * 0.06)
                        : "transparent"
                    border.color: isActive
                        ? Qt.rgba(itemColor.r, itemColor.g, itemColor.b,
                                  0.45 + _crystalProg * 0.25)
                        : "transparent"
                    border.width: 1

                    Behavior on color        { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on scale        { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 0.4 } }

                    scale: isActive ? 1.06 : 1.0

                    layer.enabled: isActive
                    layer.effect: MultiEffect {
                        shadowEnabled: isActive
                        shadowColor:   Qt.rgba(_pill.itemColor.r, _pill.itemColor.g,
                                               _pill.itemColor.b, 0.45)
                        shadowBlur:    0.85
                        shadowVerticalOffset: 3
                        blurEnabled:   false
                    }

                    ShaderEffect {
                        anchors.fill: parent
                        z: 1
                        visible: _pill.isActive && _pill._crystalProg < 1.0
                        property real u_time:       _pill._shimmerTime
                        property real u_confidence: 0.85
                        property real u_progress:   _pill._crystalProg
                        property real u_shatter:    0.0
                        property real u_morphR:     _pill.itemColor.r
                        property real u_morphG:     _pill.itemColor.g
                        property real u_morphB:     _pill.itemColor.b
                        property real u_width:      width
                        property real u_height:     height
                        fragmentShader: "../shaders/crystallize.frag.qsb"
                        blending: true
                    }

                    ShaderEffect {
                        anchors.fill: parent
                        z: 1
                        visible: _pill.isActive && _pill._crystalProg >= 1.0
                        opacity: 0.20
                        property real u_time:       _pill._shimmerTime
                        property real u_confidence: 0.30
                        property real u_progress:   0.55
                        property real u_shatter:    0.0
                        property real u_morphR:     _pill.itemColor.r
                        property real u_morphG:     _pill.itemColor.g
                        property real u_morphB:     _pill.itemColor.b
                        property real u_width:      width
                        property real u_height:     height
                        fragmentShader: "../shaders/crystallize.frag.qsb"
                        blending: true
                    }

                    RowLayout {
                        id: _contentRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text:  _pill.item.icon || "⚡"
                            color: _pill.isActive ? _pill.itemColor : Qt.rgba(1, 1, 1, 0.30)
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        Text {
                            text:  _pill.item.label || ""
                            color: _pill.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.45)
                            font.family:      TW.TransparentWorld.fontFamily
                            font.pixelSize:   14
                            font.bold:        true
                            font.letterSpacing: 1.5
                            elide: Text.ElideRight
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        Rectangle {
                            visible: root.showHotkeys && _pill.index < 9
                            width:  _hotkeyTxt.implicitWidth + 8
                            height: 14; radius: 3
                            color:  Qt.rgba(1, 1, 1, _pill.isActive ? 0.15 : 0.05)
                            Text {
                                id: _hotkeyTxt
                                anchors.centerIn: parent
                                text:  "⌘" + (_pill.index + 1)
                                color: _pill.isActive ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.25)
                                font.family:    "Fira Code"
                                font.pixelSize: 14
                                font.bold:      true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered: { root.activeIdx = _pill.index; root.itemHovered(_pill.index) }
                        onClicked: root.itemSelected(_pill.item)
                    }
                }
            }
        }
    }



    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:              parent.bottom
        anchors.topMargin:        4
        text:  root.showPreview && activeIdx >= 0 && root.items[activeIdx]?.preview || ""
        color: Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.5)
        font.family:    "Fira Code"
        font.pixelSize: 14
        font.italic:    true
        visible: text !== ""
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    function selectNext() { if (items.length > 0) activeIdx = (activeIdx + 1) % items.length }
    function selectPrevious() { if (items.length > 0) activeIdx = (activeIdx - 1 + items.length) % items.length }
}
