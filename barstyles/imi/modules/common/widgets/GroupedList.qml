import ".."
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    default property list<Item> items
    property var model: null
    property Component rowDelegate: null
    readonly property bool modelDriven: root.rowDelegate !== null
    property real bigRadius: Appearance.rounding.normal
    property real smallRadius: Appearance.rounding.unsharpenmore
    property bool cohesive: false
    property color bgcolor: Appearance.colors.colLayer1
    property real itemVerticalPadding: Appearance.spacing.space300
    readonly property real selfSurfacedInset: Appearance.spacing.space75
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    readonly property var drawnIndices: {
        const drawn = [];
        if (root.modelDriven) {
            const count = root.model?.length ?? 0;
            for (let i = 0; i < count; i++)
                drawn.push(i);
            return drawn;
        }
        for (let i = 0; i < root.items.length; i++) {
            const item = root.items[i];
            if (item && (item.rowVisible ?? true))
                drawn.push(i);
        }
        return drawn;
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: root.cohesive ? 0 : Appearance.spacing.space25

        Repeater {
            model: root.modelDriven ? root.model : root.items.length
            delegate: Rectangle {
                id: plate
                required property int index
                required property var modelData
                readonly property bool isFirst: index === root.drawnIndices[0]
                readonly property bool isLast: index === root.drawnIndices[root.drawnIndices.length - 1]
                visible: root.drawnIndices.indexOf(index) !== -1
                Layout.fillWidth: true
                implicitHeight: (root.modelDriven
                    ? (rowLoader.item?.implicitHeight ?? 0)
                    : (root.items[index]?.implicitHeight ?? 0))
                    + (ownsItsSurface ? root.selfSurfacedInset * 2 : root.itemVerticalPadding)
                readonly property bool ownsItsSurface: rowLoader.item?.cornerTopLeft !== undefined
                color: "transparent"

                readonly property var rowControl: {
                    const item = root.modelDriven ? rowLoader.item : root.items[index];
                    return item && item.interactionMotion !== undefined && item.startRipple !== undefined
                        && !plate.ownsItsSurface ? item : null;
                }
                onRowControlChanged: {
                    if (!plate.rowControl) return;
                    plate.rowControl.rippleEnabled = false;
                    plate.rowControl.interactionMotionEnabled = false;
                }
                transform: Scale {
                    origin.x: plate.width / 2
                    origin.y: plate.height / 2
                    xScale: surface.interactionMotion.scale
                    yScale: surface.interactionMotion.scale
                }
                RippleButton {
                    id: surface
                    anchors.fill: parent
                    z: -1
                    transform: []
                    colBackground: plate.ownsItsSurface ? "transparent" : root.bgcolor
                    colBackgroundHover: plate.ownsItsSurface ? "transparent" : root.bgcolor
                    cornerTopLeft: plate.topLeftRadius
                    cornerTopRight: plate.topRightRadius
                    cornerBottomLeft: plate.bottomLeftRadius
                    cornerBottomRight: plate.bottomRightRadius
                    rippleEnabled: plate.rowControl !== null
                    interactionMotionEnabled: plate.rowControl !== null
                    interactionMotion.hovered: surface.interactionMotionEnabled
                        && (surface.hovered || (plate.rowControl?.hovered ?? false))
                    interactionMotion.down: surface.interactionMotionEnabled
                        && (surface.down || (plate.rowControl?.down ?? false))
                    onClicked: plate.rowControl?.clicked()
                    Connections {
                        target: plate.rowControl
                        function onDownChanged() {
                            if (plate.rowControl.down) {
                                const at = surface.mapFromItem(plate.rowControl,
                                    plate.rowControl.pressPoint.x, plate.rowControl.pressPoint.y);
                                surface.startRipple(at.x, at.y);
                            } else {
                                surface.fadeRipple();
                            }
                        }
                    }
                }
                topLeftRadius:     isFirst ? root.bigRadius : (root.cohesive ? 0 : root.smallRadius)
                topRightRadius:    isFirst ? root.bigRadius : (root.cohesive ? 0 : root.smallRadius)
                bottomLeftRadius:  isLast  ? root.bigRadius : (root.cohesive ? 0 : root.smallRadius)
                bottomRightRadius: isLast  ? root.bigRadius : (root.cohesive ? 0 : root.smallRadius)

                Component.onCompleted: {
                    if (root.modelDriven)
                        return;
                    const child = root.items[index]
                    if (child) {
                        child.parent = contentArea
                        child.Layout.fillWidth = true
                    }
                }

                ColumnLayout {
                    id: contentArea
                    anchors { fill: parent; margins: ownsItsSurface ? root.selfSurfacedInset : Appearance.spacing.space100 }
                    spacing: 0

                    Loader {
                        id: rowLoader
                        active: root.modelDriven
                        Layout.fillWidth: true
                        sourceComponent: root.rowDelegate
                    }
                }

                Binding {
                    target: rowLoader.item
                    property: "modelData"
                    value: plate.modelData
                    when: rowLoader.item !== null
                }
                Binding {
                    target: rowLoader.item
                    property: "cornerTopLeft"
                    value: plate.topLeftRadius
                    when: rowLoader.item?.cornerTopLeft !== undefined
                }
                Binding {
                    target: rowLoader.item
                    property: "cornerTopRight"
                    value: plate.topRightRadius
                    when: rowLoader.item?.cornerTopRight !== undefined
                }
                Binding {
                    target: rowLoader.item
                    property: "cornerBottomLeft"
                    value: plate.bottomLeftRadius
                    when: rowLoader.item?.cornerBottomLeft !== undefined
                }
                Binding {
                    target: rowLoader.item
                    property: "cornerBottomRight"
                    value: plate.bottomRightRadius
                    when: rowLoader.item?.cornerBottomRight !== undefined
                }
            }
        }
    }
}
