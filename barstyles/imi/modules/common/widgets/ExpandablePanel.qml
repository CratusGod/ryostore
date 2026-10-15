pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import ".."
import "."

StyledRectangle {
    id: root

    property bool expanded: false
    property alias header: headerRow.data
    default property alias content: contentColumn.data

    property int surfaceLayer: StyledRectangle.ContentLayer.Pane
    property bool outline: false
    property bool divider: true
    property bool shapeMorph: false
    property bool tonalLift: false
    property int staggerStep: 0
    property Item staggerTarget: contentColumn

    property bool headerClickable: false
    signal headerClicked()

    readonly property int staggerLeadIn: 120

    property StaggerWave stagger: StaggerWave {
        target: root.staggerTarget ?? contentColumn
        step: root.staggerStep
        leadIn: root.staggerLeadIn
    }

    contentLayer: (root.tonalLift && root.expanded) ? Math.max(0, root.surfaceLayer - 1) : root.surfaceLayer

    implicitHeight: cardColumn.implicitHeight
    radius: (root.shapeMorph && root.expanded) ? Appearance.rounding.large : Appearance.rounding.normal
    border.width: root.outline ? Appearance.borderWidth.standard : 0
    border.color: root.expanded ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

    Behavior on radius {
        animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
    }
    Behavior on border.color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    onStaggerStepChanged: {
        if (root.staggerStep <= 0)
            root.stagger.settle();
    }

    onExpandedChanged: {
        panel.animateTo(root.expanded);
        if (root.staggerStep > 0)
            root.stagger.run(root.expanded);
    }

    ColumnLayout {
        id: cardColumn
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 0

        Item {
            id: headerSlot
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + Appearance.spacing.space100 * 2

            Loader {
                anchors.fill: parent
                active: root.headerClickable
                sourceComponent: RippleButton {
                    buttonRadius: root.radius
                    cornerBottomLeft: root.expanded ? 0 : root.radius
                    cornerBottomRight: root.expanded ? 0 : root.radius
                    Behavior on cornerBottomLeft {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on cornerBottomRight {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    onClicked: root.headerClicked()
                }
            }

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: Appearance.spacing.space100
                spacing: Appearance.spacing.space100
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.spacing.space100
            Layout.rightMargin: Appearance.spacing.space100
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            visible: root.divider
            opacity: (root.expanded && panel.targetHeight > 0) ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        Item {
            id: panel
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.spacing.space300
            Layout.rightMargin: Appearance.spacing.space100

            readonly property int verticalInset: Appearance.spacing.space100 + Appearance.spacing.space150
            readonly property real targetHeight: contentColumn.implicitHeight > 0
                ? contentColumn.implicitHeight + verticalInset : 0
            implicitHeight: 0
            opacity: root.expanded ? 1 : 0
            enabled: root.expanded
            clip: true

            function animateTo(open) {
                expandAnim.stop();
                collapseAnim.stop();
                if (open) {
                    expandAnim.to = panel.targetHeight;
                    expandAnim.start();
                } else {
                    collapseAnim.start();
                }
            }


            NumberAnimation {
                id: expandAnim
                target: panel
                property: "implicitHeight"
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
            NumberAnimation {
                id: collapseAnim
                target: panel
                property: "implicitHeight"
                to: 0
                duration: Appearance.animation.elementMoveExit.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
            }

            Component.onCompleted: {
                if (root.expanded)
                    panel.implicitHeight = panel.targetHeight;
            }

            onTargetHeightChanged: {
                if (root.expanded && !expandAnim.running)
                    panel.implicitHeight = panel.targetHeight;
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            ColumnLayout {
                id: contentColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    topMargin: Appearance.spacing.space100
                }
                spacing: Appearance.spacing.space100
            }
        }
    }
}
