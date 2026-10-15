import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../phone"
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var device: null
    readonly property bool online: root.device !== null
        && root.device.paired && root.device.reachable

    property real appear: 1

    implicitHeight: actionRow.implicitHeight

    RowLayout {
        id: actionRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.space100

        PhoneActionButton {
            id: ringButton
            glyph: "phone_in_talk"
            label: Translation.tr("Ring phone")
            enabled: root.online
            onClicked: PhoneConnect.ring(root.device)
        }
        PhoneActionButton {
            id: pingButton
            glyph: "notifications_active"
            label: Translation.tr("Send a ping")
            enabled: root.online && PhoneConnect.canPing
            onClicked: PhoneConnect.ping(root.device)
        }
        PhoneActionButton {
            id: clipboardButton
            glyph: "content_paste"
            label: Translation.tr("Send clipboard to phone")
            enabled: root.online && PhoneConnect.canSendClipboard
            onClicked: PhoneConnect.sendClipboard(root.device)
        }
        PhoneActionButton {
            id: sendFileButton
            glyph: "file_upload"
            label: Translation.tr("Send file…")
            enabled: root.online && PhoneConnect.canShare
            onClicked: PhoneConnect.pickAndSendFiles(root.device)
        }
        PhoneActionButton {
            id: shareClipboardButton
            glyph: "link"
            label: Translation.tr("Share clipboard as a link or text")
            enabled: root.online && PhoneConnect.canShare
            onClicked: PhoneConnect.shareClipboard(root.device)
        }
        PhoneActionButton {
            id: browseFilesButton
            glyph: "folder_shared"
            label: Translation.tr("Browse phone files")
            enabled: root.online && PhoneConnect.canBrowseFiles
            onClicked: PhoneConnect.browseFiles(root.device)
        }
    }
}
