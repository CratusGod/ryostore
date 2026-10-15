pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../services"
import ".."
import "../functions"

ComboBox {
    id: root

    property string buttonIcon: ""
    property real buttonRadius: height / 2
    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colBackgroundHover: Appearance.colors.colSecondaryContainerHover
    property color colBackgroundActive: Appearance.colors.colSecondaryContainerActive

    implicitHeight: 40
    Layout.fillWidth: true

    component Lift: Scale {
        required property Item part
        origin.x: root.width / 2 - part.x
        origin.y: root.height / 2 - part.y
        xScale: surface.interactionMotion.scale
        yScale: surface.interactionMotion.scale
    }

    HoverHandler {
        id: pointer
        cursorShape: Qt.PointingHandCursor
    }

    background: PassiveRippleSurface {
        id: surface
        transform: Lift { part: surface }
        buttonRadius: root.buttonRadius
        colBackground: root.colBackground
        colBackgroundHover: root.colBackgroundHover
        colRipple: root.colBackgroundActive
        hostHovered: root.hovered
        hostDown: root.pressed
        hostPressPoint: pointer.point.position
    }

    indicator: MaterialSymbol {
        id: arrow
        x: root.width - width - 16
        y: root.height / 2 - height / 2
        transform: Lift { part: arrow }
        text: "keyboard_arrow_down"
        iconSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colOnSecondaryContainer

        rotation: root.popup.visible ? 180 : 0
        Behavior on rotation {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    contentItem: Item {
        id: content
        implicitWidth: buttonLayout.implicitWidth
        implicitHeight: buttonLayout.implicitHeight
        transform: Lift { part: content }

        RowLayout {
            id: buttonLayout
            anchors.fill: parent
            spacing: Appearance.spacing.space100
            anchors.leftMargin: Appearance.spacing.space200
            anchors.rightMargin: Appearance.spacing.space200

            Loader {
                Layout.alignment: Qt.AlignVCenter
                active: root.buttonIcon.length > 0 || !!(root.currentIndex >= 0 && typeof root.model[root.currentIndex] === 'object' && root.model[root.currentIndex]?.icon)
                visible: active
                sourceComponent: MaterialSymbol {
                    text: {
                        if (root.currentIndex >= 0 && typeof root.model[root.currentIndex] === 'object' && root.model[root.currentIndex]?.icon) {
                            return root.model[root.currentIndex].icon;
                        }
                        return root.buttonIcon;
                    }
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }

            StyledText {
                id: buttonLabel
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: Appearance.colors.colOnSecondaryContainer
                text: root.displayText
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    StyledToolTip {
        extraVisibleCondition: false
        alternativeVisibleCondition: root.hovered && buttonLabel.truncated
        delay: 0
        text: buttonLabel.text
    }

    delegate: ItemDelegate {
        id: itemDelegate
        width: ListView.view ? ListView.view.width : root.width
        implicitHeight: 40

        required property var model
        required property int index
        readonly property bool chosen: root.currentIndex === itemDelegate.index
        property color colText: itemDelegate.chosen ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3

        transform: Scale {
            origin.x: itemDelegate.width / 2
            origin.y: itemDelegate.height / 2
            xScale: rowSurface.interactionMotion.scale
            yScale: rowSurface.interactionMotion.scale
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        background: PassiveRippleSurface {
            id: rowSurface
            buttonRadius: Appearance.rounding.small
            colBackground: itemDelegate.chosen
                ? Appearance.colors.colSecondaryContainer
                : ColorUtils.transparentize(Appearance.colors.colLayer3)
            colBackgroundHover: itemDelegate.chosen
                ? Appearance.colors.colSecondaryContainerHover
                : Appearance.colors.colLayer3Hover
            colRipple: itemDelegate.chosen
                ? Appearance.colors.colSecondaryContainerActive
                : Appearance.colors.colLayer3Active
            hostHovered: itemDelegate.hovered
            hostDown: itemDelegate.down
            hostPressPoint: Qt.point(itemDelegate.pressX, itemDelegate.pressY)
        }

        contentItem: RowLayout {
            spacing: Appearance.spacing.space100
            anchors.leftMargin: Appearance.spacing.space150
            anchors.rightMargin: Appearance.spacing.space150

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Appearance.font.pixelSize.larger
                active: typeof itemDelegate.model === 'object' && itemDelegate.model?.icon?.length > 0
                visible: active

                sourceComponent: Item {
                    implicitWidth: icon.implicitWidth
                    implicitHeight: Appearance.font.pixelSize.larger

                    MaterialSymbol {
                        id: icon
                        anchors.centerIn: parent
                        text: itemDelegate.model?.icon ?? ""
                        iconSize: Appearance.font.pixelSize.larger
                        color: itemDelegate.colText
                    }
                }
            }

            StyledText {
                id: label
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.font.pixelSize.larger
                color: itemDelegate.colText
                text: itemDelegate.model[root.textRole]
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        StyledToolTip {
            extraVisibleCondition: false
            alternativeVisibleCondition: itemDelegate.hovered && label.truncated
            delay: 0
            text: label.text
        }
    }

    property real popupWidth: 0

    popup: Popup {
        id: popup
        y: root.height + 4
        width: root.popupWidth > 0 ? Math.max(root.width, root.popupWidth) : root.width
        height: Math.min(listView.contentHeight + topPadding + bottomPadding, 300)
        padding: Appearance.spacing.space100

        property real reveal: 1
        opacity: popup.reveal

        enter: Transition {
            NumberAnimation {
                target: popup
                property: "reveal"
                from: 0
                to: 1
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }

        exit: Transition {
            NumberAnimation {
                target: popup
                property: "reveal"
                from: 1
                to: 0
                duration: Appearance.animation.elementMoveExit.duration
                easing.type: Appearance.animation.elementMoveExit.type
                easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
            }
        }

        readonly property bool opensUpward: popup.y < 0
        component Unfold: Scale {
            required property Item part
            origin.x: part.width / 2
            origin.y: popup.opensUpward ? part.height : 0
            xScale: 0.96 + 0.04 * popup.reveal
            yScale: 0.8 + 0.2 * popup.reveal
        }

        background: Item {
            id: popupBackdrop
            transform: Unfold { part: popupBackdrop }
            StyledRectangularShadow {
                target: popupBackground
            }

            Rectangle {
                id: popupBackground
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainerHigh
            }
        }

        contentItem: StyledListView {
            id: listView
            transform: Unfold { part: listView }
            clip: true
            implicitHeight: contentHeight
            spacing: Appearance.spacing.space25
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }
    }
}
