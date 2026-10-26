pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    readonly property bool enabled: HostState.flags !== null ? HostState.flags.keepAwake : props.enabled
    readonly property date enabledSince: HostState.flags !== null
        ? new Date(HostState.flags.keepAwakeSince) : props.enabledSince

    function setEnabled(value: bool): void {
        if (HostState.flags !== null)
            HostState.flags.keepAwake = value;
        else
            props.enabled = value;
    }

    function toggle(): void {
        setEnabled(!enabled);
    }

    onEnabledChanged: {
        if (enabled && HostState.flags === null)
            props.enabledSince = new Date();
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    IdleInhibitor {
        enabled: HostState.flags === null && props.enabled
        window: PanelWindow {
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.setEnabled(true);
        }

        function disable(): void {
            root.setEnabled(false);
        }

        target: "idleInhibitor"
    }
}
