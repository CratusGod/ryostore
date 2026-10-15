import ".."
import "../functions"
import QtQuick
import QtQuick.Layouts
import "../../imi/dock/dock_geometry.js" as DockGeometry

Rectangle {
    id: root

    readonly property string dockEdge: DockGeometry.normalizedEdge(
        Config.options?.dock.edge ?? "bottom")
    readonly property bool dockVertical: DockGeometry.isVertical(root.dockEdge)

    readonly property var dockMargins: DockGeometry.directedSides(
        root.dockEdge,
        Appearance.sizes.elevationMargin + dockRow.padding + Appearance.rounding.normal - 4,
        Appearance.sizes.hyprlandGapsOut + dockRow.padding + Appearance.rounding.normal)

    Layout.topMargin: root.dockMargins.top
    Layout.bottomMargin: root.dockMargins.bottom
    Layout.leftMargin: root.dockMargins.left
    Layout.rightMargin: root.dockMargins.right

    Layout.fillHeight: !root.dockVertical
    Layout.fillWidth: root.dockVertical
    implicitWidth: root.dockVertical ? 0 : 1
    implicitHeight: root.dockVertical ? 1 : 0

    color: Appearance.colors.colOutlineVariant
}
