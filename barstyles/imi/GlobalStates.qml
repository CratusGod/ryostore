import "modules/common"
import "services"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "modules/common/functions/edit_mode.js" as EditMode
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property string sidebarLeftTab: ""
    property string sidebarLeftTabIcon: ""
    property bool sidebarRightOpen: false
    property string sidebarRightDialog: ""
    property bool mediaControlsOpen: false
    property bool sysTrayOverflowOpen: false
    property bool screensaverActive: false
    property var screensaverScreens: []
    property bool osdBrightnessOpen: false
    property bool settingsOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool settingsHeldForRegionSelector: false
    property bool clockDepthSelectOpen: false
    property var clockDepthViewports: ({})
    property bool snipCopyInFlight: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false
    property string settingsPage: ""
    property Item currentPageInstance: null
    property bool desktopWidgetKeyboardFocus: false
    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0
    property string wallpaperSelectorTarget: "wallpaper"
    property var activeBarPopup: null
    property var activeComboBox: null
    property bool editMode: false
    property real editProgress: root.editMode ? 1 : 0
    Behavior on editProgress {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    property string editTab: EditMode.DESKTOP_TAB
    readonly property bool editLockPreview: root.editMode
        && root.editTab === EditMode.LOCKSCREEN_TAB

    readonly property bool lockLookActive: root.screenLocked || root.editLockPreview

    property bool editDrawerOpen: false
    property real editDrawerProgress: root.editMode && root.editDrawerOpen ? 1 : 0
    Behavior on editDrawerProgress {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    property var editDrawerReveals: ({})
    property string editDrawerDropScreen: ""
    signal editWidgetDroppedOnDrawer(string pluginId)

    property bool editWidgetMenuOpen: false
    property string editWidgetMenuScreenName: ""
    property real editWidgetMenuX: 0
    property real editWidgetMenuY: 0
    property string editWidgetMenuPluginId: ""

    property bool editBarDragActive: false
    property bool editLockDragActive: false
    signal editReorderCancel()

    property var editUndoStack: []
    property var editUndoBatch: null
    function editUndoBeginBatch() {
        if (root.editUndoBatch === null) root.editUndoBatch = [];
    }
    function editUndoEndBatch() {
        const entries = root.editUndoBatch;
        root.editUndoBatch = null;
        if (entries === null || entries.length === 0) return;
        if (entries.length === 1) {
            root.editUndoStack = EditMode.undoPush(root.editUndoStack, entries[0]);
            return;
        }
        root.editUndoStack = EditMode.undoPush(root.editUndoStack, () => {
            for (let index = entries.length - 1; index >= 0; index--) entries[index]();
        });
    }
    function editUndoPush(entry) {
        if (!root.editMode) return;
        if (root.editUndoBatch !== null) {
            root.editUndoBatch.push(entry);
            return;
        }
        root.editUndoStack = EditMode.undoPush(root.editUndoStack, entry);
    }
    function editUndo() {
        const popped = EditMode.undoPop(root.editUndoStack);
        root.editUndoStack = popped.stack;
        if (popped.entry !== null) popped.entry();
    }

    property bool dropShelfOpen: false
    property real dropShelfX: 0
    property real dropShelfY: 0
    property bool dropShelfAnchorBelow: false

    onScreenLockedChanged: if (root.screenLocked) root.editMode = false
    onOverviewOpenChanged: if (root.overviewOpen) root.editMode = false
    onSessionOpenChanged: if (root.sessionOpen) root.editMode = false

    onEditModeChanged: {
        if (root.editMode) {
            root.clockDepthSelectOpen = false;
            root.activeBarPopup = null;
            root.sidebarLeftOpen = false;
            root.sidebarRightOpen = false;
        }
        else {
            root.editDrawerOpen = false;
            root.editWidgetMenuOpen = false;
            root.editTab = EditMode.DESKTOP_TAB;
            root.editBarDragActive = false;
            root.editLockDragActive = false;
            root.editDrawerDropScreen = "";
        }
    }
    onClockDepthSelectOpenChanged: if (root.clockDepthSelectOpen) root.editMode = false

    onSidebarLeftOpenChanged: {
        if (root.sidebarLeftOpen && root.editMode)
            root.sidebarLeftOpen = false;
    }

    onSidebarRightOpenChanged: {
        if (root.sidebarRightOpen && root.editMode) {
            root.sidebarRightOpen = false;
            return;
        }
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"
        onPressed: { root.superDown = true }
        onReleased: { root.superDown = false }
    }
}
