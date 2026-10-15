import QtQuick
import shell.services as RyokuServices
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../../common/functions"

RippleButton {
    id: root
    property bool showPing: false
    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    readonly property int unread: RyokuServices.Notifs.history.length

    implicitWidth: 32
    implicitHeight: 32

    buttonRadius: Appearance.rounding.full
    colBackground: isMaterial ? Appearance.colors.colPrimaryContainer : "transparent"
    colBackgroundHover: isMaterial ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarRightOpen

    onPressed: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }

    Connections {
        target: RyokuServices.Notifs
        function onNewNotification() {
            if (GlobalStates.sidebarRightOpen) return;
            root.showPing = true;
        }
    }
    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            root.showPing = false;
        }
    }

    MaterialShape {
        id: litGlyph
        anchors.centerIn: parent
        shape: MaterialShape.Shape.Cookie6Sided
        implicitSize: 28
        color: Appearance.colors.colPrimary
        scale: root.toggled ? 1 : 0
        opacity: root.toggled ? 1 : 0
        rotation: root.toggled ? 0 : -90
        visible: opacity > 0.01
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            }
        }
        Behavior on rotation {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: RyokuServices.Flags.dnd ? "notifications_off" : "notifications"
        iconSize: Appearance.font.pixelSize.large
        fill: 1
        animateChange: true
        z: 2
        color: Appearance.m3colors.m3onPrimary
        scale: root.toggled ? 1 : 0
        opacity: root.toggled ? 1 : 0
        visible: opacity > 0.01
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    MaterialSymbol {
        id: bellGlyph
        anchors.centerIn: parent
        text: RyokuServices.Flags.dnd ? "notifications_off" : "notifications"
        iconSize: Appearance.font.pixelSize.large
        color: Appearance.colors.colOnLayer1
        scale: root.toggled ? 0 : 1
        opacity: root.toggled ? 0 : 1
        visible: opacity > 0.01
        Behavior on scale {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Rectangle {
        opacity: root.showPing ? 1 : 0
        visible: opacity > 0
        anchors {
            bottom: parent.bottom
            right: parent.right
            bottomMargin: -Appearance.spacing.space25
            rightMargin: -Appearance.spacing.space25
        }
        implicitWidth: 8
        implicitHeight: 8
        radius: Appearance.rounding.full
        color: Appearance.colors.colTertiary
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }
}
