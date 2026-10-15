import "../../common"
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property var artUrl: ""
    readonly property string artFilePath: `${Directories.coverArt}/${Qt.md5(String(root.artUrl ?? ""))}`
    property bool downloaded: false

    readonly property string displayedArtFilePath: {
        if (!root.downloaded) return ""
        const url = String(root.artUrl ?? "")
        if (url.startsWith("file://")) return url
        return Qt.resolvedUrl(root.artFilePath)
    }
    readonly property var colors: colorQuantizer.colors

    onArtUrlChanged: root.refresh()
    Component.onCompleted: root.refresh()
    function refresh() {
        const url = String(root.artUrl ?? "")
        if (url.length === 0) { root.downloaded = false; return }
        if (url.startsWith("file://")) { root.downloaded = true; return }
        downloader.targetFile = url
        downloader.filePath = root.artFilePath
        root.downloaded = false
        downloader.running = true
    }

    Process {
        id: downloader
        property string targetFile
        property string filePath
        command: ["bash", "-c", 'mkdir -p "$(dirname "$1")"; [ -f "$1" ] || curl -4 -fsSL "$2" -o "$1"', "bash", filePath, targetFile]
        onExited: (exitCode, exitStatus) => root.downloaded = exitCode === 0
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }
}
