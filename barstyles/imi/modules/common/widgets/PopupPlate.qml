import ".."
import "."
import QtQuick

Item {
    id: root

    property real radius: Appearance.rounding.normal
    property color color: Appearance.colors.colLayer0
    property color colBorder: Appearance.colors.colLayer0Border
    property bool bordered: true
    property bool shadow: true
    readonly property alias plate: plate
    default property alias content: plate.data

    implicitWidth: plate.implicitWidth
    implicitHeight: plate.implicitHeight

    Rectangle {
        id: plate
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.width: root.bordered ? Appearance.borderWidth.standard : 0
        border.color: root.colBorder
    }

    Loader {
        z: -1
        active: root.shadow
        anchors.fill: parent
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: plate
            visible: plate.visible
            opacity: plate.opacity
        }
    }
}
