import ".."
import "."
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    property bool bounce: true
    property real baseWidth: contentItem.implicitWidth + horizontalPadding * 2
    property real baseHeight: contentItem.implicitHeight + verticalPadding * 2
    property bool enableImplicitWidthAnimation: true
    property bool enableImplicitHeightAnimation: true
    property real clickedWidth: baseWidth + (isAtSide ? 10 : 20)
    property real clickedHeight: baseHeight
    property var parentGroup: root.parent
    property int indexInParent: parentGroup?.children.indexOf(root) ?? -1
    property int clickIndex: parentGroup?.clickIndex ?? -1
    property bool isAtSide: indexInParent === 0 || indexInParent === (parentGroup?.childrenCount - 1)

    Layout.fillWidth: (clickIndex - 1 <= indexInParent && indexInParent <= clickIndex + 1)
    Layout.fillHeight: (clickIndex - 1 <= indexInParent && indexInParent <= clickIndex + 1)
    implicitWidth: (root.down && bounce) ? clickedWidth : baseWidth
    implicitHeight: (root.down && bounce) ? clickedHeight : baseHeight

    property color colBackgroundActive: Appearance?.colors.colLayer1Active ?? "#D6CEE2"
    property color colBackgroundToggledActive: Appearance?.colors.colPrimaryActive ?? "#D6CEE2"
    colRipple: root.colBackgroundActive
    colRippleToggled: root.colBackgroundToggledActive

    property real radius: root.buttonEffectiveRadius
    property real leftRadius: root.buttonEffectiveRadius
    property real rightRadius: root.buttonEffectiveRadius
    cornerTopLeft: root.leftRadius
    cornerBottomLeft: root.leftRadius
    cornerTopRight: root.rightRadius
    cornerBottomRight: root.rightRadius

    property color color: root.enabled ? (root.toggled ?
        (root.down ? colBackgroundToggledActive :
            root.hovered ? colBackgroundToggledHover :
            colBackgroundToggled) :
        (root.down ? colBackgroundActive :
            root.hovered ? colBackgroundHover :
            colBackground)) : colBackground
    buttonColor: root.color

    property bool tabbedTo: root.focus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason)
    border: root.tabbedTo
    borderWidth: 2
    colBorder: Appearance.colors.colSecondary

    onDownChanged: {
        if (root.down) {
            if (root.parent.clickIndex !== undefined) {
                root.parent.clickIndex = parent.children.indexOf(root)
            }
        }
    }

    Behavior on implicitWidth {
        enabled: root.enableImplicitWidthAnimation && root.hovered
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    Behavior on implicitHeight {
        enabled: root.enableImplicitHeightAnimation && root.hovered
        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
    }

    Behavior on leftRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on rightRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
