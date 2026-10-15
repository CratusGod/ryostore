pragma ComponentBehavior: Bound
import "../../../../.."
import "../../../../../services"
import "../../../../common"
import "../../../../common/widgets"
import "../../../../common/functions/quick_toggle_pages.js" as QuickTogglePages
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

DelegateChooser {
    id: root
    property bool editMode: false
    required property real baseCellWidth
    required property real baseCellHeight
    required property real spacing
    property var dropIndicatorRef: null 
    property bool isUnused: false
    property var gridRef: null 
    property var pagerRef: null
    property int pageIndex: 0
    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()
    signal openTailscaleDialog()
    signal openPhoneTab()

    function currentPages() {
        return QuickTogglePages.normalise(
            Config.options.sidebar.quickToggles.android.pages,
            Config.options.sidebar.quickToggles.android.toggles);
    }
    function writePages(next) {
        Config.options.sidebar.quickToggles.android.pages = next;
    }
    function moveToggle(fromIndex, toIndex) {
        writePages(QuickTogglePages.withMove(currentPages(),
            root.pageIndex, fromIndex, root.pageIndex, toIndex));
    }
    function moveToggleAcross(fromIndex, toPage, toIndex) {
        writePages(QuickTogglePages.withMove(currentPages(),
            root.pageIndex, fromIndex, toPage, toIndex));
    }
    function addToggle(type) {
        writePages(QuickTogglePages.withInsert(currentPages(),
            root.pageIndex, { type: type, size: 1 }));
    }
    function removeToggle(index) {
        writePages(QuickTogglePages.withRemove(currentPages(), root.pageIndex, index));
    }
    function resizeToggle(index, size) {
        writePages(QuickTogglePages.withResize(currentPages(), root.pageIndex, index, size));
    }

    role: "type"



    DelegateChoice { roleValue: "audio"; AndroidAudioToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
        onOpenMenu: root.openAudioOutputDialog()
    } }

    DelegateChoice { roleValue: "bluetooth"; AndroidBluetoothToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
        onOpenMenu: root.openBluetoothDialog()
    } }


    DelegateChoice { roleValue: "phoneConnect"; AndroidPhoneConnectToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
        onOpenMenu: root.openPhoneTab()
    } }






    DelegateChoice { roleValue: "gameMode"; AndroidGameModeToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
    } }

    DelegateChoice { roleValue: "idleInhibitor"; AndroidIdleInhibitorToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
    } }

    DelegateChoice { roleValue: "mic"; AndroidMicToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        onOpenMenu: root.openAudioInputDialog()
    } }


    DelegateChoice { roleValue: "network"; AndroidNetworkToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        onOpenMenu: root.openWifiDialog()
    } }

    DelegateChoice { roleValue: "nightLight"; AndroidNightLightToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        onOpenMenu: root.openNightLightDialog()
    } }

    DelegateChoice { roleValue: "notifications"; AndroidNotificationToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
    } }


    DelegateChoice { roleValue: "powerProfile"; AndroidPowerProfileToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
    } }

    DelegateChoice { roleValue: "screenSnip"; AndroidScreenSnipToggle {
        required property int index
        required property var modelData
        buttonIndex: modelData.sourceIndex
        buttonData: modelData
        editMode: root.editMode
        gridRef: root.gridRef
        expandedSize: modelData.size > 1
        baseCellWidth: root.baseCellWidth
        baseCellHeight: root.baseCellHeight
        cellSpacing: root.spacing
        cellSize: modelData.size
        dropIndicatorRef: root.dropIndicatorRef
        pagerRef: root.pagerRef
        pageIndex: root.pageIndex
        isUnused: root.isUnused
        panelOpen: GlobalStates.sidebarRightOpen
        onMoveRequested: (fromIndex, toIndex) => root.moveToggle(fromIndex, toIndex)
        onMoveAcrossRequested: (fromIndex, toPage, toIndex) => root.moveToggleAcross(fromIndex, toPage, toIndex)
        onAddRequested: type => root.addToggle(type)
        onRemoveRequested: index => root.removeToggle(index)
        onResizeRequested: (index, size) => root.resizeToggle(index, size)
    } }
}