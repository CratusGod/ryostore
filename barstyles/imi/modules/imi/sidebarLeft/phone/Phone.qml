import "../../../.."
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../phone"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property string pickedDeviceId: ""
    readonly property var device: PhoneConnect.devices.find(d => d.id === root.pickedDeviceId)
        ?? PhoneConnect.activeDevice
        ?? (PhoneConnect.devices[0] ?? null)
    readonly property bool online: root.device !== null
        && root.device.paired && root.device.reachable

    property bool rosterOpen: false
    property real rosterProgress: root.rosterOpen ? 1 : 0

    Behavior on rosterProgress {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    property string subPage: ""
    property string shownSubPage: ""
    property real subPageProgress: root.subPage !== "" ? 1 : 0

    Behavior on subPageProgress {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    onSubPageChanged: {
        if (root.subPage !== "")
            root.shownSubPage = root.subPage;
    }
    onSubPageProgressChanged: {
        if (root.subPageProgress === 0)
            root.shownSubPage = "";
    }

    function openSubPage(id: string): void {
        root.subPage = id;
    }

    function popSubPage(): void {
        root.subPage = "";
    }

    function subPageSource(id: string): string {
        switch (id) {
        case "contacts": return "PhoneContactsPage.qml";
        case "apps": return "PhoneAppsPage.qml";
        case "webcam": return "PhoneWebcamPage.qml";
        case "mic": return "PhoneMicPage.qml";
        default: return "";
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && root.subPage !== "") {
            root.popSubPage();
            event.accepted = true;
        }
    }


    ColumnLayout {
        id: phoneColumn
        anchors.fill: parent
        anchors.margins: Appearance.spacing.space125
        spacing: Appearance.spacing.space125

        readonly property real recedeTo: Appearance.animation.entranceScaleFrom(root.width)
        opacity: 1 - root.subPageProgress
        scale: 1 - (1 - phoneColumn.recedeTo) * root.subPageProgress
        transformOrigin: Item.Center
        enabled: root.subPage === ""

        StaggerWave {
            id: entrance
            target: phoneColumn
        }
        StaggerEntrance {
            target: phoneColumn
            reference: root.width
        }

        PhoneHeader {
            id: header
            Layout.fillWidth: true
            device: root.device
            rosterOpen: root.rosterOpen
            onToggleRoster: root.rosterOpen = !root.rosterOpen
        }

        Item {
            id: rosterReveal
            objectName: "rosterReveal"
            Layout.fillWidth: true
            Layout.preferredHeight: rosterGroup.implicitHeight * root.rosterProgress
            visible: root.rosterProgress > 0
            opacity: root.rosterProgress
            clip: true

            GroupedList {
                id: rosterGroup
                objectName: "rosterGroup"
                anchors { left: parent.left; right: parent.right; top: parent.top }
                model: PhoneConnect.devices
                rowDelegate: Component {
                    PhoneDeviceItem {
                        property var modelData: null
                        device: modelData
                        active: root.device !== null && modelData !== null
                            && root.device.id === modelData.id
                        onClicked: {
                            root.pickedDeviceId = modelData.id;
                            PhoneConnect.selectDevice(modelData.id);
                            root.rosterOpen = false;
                        }
                    }
                }
            }
        }

        PhoneActionsRow {
            id: actionsRow
            Layout.fillWidth: true
            device: root.device
        }

        PhoneNavCards {
            id: navCards
            Layout.fillWidth: true
            onOpenPage: pageId => root.openSubPage(pageId)
        }

        PhoneNotificationList {
            id: notificationList
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        PhoneFooterBar {
            id: footerBar
            Layout.fillWidth: true
            online: root.online
        }

        Repeater {
            model: ScriptModel {
                values: PhoneConnect.pairingRequests
            }
            delegate: PhonePairingCard {
                required property var modelData
                device: modelData
                Layout.fillWidth: true
            }
        }

        Loader {
            id: featureCardsLoader
            property real appear: 1
            Layout.fillWidth: true
            source: Qt.resolvedUrl("PhoneFeatureCards.qml")

            onLoaded: {
                if (featureCardsLoader.item?.openPage !== undefined)
                    featureCardsLoader.item.openPage.connect(root.openSubPage);
            }
        }
    }


    DropArea {
        id: shareDrop
        anchors.fill: parent
        enabled: root.online && PhoneConnect.canShare && root.subPage === ""

        onDropped: drop => {
            const urls = (drop.urls ?? []).map(url => String(url));
            if (urls.length === 0) return;
            PhoneConnect.shareUrls(root.device, urls);
            drop.accept(Qt.CopyAction);
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Appearance.colors.colPrimaryContainer
            opacity: shareDrop.containsDrag ? 0.9 : 0
            visible: opacity > 0

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.space100

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "upload_file"
                    iconSize: 56
                    color: Appearance.colors.colOnPrimaryContainer
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Drop the file here")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnPrimaryContainer
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Ready to send to %1").arg(root.device?.name ?? "")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }
    }


    Item {
        id: subPageHost
        anchors.fill: parent
        anchors.margins: Appearance.spacing.space125
        opacity: root.subPageProgress
        visible: opacity > 0

        Loader {
            id: subPageLoader
            width: parent.width
            height: parent.height
            x: (1 - root.subPageProgress) * root.width
            active: root.shownSubPage !== ""
            source: root.shownSubPage !== ""
                ? Qt.resolvedUrl(root.subPageSource(root.shownSubPage))
                : ""

            onLoaded: {
                if (subPageLoader.item?.back !== undefined)
                    subPageLoader.item.back.connect(root.popSubPage);
            }
        }
    }


    Rectangle {
        id: toast
        z: 9999
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.space150

        property string message: ""
        property bool ok: true

        readonly property real maxWidth: root.width - Appearance.spacing.space125 * 2
        readonly property real horizontalPadding: Appearance.spacing.space300

        implicitWidth: Math.min(toastRow.implicitWidth + toast.horizontalPadding, toast.maxWidth)
        implicitHeight: toastRow.implicitHeight + Appearance.spacing.space150
        radius: Appearance.rounding.full
        color: toast.ok ? Appearance.colors.colPrimaryContainer : Appearance.colors.colErrorContainer
        opacity: toastTimer.running ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Timer {
            id: toastTimer
            interval: 2800
        }

        RowLayout {
            id: toastRow
            anchors.centerIn: parent
            spacing: Appearance.spacing.space100

            MaterialSymbol {
                id: toastGlyph
                Layout.alignment: Qt.AlignVCenter
                text: toast.ok ? "check_circle" : "error"
                iconSize: Appearance.font.pixelSize.larger
                color: toast.ok ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnErrorContainer
            }
            StyledText {
                id: toastLabel
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: toast.maxWidth - toast.horizontalPadding
                    - toastGlyph.implicitWidth - toastRow.spacing
                text: toast.message
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.small
                color: toast.ok ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnErrorContainer
            }
        }
    }

    function showToast(message: string, ok: bool): void {
        if (!message)
            return;
        toast.message = message;
        toast.ok = ok;
        toastTimer.restart();
    }

    Connections {
        target: PhoneConnect
        function onActionFeedback(message: string, ok: bool): void {
            root.showToast(message, ok);
        }
    }

    Connections {
        target: PhoneScrcpy
        function onFeedback(message: string, ok: bool): void {
            root.showToast(message, ok);
        }
    }

    Connections {
        target: PhoneCamera
        function onErrorOccurred(message: string): void {
            root.showToast(message, false);
        }
    }

    Connections {
        target: PhoneMic
        function onErrorOccurred(message: string): void {
            root.showToast(message, false);
        }
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) {
                entrance.park();
                entrance.enter();
            }
        }
    }
}
