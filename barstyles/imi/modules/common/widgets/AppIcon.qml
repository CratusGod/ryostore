pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../../../services"
import ".."

IconImage {
    id: root

    property real implicitSize: 26
    property bool animated: false

    implicitWidth: implicitSize
    implicitHeight: implicitSize
}
