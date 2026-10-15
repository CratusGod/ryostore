import "../../.."
import "../../../services"
import "phone"
import "../../common"
import "../../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property int sidebarPadding: Appearance.spacing.space125
    anchors.fill: parent
    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property bool mediaEnabled: Config.options.sidebar.media.enable
    property bool phoneEnabled: Config.options.sidebar.phone.enable
    property var tabButtonList: [
        ...(root.aiChatEnabled ? [{"icon": "star_shine", "name": Translation.tr("Intelligence")}] : []),
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...(root.mediaEnabled ? [{"icon": "music_note", "name": Translation.tr("Media")}] : []),
        ...(root.phoneEnabled ? [{"icon": "smartphone", "name": Translation.tr("Phone")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : [])
    ]
    property int tabCount: swipeView.count

    property var tabIdList: [
        ...(root.aiChatEnabled ? ["intelligence"] : []),
        ...(root.translatorEnabled ? ["translator"] : []),
        ...(root.mediaEnabled ? ["media"] : []),
        ...(root.phoneEnabled ? ["phone"] : []),
        ...((root.animeEnabled && !root.animeCloset) ? ["anime"] : [])
    ]

    readonly property Item backgroundItem: sidebarLeftBackground

    function showTab(id) {
        const index = root.tabIdList.indexOf(id);
        if (index < 0) return;
        swipeView.currentIndex = index;
    }

    function consumeTabRequest() {
        if (GlobalStates.sidebarLeftTab === "") return;
        root.showTab(GlobalStates.sidebarLeftTab);
        GlobalStates.sidebarLeftTab = "";
    }

    function focusActiveItem() {
        swipeView.currentItem?.forceActiveFocus();
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    Component.onCompleted: {
        if (GlobalStates.sidebarLeftOpen)
            Qt.callLater(() => {
                if (GlobalStates.sidebarLeftOpen) {
                    root.runEntrance();
                    root.focusActiveItem();
                }
            });
        root.consumeTabRequest();
    }

    function runEntrance() {
        leftEntrance.park();
        leftEntrance.enter();
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) {
                root.consumeTabRequest();
                root.runEntrance();
                root.focusActiveItem();
            }
        }
        function onSidebarLeftTabChanged() {
            if (GlobalStates.sidebarLeftOpen) {
                root.consumeTabRequest();
                root.focusActiveItem();
            }
        }
    }

    implicitHeight: sidebarLeftBackground.implicitHeight
    implicitWidth: sidebarLeftBackground.implicitWidth

    PopupPlate {
        id: sidebarLeftBackground
        anchors.fill: parent
        implicitHeight: parent.height
        implicitWidth: parent.width
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 5

        ColumnLayout {
            id: leftColumn
            anchors {
                fill: parent
                margins: sidebarPadding
            }
            spacing: verticalTabBar.expanded ? -Appearance.spacing.space25 : 0

            StaggerWave {
                id: leftEntrance
                target: leftColumn
            }
            StaggerEntrance {
                target: leftColumn
                reference: root.width
            }

            VerticalTabBar {
                id: verticalTabBar
                property real appear: 1
                visible: tabButtonList.length > 0
                Layout.fillWidth: true
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
                onCurrentIndexRequested: index => {
                    swipeView.currentIndex = Math.max(0, Math.min(swipeView.count - 1, index));
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: swipeView.implicitWidth
                implicitHeight: swipeView.implicitHeight
                topLeftRadius: 0
                bottomLeftRadius: Appearance.rounding.normal
                topRightRadius: 0
                bottomRightRadius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                SwipeView {
                    id: swipeView
                    anchors.fill: parent
                    spacing: Appearance.spacing.space150

                    onCurrentIndexChanged: GlobalStates.sidebarLeftTabIcon =
                        root.tabButtonList[swipeView.currentIndex]?.icon ?? ""
                    Component.onCompleted: GlobalStates.sidebarLeftTabIcon =
                        root.tabButtonList[swipeView.currentIndex]?.icon ?? ""

                    clip: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: swipeView.width
                            height: swipeView.height
                            radius: Appearance.rounding.small
                        }
                    }

                    contentChildren: [
                        ...(root.aiChatEnabled ? [aiChat.createObject()] : []),
                        ...(root.translatorEnabled ? [translator.createObject()] : []),
                        ...(root.mediaEnabled ? [media.createObject()] : []),
                        ...(root.phoneEnabled ? [phone.createObject()] : []),
                        ...((root.tabButtonList.length === 0 || (!root.aiChatEnabled && !root.translatorEnabled && root.animeCloset)) ? [placeholder.createObject()] : []),
                        ...(root.animeEnabled ? [anime.createObject()] : []),
                    ]
                }
            }

            Component {
                id: aiChat
                AiChat {}
            }
            Component {
                id: translator
                Translator {}
            }
            Component {
                id: media
                SidebarPlayerControl {}
            }
            Component {
                id: phone
                Phone {}
            }
            Component {
                id: anime
                Anime {}
            }
            Component {
                id: placeholder
                Item {
                    StyledText {
                        anchors.centerIn: parent
                        text: root.animeCloset ? Translation.tr("Nothing") : Translation.tr("Enjoy your empty sidebar...")
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
