import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../functions"
import "."

Rectangle {
    readonly property real cardBleed: parent?.contentPadding ?? 0

    implicitHeight: 1
    color: Appearance.colors.colOutline
    Layout.fillWidth: true
    Layout.leftMargin: -cardBleed
    Layout.rightMargin: -cardBleed
    Layout.topMargin: -Appearance.spacing.space100
    Layout.bottomMargin: -Appearance.spacing.space100
}
