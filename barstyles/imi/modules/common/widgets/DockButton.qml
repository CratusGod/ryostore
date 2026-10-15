import ".."
import "."
import QtQuick
import QtQuick.Layouts
import "../../imi/dock/dock_geometry.js" as DockGeometry

RippleButton {
    id: root

    readonly property string dockEdge: DockGeometry.normalizedEdge(
        Config.options?.dock.edge ?? "bottom")
    readonly property bool dockVertical: DockGeometry.isVertical(root.dockEdge)

    property real insetInward: 0
    property real insetOutward: 0
    readonly property var dockInsets: DockGeometry.directedSides(
        root.dockEdge, root.insetInward, root.insetOutward)
    topInset: root.dockInsets.top
    bottomInset: root.dockInsets.bottom
    leftInset: root.dockInsets.left
    rightInset: root.dockInsets.right

    property real crossMargin: Appearance.sizes.elevationMargin - Appearance.sizes.hyprlandGapsOut
    readonly property var dockCrossMargins: DockGeometry.directedSides(
        root.dockEdge, root.crossMargin, 0)
    Layout.topMargin: root.dockCrossMargins.top
    Layout.bottomMargin: root.dockCrossMargins.bottom
    Layout.leftMargin: root.dockCrossMargins.left
    Layout.rightMargin: root.dockCrossMargins.right

    Layout.fillHeight: !root.dockVertical
    Layout.fillWidth: root.dockVertical

    property real span: 50
    implicitWidth: root.dockVertical ? root.span + leftInset + rightInset : root.span
    implicitHeight: root.dockVertical ? root.span : root.span + topInset + bottomInset

    buttonRadius: Appearance.rounding.normal
}
