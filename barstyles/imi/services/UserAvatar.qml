pragma Singleton
import "../modules/common"
import "../modules/common/functions"
import QtQuick
import Quickshell
import Quickshell.Io
import "./avatar_source.js" as AvatarSource

Singleton {
    id: root

    property bool faceExists: false
    property bool faceIconExists: false

    readonly property string url: AvatarSource.resolve(
        Config.options.profile.avatarPath,
        Config.options.profile.avatarPicture,
        FileUtils.trimFileProtocol(Directories.home),
        root.faceExists,
        root.faceIconExists)

    Process {
        running: true
        command: ["bash", "-c", 'f=0; i=0; [ -f "$HOME/.face" ] && f=1; [ -f "$HOME/.face.icon" ] && i=1; echo "$f $i"']
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                root.faceExists = parts[0] === "1"
                root.faceIconExists = parts[1] === "1"
            }
        }
    }
}
