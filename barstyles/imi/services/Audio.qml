pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services as RyokuServices

Singleton {
    id: root

    readonly property var sink: RyokuServices.Audio.sink
    readonly property var source: RyokuServices.Audio.source
    readonly property real hardMaxValue: 2.0
    readonly property real value: root.sink?.audio?.volume ?? 0

    readonly property var outputAppNodes: RyokuServices.Audio.streams
    readonly property var inputAppNodes: RyokuServices.Audio.captureStreams
    readonly property var outputDevices: RyokuServices.Audio.outputs
    readonly property var inputDevices: RyokuServices.Audio.inputs

    function toggleMute() {
        if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted;
    }

    function toggleMicMute() {
        if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted;
    }

    function friendlyDeviceName(node) {
        return RyokuServices.Audio.nodeLabel(node);
    }

    function appNodeDisplayName(node) {
        return RyokuServices.Audio.streamName(node);
    }

    function setDefaultSink(node) {
        RyokuServices.Audio.setOutput(node);
    }

    function setDefaultSource(node) {
        RyokuServices.Audio.setInput(node);
    }
}
