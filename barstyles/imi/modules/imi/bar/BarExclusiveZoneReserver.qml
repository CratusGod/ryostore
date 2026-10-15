import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../common"

PanelWindow {
    id: reserver

    property real zone: 0
    property real edgeMargin: 0
    property bool vertical: false
    property bool farEdge: false
    required property string barNamespace

    WlrLayershell.namespace: reserver.barNamespace
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: reserver.vertical ? true : !reserver.farEdge
        bottom: reserver.vertical ? true : reserver.farEdge
        left: reserver.vertical ? !reserver.farEdge : true
        right: reserver.vertical ? reserver.farEdge : true
    }
    implicitWidth: 1
    implicitHeight: 1

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Math.round(reserver.animatedZone)

    readonly property real settledZone: reserver.zone > 0 ? reserver.zone + reserver.edgeMargin : 0
    property real animatedZone: reserver.settledZone
    Behavior on animatedZone {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(reserver)
    }

    color: "transparent"
    mask: Region {}
}
