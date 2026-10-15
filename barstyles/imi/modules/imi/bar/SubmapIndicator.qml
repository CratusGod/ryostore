import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../common"
import "../../common/widgets"

Item {
    id: root

    property bool vertical: false

    readonly property bool shown: Boolean(HyprlandSubmap.active)

    readonly property string submapName: HyprlandSubmap.submapName ?? ""
    property string displayName: ""
    onSubmapNameChanged: {
        if (root.submapName.length > 0 && root.submapName !== "global")
            root.displayName = root.submapName;
    }

    readonly property color pillColor: Appearance.colors.colTertiary
    readonly property color onColor: Appearance.colors.colOnTertiary

    visible: implicitWidth > 0
    implicitWidth: shown ? (vertical ? Appearance.sizes.verticalBarWidth : pill.implicitWidth) : 0
    implicitHeight: vertical ? pill.implicitHeight : Appearance.sizes.barHeight
    Behavior on implicitWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.vertical ? 0 : Appearance.sizes.barStandalonePillOffset
        anchors.horizontalCenterOffset: root.vertical ? Appearance.sizes.barStandalonePillOffset : 0
        radius: Appearance.rounding.full
        color: root.pillColor
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.7
        transformOrigin: Item.Center
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on scale {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        implicitWidth: root.vertical
            ? verticalIcon.implicitWidth + Appearance.spacing.space50 * 2
            : pillRow.implicitWidth + Appearance.spacing.space150 * 2
        implicitHeight: root.vertical
            ? verticalIcon.implicitHeight + Appearance.spacing.space50 * 2
            : Appearance.sizes.barStandalonePillHeight

        RowLayout {
            id: pillRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Appearance.spacing.space50
            MaterialSymbol {
                text: "keyboard"
                iconSize: Appearance.font.pixelSize.large
                color: root.onColor
            }
            StyledText {
                text: root.displayName
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: root.onColor
            }
        }

        MaterialSymbol {
            id: verticalIcon
            visible: root.vertical
            anchors.centerIn: parent
            text: "keyboard"
            iconSize: Appearance.font.pixelSize.large
            color: root.onColor
        }
    }
}
