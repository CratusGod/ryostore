import "../../../.."
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

import "androidStyle"
import "../../../common/functions/quick_toggle_layout.js" as QuickToggleLayout
import "../../../common/functions/quick_toggle_pages.js" as QuickTogglePages

AbstractQuickPanel {
    id: root
    property bool editMode: false
    Layout.fillWidth: true

    implicitHeight: contentItem.implicitHeight + root.padding * 2
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    property real spacing: Appearance.spacing.space100
    property real padding: Appearance.spacing.space100
    readonly property real baseCellWidth: QuickToggleLayout.cellWidth(
        root.width - root.padding * 2, root.spacing, root.columns)
    readonly property real baseCellHeight: 56

    readonly property list<string> availableToggleTypes: ["network", "bluetooth", "phoneConnect", "idleInhibitor", "nightLight", "gameMode", "screenSnip", "mic", "audio", "notifications", "powerProfile"]
    readonly property int columns: Config.options.sidebar.quickToggles.android.columns

    readonly property list<var> pages: Config.ready
        ? QuickTogglePages.normalise(
              Config.options.sidebar.quickToggles.android.pages,
              Config.options.sidebar.quickToggles.android.toggles)
        : [[]]
    readonly property int pageCount: root.pages.length
    property int currentPage: 0
    onPageCountChanged: root.currentPage = QuickTogglePages.clampPage(root.pages, root.currentPage)
    onCurrentPageChanged: pager.snapTo(root.currentPage)

    readonly property bool needsMigration: Config.ready
        && (Config.options.sidebar.quickToggles.android.pages?.length ?? 0) === 0
        && (Config.options.sidebar.quickToggles.android.toggles?.length ?? 0) > 0
    onNeedsMigrationChanged: if (root.needsMigration)
        Config.options.sidebar.quickToggles.android.pages = root.pages

    readonly property list<var> unusedToggles: {
        const used = QuickTogglePages.usedTypes(root.pages)
        const types = availableToggleTypes.filter(type => !used[type])
        return types.map(type => { return { type: type, size: 1 } })
    }

    readonly property string pagesSignature: QuickTogglePages.signatureOf(root.pages, root.columns)
    readonly property string unusedSignature: QuickToggleLayout.signatureOf(root.unusedToggles, root.columns)
    onPagesSignatureChanged: root.requestSync()
    onUnusedSignatureChanged: root.requestSync()

    property bool syncPending: false
    function requestSync() {
        if (root.syncPending) return;
        root.syncPending = true;
        Qt.callLater(() => {
            root.syncPending = false;
            for (let i = 0; i < pageRepeater.count; i++)
                pageRepeater.itemAt(i)?.syncNow();
            unusedModel.sync(root.unusedToggles, root.columns);
        });
    }

    Component.onCompleted: {
        if (root.needsMigration)
            Config.options.sidebar.quickToggles.android.pages = root.pages;
        root.requestSync();
        if (GlobalStates.sidebarRightOpen)
            Qt.callLater(() => {
                if (GlobalStates.sidebarRightOpen) root.enterWave();
            });
    }

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (GlobalStates.sidebarRightOpen) root.enterWave();
        }
    }

    function enterWave() {
        const page = pageRepeater.itemAt(root.currentPage);
        if (!page) return;
        page.wave.park();
        page.wave.enter();
    }

    property bool dragActive: false
    property int edgeDirection: 0
    function currentGrid() { return pageRepeater.itemAt(root.currentPage)?.grid ?? null; }
    function currentIndicator() { return pageRepeater.itemAt(root.currentPage)?.indicator ?? null; }
    function dragHoverAt(sceneX) {
        const localX = pager.mapFromItem(null, sceneX, 0).x;
        const band = 28;
        const direction = localX < band ? -1 : (localX > pager.width - band ? 1 : 0);
        if (direction === root.edgeDirection) return;
        root.edgeDirection = direction;
        if (direction === 0) edgeHold.stop(); else edgeHold.restart();
    }
    function dragEnded() {
        root.edgeDirection = 0;
        edgeHold.stop();
        root.dragActive = false;
    }
    Timer {
        id: edgeHold
        interval: 300
        onTriggered: {
            const next = root.currentPage + root.edgeDirection;
            if (next < 0 || next >= root.pageCount) return;
            root.currentPage = next;
            edgeHold.restart();
        }
    }

    onEditModeChanged: if (!root.editMode) {
        const pruned = QuickTogglePages.pruned(root.pages);
        root.currentPage = QuickTogglePages.clampPage(pruned, root.currentPage);
        Config.options.sidebar.quickToggles.android.pages = pruned;
    }

    StableQuickToggleModel { id: unusedModel }

    function gridHeight(rows) {
        return Math.max(rows, 1) * root.baseCellHeight
            + Math.max(0, Math.max(rows, 1) - 1) * root.spacing;
    }
    readonly property int currentRows: QuickToggleLayout.rowCount(
        QuickToggleLayout.pack(root.pages[root.currentPage] ?? [], root.columns))

    function unusedGridHeight() {
        return unusedModel.gridRows * root.baseCellHeight
            + Math.max(0, unusedModel.gridRows - 1) * root.spacing;
    }

    Column {
        id: contentItem
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: Appearance.spacing.space150

        Item {
            id: pagerArea
            width: contentItem.width
            height: root.gridHeight(root.currentRows)
            clip: true

            Flickable {
                id: pager
                anchors.fill: parent
                contentWidth: root.pageCount * pager.width
                contentHeight: pager.height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                interactive: false
                onWidthChanged: contentX = root.currentPage * width

                NumberAnimation {
                    id: snapAnim
                    target: pager
                    property: "contentX"
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                }
                function snapTo(page) {
                    snapAnim.stop();
                    snapAnim.to = page * pager.width;
                    snapAnim.start();
                }

                Row {
                    Repeater {
                        id: pageRepeater
                        model: root.pageCount
                        delegate: Item {
                            id: pageItem
                            required property int index
                            width: pager.width
                            height: pagerArea.height

                            property alias wave: tileWave
                            property alias grid: pageGrid
                            property alias indicator: pageDropIndicator

                            function syncNow() {
                                pageModel.sync(root.pages[pageItem.index] ?? [], root.columns);
                            }
                            Component.onCompleted: syncNow()

                            StableQuickToggleModel { id: pageModel }

                            Item {
                                id: pageGrid
                                width: pageItem.width
                                height: pageItem.height
                                property StaggerWave entranceWave: tileWave

                                StaggerWave {
                                    id: tileWave
                                    target: pageGrid
                                    leadIn: 80
                                    step: 25
                                }
                                StaggerEntrance {
                                    target: pageGrid
                                    convergent: true
                                }

                                Repeater {
                                    model: pageModel
                                    delegate: AndroidToggleDelegateChooser {
                                        editMode: root.editMode
                                        gridRef: pageGrid
                                        dropIndicatorRef: pageDropIndicator
                                        pagerRef: root
                                        pageIndex: pageItem.index
                                        isUnused: false
                                        baseCellWidth: root.baseCellWidth
                                        baseCellHeight: root.baseCellHeight
                                        spacing: root.spacing
                                        onOpenAudioOutputDialog: root.openAudioOutputDialog()
                                        onOpenAudioInputDialog: root.openAudioInputDialog()
                                        onOpenBluetoothDialog: root.openBluetoothDialog()
                                        onOpenNightLightDialog: root.openNightLightDialog()
                                        onOpenWifiDialog: root.openWifiDialog()
                                        onOpenTailscaleDialog: root.openTailscaleDialog()
                                        onOpenPhoneTab: root.openPhoneTab()
                                    }
                                }

                                Rectangle {
                                    id: pageDropIndicator
                                    visible: false
                                    z: 99
                                    width: 3
                                    radius: Appearance.rounding.unsharpen
                                    color: Appearance.colors.colPrimary

                                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: -Appearance.spacing.space50
                                        width: 8; height: 8; radius: Appearance.rounding.full
                                        color: Appearance.colors.colPrimary
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -Appearance.spacing.space50
                                        width: 8; height: 8; radius: Appearance.rounding.full
                                        color: Appearance.colors.colPrimary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            DragHandler {
                id: swipeHandler
                target: null
                enabled: root.pageCount > 1 && !root.editMode
                xAxis.enabled: true
                yAxis.enabled: false
                property real startX: 0

                onActiveChanged: {
                    if (active) {
                        snapAnim.stop();
                        startX = pager.contentX;
                        return;
                    }
                    const moved = pager.contentX - startX;
                    const flung = activeTranslation.x === 0 ? 0
                        : (Math.abs(centroid.velocity.x) > 500
                            ? (centroid.velocity.x < 0 ? 1 : -1) : 0);
                    let step = root.currentPage;
                    if (flung !== 0) step += flung;
                    else if (moved > pager.width / 4) step += 1;
                    else if (moved < -pager.width / 4) step -= 1;
                    const page = QuickTogglePages.clampPage(root.pages, step);
                    if (page === root.currentPage) pager.snapTo(page);
                    else root.currentPage = page;
                }
                onTranslationChanged: {
                    if (!active) return;
                    const max = Math.max(0, pager.contentWidth - pager.width);
                    pager.contentX = Math.max(0, Math.min(max,
                        swipeHandler.startX - translation.x));
                }
            }
        }

        Row {
            visible: root.pageCount > 1 || root.editMode
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Appearance.spacing.space100

            Repeater {
                model: root.pageCount
                delegate: Rectangle {
                    id: dot
                    required property int index
                    readonly property bool current: dot.index === root.currentPage
                    anchors.verticalCenter: parent.verticalCenter
                    width: dot.current ? 18 : 6
                    height: 6
                    radius: Appearance.rounding.full
                    color: dot.current ? Appearance.colors.colPrimary
                                       : Appearance.colors.colOutlineVariant
                    Behavior on width {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Appearance.spacing.space50
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentPage = dot.index
                    }
                }
            }

            FadeLoader {
                shown: root.editMode
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: MaterialSymbol {
                    text: "add"
                    iconSize: 16
                    color: addArea.containsMouse ? Appearance.colors.colPrimary
                                                 : Appearance.colors.colOnLayer1
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                    MouseArea {
                        id: addArea
                        anchors.fill: parent
                        anchors.margins: -Appearance.spacing.space50
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const next = root.pageCount;
                            Config.options.sidebar.quickToggles.android.pages =
                                QuickTogglePages.withAddedPage(root.pages);
                            root.currentPage = next;
                        }
                    }
                }
            }
        }

        FadeLoader {
            shown: root.editMode
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: root.baseCellHeight / 2
                rightMargin: root.baseCellHeight / 2
            }
            sourceComponent: Rectangle {
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }
        }

        FadeLoader {
            shown: root.editMode
            sourceComponent: Item {
                id: unusedGrid
                width: contentItem.width
                implicitHeight: root.unusedGridHeight()

                Repeater {
                    model: unusedModel
                    delegate: AndroidToggleDelegateChooser {
                        editMode: root.editMode
                        gridRef: unusedGrid
                        isUnused: true
                        pagerRef: root
                        pageIndex: root.currentPage
                        baseCellWidth: root.baseCellWidth
                        baseCellHeight: root.baseCellHeight
                        spacing: root.spacing
                    }
                }
            }
        }

        ConfigSpinBox {
            visible: root.editMode
            width: parent.width
            enabled: Config.options.sidebar.quickToggles.style === "android"
            icon: "add_column_left"
            text: Translation.tr("Columns")
            value: Config.options.sidebar.quickToggles.android.columns
            from: 1
            to: 8
            stepSize: 1
            onValueModified: {
                Config.options.sidebar.quickToggles.android.columns = newValue;
            }
        }
    }
}
