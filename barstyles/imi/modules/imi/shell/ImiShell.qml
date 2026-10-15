pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "../sidebarLeft"
import "../sidebarRight"
import "../../.."

Scope {
    id: root

    IpcHandler {
        target: "imi"

        function toggle(): void { GlobalStates.settingsOpen = !GlobalStates.settingsOpen; }
        function open(): void { GlobalStates.settingsOpen = true; }
        function close(): void { GlobalStates.settingsOpen = false; }
        function page(target: string): void {
            GlobalStates.settingsOpen = true;
            Qt.callLater(() => { GlobalStates.settingsPage = String(target); });
        }

        function toggleSidebarRight(): void { GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen; }
        function openSidebarRight(): void { GlobalStates.sidebarRightOpen = true; }
        function closeSidebarRight(): void { GlobalStates.sidebarRightOpen = false; }

        function toggleLeft(): void { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen; }
        function openLeft(): void { GlobalStates.sidebarLeftOpen = true; }
        function closeLeft(): void { GlobalStates.sidebarLeftOpen = false; }
        function tab(id: string): void {
            GlobalStates.sidebarLeftTab = String(id);
            GlobalStates.sidebarLeftOpen = true;
        }

        function ping(): string { return "imi alive"; }
    }

    ImiSettingsLayer {}
    SidebarLeft {}
    SidebarRight {}
}
