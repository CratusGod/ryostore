import QtQuick
import QtQuick.Layouts
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../../common/functions/edit_mode.js" as EditMode

Item {
    id: root

    property rect card: Qt.rect(0, 0, root.width, root.height)

    property rect area: Qt.rect(0, 0, root.width, root.height)

    property rect drawer: Qt.rect(root.width, 0, 0, root.height)

    signal doneRequested()
    signal drawerToggleRequested()
    signal snapToggleRequested()
    signal widgetDropRequested(var manifest, real dropX, real dropY)
    signal widgetToggleRequested(var manifest)
    signal barWidgetAddRequested(string widgetId, string bucket)
    signal dockAppToggleRequested(string appId)
    signal lockIslandToggleRequested(string key)
    signal lockWidgetToggleRequested(string pluginId)
    signal lockLayoutResetRequested()
    signal lockPresenceResetRequested()

    property real bandFraction: 0.5

    property string screenName: ""

    readonly property alias toolbarItem: toolbar
    readonly property alias tabBarItem: tabBar
    readonly property alias drawerItem: drawerPanel

    Toolbar {
        id: toolbar
        x: root.card.x + (root.card.width - width) / 2
        y: root.area.y + (root.card.y - root.area.y - height) * root.bandFraction
        spacing: Appearance.spacing.space150

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Appearance.spacing.space100
            text: Translation.tr("Edit layout")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colOnSurfaceVariant
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Appearance.spacing.space50
            Layout.rightMargin: Appearance.spacing.space50
            implicitWidth: 1
            implicitHeight: Math.round(Appearance.sizes.toolbarHeight * 0.4)
            color: Appearance.colors.colOutlineVariant
        }

        IconAndTextToolbarButton {
            id: drawerButton
            Layout.alignment: Qt.AlignVCenter
            iconText: "widgets"
            text: Translation.tr("Add widgets")
            toggled: GlobalStates.editDrawerOpen
            onClicked: root.drawerToggleRequested()
        }

        IconToolbarButton {
            id: snapButton
            Layout.alignment: Qt.AlignVCenter
            text: "align_horizontal_left"
            toggled: Config.options.background.showSnapLines
            onClicked: root.snapToggleRequested()
            StyledToolTip {
                text: Config.options.background.showSnapLines
                    ? Translation.tr("Edge snapping on")
                    : Translation.tr("Edge snapping off")
            }
        }

        IconAndTextToolbarButton {
            id: doneButton
            Layout.alignment: Qt.AlignVCenter
            iconText: "done"
            text: Translation.tr("Done")
            colBackground: Appearance.colors.colPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
            colRipple: Appearance.colors.colPrimaryActive
            colText: Appearance.colors.colOnPrimary
            onClicked: root.doneRequested()
        }
    }

    Toolbar {
        id: tabBar
        x: root.card.x + (root.card.width - width) / 2
        y: root.card.y + root.card.height
            + (root.area.y + root.area.height - root.card.y - root.card.height - height)
                * (1 - root.bandFraction)

        ToolbarTabBar {
            id: tabs
            tabButtonList: [
                { name: Translation.tr("Desktop"), icon: "wallpaper" },
                { name: Translation.tr("Lockscreen"), icon: "lock" }
            ]
            onCurrentIndexChanged: GlobalStates.editTab = EditMode.tabAt(tabs.currentIndex)
            Component.onCompleted: tabs.setCurrentIndex(EditMode.tabIndex(GlobalStates.editTab))
            Connections {
                target: GlobalStates
                function onEditTabChanged() {
                    tabs.setCurrentIndex(EditMode.tabIndex(GlobalStates.editTab));
                }
            }
        }
    }

    StyledRectangularShadow {
        target: drawerPanel
        visible: drawerPanel.width > 0
        radius: Appearance.rounding.verylarge
    }

    EditModeDrawer {
        id: drawerPanel
        x: root.drawer.x
        y: root.drawer.y
        width: root.drawer.width
        height: root.drawer.height
        ghostParent: root
        onAddRequested: (manifest, dropX, dropY) => root.widgetDropRequested(manifest, dropX, dropY)
        onToggleRequested: (manifest) => root.widgetToggleRequested(manifest)
        onBarAddRequested: (widgetId, bucket) => root.barWidgetAddRequested(widgetId, bucket)
        onDockToggleRequested: (appId) => root.dockAppToggleRequested(appId)
        onLockToggleRequested: (key) => root.lockIslandToggleRequested(key)
        onLockWidgetToggleRequested: (pluginId) => root.lockWidgetToggleRequested(pluginId)
        onLockLayoutResetRequested: root.lockLayoutResetRequested()
        onLockPresenceResetRequested: root.lockPresenceResetRequested()
        screenName: root.screenName
    }
}
