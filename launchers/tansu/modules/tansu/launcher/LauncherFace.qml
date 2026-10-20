import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../../services"
import "../../../modules/common"
import "../../../modules/common/widgets"

// The screen of the launcher phone (LauncherPhone.qml): the shell's home
// screen. Same 654x1214 frame as the Quick Panel's face, so it sits in the same
// PhoneBody.
//
//   - a clock / date strip at the top (the notch is in the middle of it)
//   - a search pill: type anything and the Apps drawer takes over
//   - APPS: every installed app, A to Z, or the ranked matches for what you typed
//
// There is no Home page, no Back chip and no Settings / Wallpapers tile: Settings is
// the gear on the Quick Panel and the Wallpapers have their own key.
//
// Keys: type to search, arrows move the pick, Enter opens it (the first match
// while searching), Escape clears the search, then asks to go back
// (closeRequested). Ctrl+1..4 jump to a screen of the phone (jumpRequested).
//
// It is the Apps screen of the one phone (QuickPanel.qml, PhoneRoute.js).
//
// What the old Overview + App Launcher board could do beyond launching apps (the
// calculator, clipboard, colour, emoji and web cards, `> cmd`, system actions like
// "lock") is here too, in LauncherExtras.qml, driven by the same search box.
//
// Pure UI apart from reading the app index it is given: it never launches
// anything itself, it asks (`appActivated`,
// `closeRequested`, `doneRequested`) and QuickPanel.qml does it.
Item {
    id: face

    readonly property bool classicPanel: true

    width: 654
    height: 1214

    property var source: null
    property string clockText: "00:00AM"
    property string dateText: "Sun, 20  Sep"
    property real downloadBps: 0
    property real uploadBps: 0
    property real renderScale: 1
    property real visibleBottom: 1214
    property real visibleReach: face.visibleBottom + 58
    property string screenName: ""

    signal appActivated(var app)
    signal closeRequested()
    signal jumpRequested(int number)
    signal doneRequested()
    signal pickerRequested()
    signal colorPickedBack(string hex)
    signal wallpapersRequested()

    readonly property real sideX: 52
    readonly property real gridW: 550
    readonly property int columns: 4
    readonly property real cellW: gridW / columns
    readonly property real cellH: 168

    readonly property string query: input.text
    readonly property bool searching: query.trim().length > 0
    property bool keyNav: false

    property bool reveal: false
    property real revealT: 1
    onEnabledChanged: {
        if (enabled && source)
            source.sync()
        if (enabled && reveal) {
            revealT = 0
            revealAnim.restart()
        }
    }
    SequentialAnimation {
        id: revealAnim

        PauseAnimation {
            duration: 60
        }

        NumberAnimation {
            target: face
            property: "revealT"
            to: 1
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    function focusSearch() {
        input.forceActiveFocus()
        input.cursorPosition = input.text.length
    }

    function appendText(text) {
        input.text = input.text + text
        input.cursorPosition = input.text.length
    }

    function setText(text) {
        input.text = text
        input.cursorPosition = input.text.length
        input.forceActiveFocus()
    }

    function reset() {
        input.text = ""
        keyNav = false
        drawerGrid.currentIndex = -1
        drawerGrid.positionViewAtBeginning()
    }

    function back() {
        if (input.text.length > 0)
            input.text = ""
        else
            face.closeRequested()
    }

    readonly property var drawerEntries: {
        if (!face.source)
            return []
        return face.searching ? face.source.rankEntries(face.query) : face.source.entries
    }

    ScriptModel {
        id: drawerModel

        values: face.drawerEntries
        objectProp: "key"
    }

    function activate(item) {
        if (!item)
            return
        if (item.app)
            face.appActivated(item.app)
    }

    function activateCurrent() {
        const grid = drawerGrid
        let i = grid.currentIndex
        if (i < 0 && face.searching)
            i = 0
        if (i >= 0 && i < face.drawerEntries.length)
            face.activate(face.drawerEntries[i])
    }

    function moveKey(key) {
        if (extrasLayer.cardShown) {
            extrasLayer.navigate(key === Qt.Key_Left ? -1 : key === Qt.Key_Right ? 1 : 0,
                                 key === Qt.Key_Up ? -1 : key === Qt.Key_Down ? 1 : 0)
            return
        }
        if (key === Qt.Key_Up || key === Qt.Key_Down) {
            const where = extrasLayer.moveRows(key === Qt.Key_Down ? 1 : -1,
                                               drawerGrid.currentIndex >= 0,
                                               drawerGrid.currentIndex >= 0 && drawerGrid.currentIndex < face.columns)
            if (where === "rows") {
                face.keyNav = true
                drawerGrid.currentIndex = -1
                return
            }
            if (where === "grid") {
                face.keyNav = true
                drawerGrid.currentIndex = 0
                return
            }
        }
        const grid = drawerGrid
        if (grid.count === 0)
            return
        face.keyNav = true
        if (grid.currentIndex < 0) {
            grid.currentIndex = 0
            return
        }
        if (key === Qt.Key_Left)
            grid.moveCurrentIndexLeft()
        else if (key === Qt.Key_Right)
            grid.moveCurrentIndexRight()
        else if (key === Qt.Key_Up)
            grid.moveCurrentIndexUp()
        else
            grid.moveCurrentIndexDown()
    }

    onQueryChanged: {
        drawerGrid.currentIndex = face.searching ? 0 : -1
        drawerGrid.positionViewAtBeginning()
        Qt.callLater(() => drawerGrid.positionViewAtBeginning())
    }

    readonly property string lcdPath: SettingsService.flag("launcher.lcdWallpaper")
                                      ? WallpaperService.imageFor(WallpaperService.pathFor(face.screenName))
                                      : ""

    readonly property bool lcdOn: face.lcdPath !== ""

    LauncherLcd {
        id: lcdLayer

        z: -10
        x: Theme.phoneScreenInset
        y: Theme.phoneScreenInset
        width: face.width - 2 * Theme.phoneScreenInset
        height: face.height - 2 * Theme.phoneScreenInset
        path: face.lcdPath
        renderScale: face.renderScale
        active: face.visible
    }

    readonly property color inkLeft: face.lcdOn ? (lcdLayer.darkLeft ? "#ffffff" : Theme.colBorder) : Theme.pInk
    readonly property color inkRight: face.lcdOn ? (lcdLayer.darkRight ? "#ffffff" : Theme.colBorder) : Theme.pInk

    Column {
        x: 67
        y: 36
        spacing: -7

        Text {
            text: face.clockText
            color: face.inkLeft
            font.family: Theme.fontFamily
            font.pixelSize: 24
            font.weight: Font.ExtraBold
            font.styleName: Theme.fontStyleBold
        }

        Text {
            text: face.dateText
            color: face.inkLeft
            font.family: Theme.fontFamily
            font.pixelSize: 20
        }
    }

    function formatRate(bps) {
        if (bps >= 1048576)
            return (bps / 1048576).toFixed(1) + " MB/s"
        if (bps >= 1024)
            return Math.round(bps / 1024) + " KB/s"
        return Math.round(bps) + " B/s"
    }

    Column {
        id: speedBlock

        x: 654 - 67 - width
        y: 38
        width: 150
        spacing: -2

        Item {
            width: speedBlock.width
            height: downText.implicitHeight

            MaterialIcon {
                id: downIcon

                name: "arrow_downward"
                size: 20
                weight: 600
                color: face.inkRight
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: downText

                anchors.right: downIcon.left
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                text: face.formatRate(face.downloadBps)
                color: face.inkRight
                font.family: Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.ExtraBold
                font.styleName: Theme.fontStyleBold
            }
        }

        Item {
            width: speedBlock.width
            height: upText.implicitHeight

            MaterialIcon {
                id: upIcon

                name: "arrow_upward"
                size: 20
                weight: 600
                color: face.inkRight
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: upText

                anchors.right: upIcon.left
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                text: face.formatRate(face.uploadBps)
                color: face.inkRight
                font.family: Theme.fontFamily
                font.pixelSize: 20
            }
        }
    }

    Rectangle {
        x: face.sideX + 4
        y: 124 + 4
        width: face.gridW
        height: 68
        radius: 34
        color: Theme.pLineShadow
        antialiasing: true
    }

    Rectangle {
        id: pill

        x: face.sideX
        y: 124
        width: face.gridW
        height: 68
        radius: 34
        color: Theme.pSurface
        border.width: 3
        border.color: Theme.pLine
        antialiasing: true

        MaterialIcon {
            x: 24
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            size: 30
        }

        Text {
            x: 70
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: "Search apps"
            color: Theme.pInkSub
            font.family: Theme.fontFamily
            font.pixelSize: 24
            font.weight: Font.Bold
        }

        TextInput {
            id: input

            x: 70
            width: parent.width - 70 - 64
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.pInk
            selectionColor: Theme.accentCyan
            selectedTextColor: Theme.pInk
            font.family: Theme.fontFamily
            font.pixelSize: 24
            font.weight: Font.Bold
            clip: true
            focus: true
            selectByMouse: true

            Keys.onPressed: event => {
                if ((event.modifiers & Qt.ControlModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_4) {
                    face.jumpRequested(event.key - Qt.Key_0)
                } else if (event.key === Qt.Key_Escape) {
                    face.back()
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (!extrasLayer.enter((event.modifiers & Qt.ShiftModifier) !== 0))
                        face.activateCurrent()
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down
                           || event.key === Qt.Key_Left && (input.text.length === 0 || extrasLayer.cardMode === "emoji")
                           || event.key === Qt.Key_Right && (input.text.length === 0 || extrasLayer.cardMode === "emoji")) {
                    face.moveKey(event.key)
                } else if (event.key === Qt.Key_Tab) {
                    if (!extrasLayer.tab(1))
                        face.moveKey(Qt.Key_Right)
                } else if (event.key === Qt.Key_Backtab) {
                    if (!extrasLayer.tab(-1))
                        face.moveKey(Qt.Key_Left)
                } else {
                    return
                }
                event.accepted = true
            }
        }

        Item {
            visible: input.text.length > 0
            x: parent.width - 56
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: clearArea.containsMouse ? Theme.accentMint : "transparent"
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: "close"
                size: 26
            }

            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    input.text = ""
                    face.focusSearch()
                }
            }
        }
    }

    readonly property real pageY: 228
    readonly property real pageBottom: Math.max(pageY + 168 + 52, Math.min(1040, face.visibleBottom - 84 - 34)) + 60
    readonly property real pageH: pageBottom - pageY
    // The apps grid alone goes further down than the page (the cards of the extras
    // keep the page's size): to the monitor's edge, never past the glass.
    readonly property real gridBottom: Math.max(pageBottom, Math.min(1100, face.visibleReach))
    readonly property real gridH: gridBottom - pageY

    Item {
        id: drawerPage

        x: face.sideX
        y: face.pageY + extrasLayer.rowsHeight + (1 - face.revealT) * 30
        width: face.gridW
        height: face.gridH - extrasLayer.rowsHeight
        opacity: face.revealT * (1 - extrasLayer.cardK)
        scale: (0.96 + 0.04 * face.revealT) * (1 - 0.025 * extrasLayer.cardK)
        transformOrigin: Item.Top
        visible: opacity > 0.01
        enabled: extrasLayer.cardK < 0.5

        WheelScroll { scroller: drawerGrid }
        GridView {
            id: drawerGrid

            anchors.fill: parent
            cellWidth: face.cellW
            cellHeight: face.cellH
            clip: true
            model: drawerModel
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: face.cellH
            reuseItems: true
            delegate: tileDelegate
            bottomMargin: Math.max(0, face.gridBottom - face.visibleBottom + 24)

            TansuScrollBar {}
        }

        Text {
            id: noMatch

            anchors.centerIn: parent
            visible: face.searching && drawerGrid.count === 0 && extrasLayer.rows.length === 0
            text: "No apps match"
            color: face.lcdOn ? "#ffffff" : Theme.pInkSub
            style: face.lcdOn ? Text.Outline : Text.Normal
            styleColor: Qt.rgba(0.10, 0.10, 0.22, 0.85)
            font.family: Theme.fontFamily
            font.pixelSize: 24
            font.weight: Font.Bold
        }
    }

    LauncherExtras {
        id: extrasLayer

        x: face.sideX
        y: face.pageY
        width: face.gridW
        height: face.pageH
        visible: face.searching || extrasLayer.shownMode !== "" || extrasLayer.rowsHold.length > 0
        query: face.query
        active: face.enabled
        present: face.visible
        appCount: face.drawerEntries.length
        pageWidth: face.gridW
        pageHeight: face.pageH

        onDoneRequested: face.doneRequested()
        onSetTextRequested: text => face.setText(text)
        onPickerRequested: face.pickerRequested()
        onColorPicked: hex => face.colorPickedBack(hex)
        onWallpapersRequested: face.wallpapersRequested()
    }

    Component {
        id: tileDelegate

        Item {
            id: tile

            required property var modelData
            required property int index

            readonly property bool picked: face.keyNav && GridView.isCurrentItem
            readonly property bool lit: area.containsMouse || picked

            property real litP: lit ? 1 : 0
            Behavior on litP {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            property real pressP: area.pressed ? 1 : 0
            Behavior on pressP {
                NumberAnimation {
                    duration: area.pressed ? 80 : 260
                    easing.type: area.pressed ? Easing.OutQuad : Easing.OutBack
                    easing.overshoot: area.pressed ? 0 : 2.2
                }
            }

            readonly property real iconBox: 100
            readonly property real iconY: 12

            width: face.cellW
            height: face.cellH

            readonly property string iconPath: face.source ? face.source.iconFor(tile.modelData.icon) : ""
            readonly property bool noIcon: tile.iconPath === "" || appIcon.status === Image.Error

            IconImage {
                id: appIcon

                x: Math.round((tile.width - implicitWidth) / 2)
                y: tile.iconY + Math.round((tile.iconBox - implicitHeight) / 2)
                implicitSize: 72
                asynchronous: true
                visible: !tile.noIcon
                transformOrigin: Item.Center
                scale: (1 + 0.10 * tile.litP) * (1 - 0.08 * tile.pressP)
                source: tile.iconPath
            }

            Loader {
                active: tile.noIcon
                x: Math.round((tile.width - 72) / 2)
                y: tile.iconY + Math.round((tile.iconBox - 72) / 2)
                width: 72
                height: 72
                transformOrigin: Item.Center
                scale: (1 + 0.10 * tile.litP) * (1 - 0.08 * tile.pressP)
                sourceComponent: AppPlaceholder {
                    size: 72
                    name: tile.modelData.name
                }
            }

            Text {
                id: nameText

                x: 4
                y: tile.iconY + tile.iconBox + 14
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                lineHeight: 0.88
                lineHeightMode: Text.ProportionalHeight
                elide: Text.ElideRight
                text: tile.modelData.name
                color: face.lcdOn ? "#ffffff" : Theme.pInk
                style: face.lcdOn ? Text.Outline : Text.Normal
                styleColor: Qt.rgba(0.10, 0.10, 0.22, 0.85)
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.weight: Font.ExtraBold
                font.styleName: Theme.fontStyleBold
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: face.keyNav = false
                onClicked: face.activate(tile.modelData)
            }
        }
    }
}
