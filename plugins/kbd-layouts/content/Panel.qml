pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The panel: one card per plugged-in keyboard, with its layout, the quick
// layouts as chips, and "All layouts" for a searchable list of every xkb
// layout. Which keyboards show and the quick layouts live in QS Bar Settings >
// Community.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 340
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var keyboards: service ? service.keyboards : []
    readonly property bool busy: service ? service.busy : false

    // The keyboard whose full layout list is open, or "".
    property string expanded: ""
    property string query: ""

    implicitWidth: root.widthBudget
    implicitHeight: col.implicitHeight + 24 * root.s

    onActiveChanged: {
        if (active && service) service.refresh();
        if (!active) { expanded = ""; query = ""; }
    }

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 12 * root.s

        Row {
            width: parent.width
            spacing: 10 * root.s
            KeyboardIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 30 * root.s
                height: 20 * root.s
                color: Theme.accent
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40 * root.s
                Text {
                    text: "Keyboard Layouts"
                    color: Theme.bright
                    font.family: Theme.display
                    font.pixelSize: 16 * root.s
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.keyboards.length === 0 ? "No keyboards plugged in"
                        : root.keyboards.length === 1 ? "1 keyboard"
                        : root.keyboards.length + " keyboards"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }
            }
        }

        Text {
            width: parent.width
            visible: root.keyboards.length === 0
            wrapMode: Text.WordWrap
            text: "Plug in a USB keyboard and it shows up here. Bluetooth keyboards, and the laptop keyboard if hidden, are toggled in QS Bar Settings > Community."
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }

        Text {
            width: parent.width
            visible: !!root.service && root.service.error !== ""
            wrapMode: Text.WordWrap
            text: root.service ? root.service.error : ""
            color: Theme.sun
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }

        Repeater {
            model: root.keyboards

            Rectangle {
                id: card
                required property var modelData
                readonly property string name: modelData.name
                readonly property string chosen: root.service ? (root.service.assigned[name] || "") : ""
                readonly property bool open: root.expanded === name

                width: col.width
                height: inner.implicitHeight + 20 * root.s
                radius: Theme.radius
                color: Theme.tileBg
                border.color: modelData.main ? Theme.lineStrong : Theme.border
                border.width: 1
                opacity: root.busy ? 0.7 : 1

                Column {
                    id: inner
                    x: 10 * root.s
                    y: 10 * root.s
                    width: parent.width - 20 * root.s
                    spacing: 8 * root.s

                    Item {
                        width: parent.width
                        height: Math.max(title.implicitHeight + sub.implicitHeight, codeCap.height)

                        KeyboardIcon {
                            id: cardIcon
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24 * root.s
                            height: 16 * root.s
                            color: card.modelData.main ? Theme.bright : Theme.dim
                        }

                        Column {
                            anchors.left: cardIcon.right
                            anchors.leftMargin: 10 * root.s
                            anchors.right: codeCap.left
                            anchors.rightMargin: 8 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                id: title
                                width: parent.width
                                elide: Text.ElideRight
                                text: card.modelData.label
                                color: Theme.bright
                                font.family: Theme.font
                                font.pixelSize: 13 * root.s
                            }
                            Text {
                                id: sub
                                width: parent.width
                                elide: Text.ElideRight
                                text: (card.modelData.kind === "usb" ? "USB"
                                       : card.modelData.kind === "bluetooth" ? "Bluetooth" : "Laptop")
                                    + " · " + (card.modelData.keymap || card.modelData.layout)
                                    + (card.chosen === "" ? " · from config" : "")
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 11 * root.s
                            }
                        }

                        Rectangle {
                            id: codeCap
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(30 * root.s, capText.implicitWidth + 12 * root.s)
                            height: 22 * root.s
                            radius: 5 * root.s
                            color: "transparent"
                            border.width: Math.max(1, 1.4 * root.s)
                            border.color: card.chosen !== "" ? Theme.accent : Theme.dim
                            Text {
                                id: capText
                                anchors.centerIn: parent
                                text: card.modelData.layout.toUpperCase()
                                color: card.chosen !== "" ? Theme.accent : Theme.bright
                                font.family: Theme.mono
                                font.weight: Font.DemiBold
                                font.pixelSize: 12 * root.s
                            }
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: 6 * root.s

                        Repeater {
                            model: root.service ? root.service.pinned : []
                            Chip {
                                required property string modelData
                                text: modelData.toUpperCase()
                                selected: card.modelData.layout === modelData
                                onClicked: root.service.choose(card.name, modelData)
                            }
                        }

                        Chip {
                            text: card.open ? "Close" : "All layouts"
                            onClicked: {
                                root.query = "";
                                root.expanded = card.open ? "" : card.name;
                            }
                        }

                        Chip {
                            visible: card.chosen !== ""
                            text: "Use config"
                            onClicked: root.service.reset(card.name)
                        }
                    }

                    Column {
                        visible: card.open
                        width: parent.width
                        spacing: 6 * root.s

                        Rectangle {
                            width: parent.width
                            height: 30 * root.s
                            radius: Theme.radius
                            color: "transparent"
                            border.color: Theme.border
                            border.width: 1

                            SearchField {
                                id: search
                                anchors.fill: parent
                                anchors.leftMargin: 8 * root.s
                                anchors.rightMargin: 8 * root.s
                                s: root.s
                                placeholder: "Search layouts"
                                counterText: list.count
                                onTextChanged: root.query = text
                                onDismissed: root.expanded = ""
                                onAccepted: if (list.count > 0) root.service.choose(card.name, list.model[0].code)
                            }
                            Connections {
                                target: card
                                function onOpenChanged() {
                                    if (card.open) { search.text = ""; search.input.forceActiveFocus(); }
                                }
                            }
                        }

                        ListView {
                            id: list
                            width: parent.width
                            height: 180 * root.s
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: {
                                if (!root.service || !card.open) return [];
                                const q = root.query.trim().toLowerCase();
                                if (q === "") return root.service.layouts;
                                return root.service.layouts.filter(l =>
                                    l.code.startsWith(q) || l.desc.toLowerCase().includes(q));
                            }

                            delegate: Rectangle {
                                id: rowItem
                                required property var modelData
                                readonly property bool current: card.modelData.layout === modelData.code
                                width: ListView.view.width
                                height: 26 * root.s
                                radius: 4 * root.s
                                color: rowArea.containsMouse ? Theme.hair : "transparent"

                                Text {
                                    id: rowCode
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6 * root.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 44 * root.s
                                    text: rowItem.modelData.code.toUpperCase()
                                    color: rowItem.current ? Theme.accent : Theme.bright
                                    font.family: Theme.mono
                                    font.pixelSize: 11 * root.s
                                }
                                Text {
                                    anchors.left: rowCode.right
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6 * root.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    text: rowItem.modelData.desc
                                    color: rowItem.current ? Theme.accent : Theme.cream
                                    font.family: Theme.font
                                    font.pixelSize: 12 * root.s
                                }
                                MouseArea {
                                    id: rowArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !root.busy
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.service.choose(card.name, rowItem.modelData.code)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component Chip: Rectangle {
        id: chip
        property string text: ""
        property bool selected: false
        signal clicked()

        width: chipText.implicitWidth + 16 * root.s
        height: 24 * root.s
        radius: 12 * root.s
        color: selected ? Theme.accent : (chipArea.pressed ? Theme.hair : "transparent")
        border.color: selected ? "transparent" : Theme.border
        border.width: 1

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.text
            color: chip.selected ? Theme.cardBot : Theme.bright
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }

        MouseArea {
            id: chipArea
            anchors.fill: parent
            enabled: !root.busy
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }
}
