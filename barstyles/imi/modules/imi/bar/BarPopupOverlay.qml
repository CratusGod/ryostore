pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "bar_popup_unroll.js" as BarPopupUnroll

Scope {
    id: overlayScope

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        PanelWindow {
            id: overlayWindow
            required property ShellScreen modelData

            screen: modelData
            color: "transparent"
            visible: overlayWindow.current !== null
                || overlayWindow.outgoing !== null
                || overlayWindow.exiting
                || card.openProgress > 0
                || card.width > 0
                || card.openHeight > 0
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "quickshell:barPopup"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region {
                item: card
            }

            property var current: null
            property var outgoing: null
            property bool exiting: false
            property var exitAnchor: null
            readonly property bool morphing: card.alongBarAnim.running || card.widthAnim.running
                || card.openAnim.running

            readonly property var requested: {
                const popup = GlobalStates.activeBarPopup;
                if (!popup || !popup.popupVisible) return null;
                if (popup.hoverTarget?.QsWindow?.window?.screen !== overlayWindow.modelData) return null;
                return popup;
            }

            onRequestedChanged: {
                if (requested) takeOver(requested);
                else beginExit();
            }

            function takeOver(popup) {
                exitTimer.stop();
                overlayWindow.exiting = false;
                if (overlayWindow.current?.contentItem)
                    overlayWindow.current.contentItem.enabled = true;

                if (overlayWindow.current === popup) {
                    retargetTimer.restart();
                    return;
                }

                if (overlayWindow.outgoing && overlayWindow.outgoing !== popup)
                    overlayWindow.release(overlayWindow.outgoing);
                overlayWindow.outgoing = null;

                const previous = overlayWindow.current;
                if (previous) previous.popupHovered = false;
                overlayWindow.current = popup;

                if (previous && previous !== popup && previous.contentItem) {
                    overlayWindow.outgoing = previous;
                    previous.contentItem.enabled = false;
                    contentExit.target = previous.contentItem;
                    contentExit.restart();
                }

                const arriving = popup.contentItem;
                if (arriving) {
                    arriving.parent = contentSlot;
                    arriving.anchors.centerIn = contentSlot;
                    arriving.enabled = true;
                    arriving.opacity = 0;
                    contentEnter.stop();
                    contentEnter.item = arriving;
                    contentEnter.restart();
                }
                popup.surfaceWindow = overlayWindow;
                popup.popupHovered = cardHover.hovered;

                if (card.width <= 0 || card.openHeight <= 0) overlayWindow.park();
                retargetTimer.restart();
            }

            function retarget() {
                const popup = overlayWindow.current;
                const content = popup?.contentItem;
                const target = popup?.hoverTarget;
                if (!content || !target?.QsWindow?.window) return;

                const margin = Appearance.sizes.elevationMargin;
                const cardWidth = content.implicitWidth + popup.contentPadding * 2;
                const cardHeight = content.implicitHeight + popup.contentPadding * 2;

                if (overlayWindow.barVertical) {
                    const base = target.QsWindow.mapFromItem(target, 0, (target.height - cardHeight) / 2).y;
                    card.alongBar = Math.max(margin, Math.min(base, overlayWindow.height - cardHeight - margin - 15));
                } else {
                    const base = target.QsWindow.mapFromItem(target, (target.width - cardWidth) / 2, 0).x;
                    card.alongBar = Math.max(margin, Math.min(base, overlayWindow.width - cardWidth - margin - 10));
                }

                card.width = cardWidth;
                card.openHeight = cardHeight;
                card.heroHeight = BarPopupUnroll.heroSectionHeight(content.children, popup.contentPadding);
                card.openProgress = 1;
                overlayWindow.exitAnchor = overlayWindow.anchorAlongBar();
            }

            function anchorAlongBar() {
                const popup = overlayWindow.current ?? overlayWindow.outgoing;
                const target = popup?.hoverTarget;
                if (!target?.QsWindow?.window) return overlayWindow.exitAnchor;

                const centre = target.QsWindow.mapFromItem(target, target.width / 2, target.height / 2);
                return (overlayWindow.barVertical ? centre.y : centre.x) - card.parkedSize / 2;
            }

            function park() {
                const anchor = overlayWindow.anchorAlongBar();
                if (anchor === null || anchor === undefined) return;
                card.animate = false;
                card.openProgress = 0;
                card.heroHeight = 0;
                card.openHeight = card.parkedSize;
                card.width = card.parkedSize;
                card.alongBar = anchor;
                card.animate = true;
                overlayWindow.exitAnchor = anchor;
            }

            function beginExit() {
                if (overlayWindow.exiting) return;
                if (!overlayWindow.current && !overlayWindow.outgoing
                        && card.width <= 0 && card.openHeight <= 0) return;
                if (card.width <= 0 && card.openHeight <= 0) {
                    overlayWindow.finishExit();
                    return;
                }
                const anchor = overlayWindow.anchorAlongBar();
                if (anchor === null || anchor === undefined) {
                    overlayWindow.finishExit();
                    return;
                }
                overlayWindow.exiting = true;
                if (overlayWindow.current?.contentItem)
                    overlayWindow.current.contentItem.enabled = false;
                card.alongBar = anchor;
                card.width = card.parkedSize;
                card.openProgress = 0;
                exitTimer.restart();
            }

            function finishExit() {
                exitTimer.stop();
                contentEnter.stop();
                contentExit.stop();

                const leaving = overlayWindow.current;
                overlayWindow.release(overlayWindow.outgoing);
                overlayWindow.release(leaving);
                overlayWindow.outgoing = null;
                overlayWindow.current = null;
                overlayWindow.exiting = false;

                card.animate = false;
                card.openProgress = 0;
                card.heroHeight = 0;
                card.openHeight = 0;
                card.width = 0;
                card.animate = true;

                if (leaving && GlobalStates.activeBarPopup === leaving)
                    GlobalStates.activeBarPopup = null;
            }

            function release(popup) {
                if (!popup) return;
                popup.aboutToRelease();
                const content = popup.contentItem;
                if (content) {
                    content.anchors.centerIn = null;
                    content.parent = null;
                    content.opacity = 1;
                    content.enabled = true;
                }
                popup.popupHovered = false;
                if (popup.surfaceWindow === overlayWindow) popup.surfaceWindow = null;
            }

            function updateHover() {
                if (overlayWindow.current) overlayWindow.current.popupHovered = cardHover.hovered;
            }

            Timer {
                id: retargetTimer
                interval: 0
                onTriggered: overlayWindow.retarget()
            }

            Timer {
                id: exitTimer
                interval: Appearance.animation.elementMove.duration
                onTriggered: overlayWindow.finishExit()
            }

            HyprlandFocusGrab {
                id: cardGrab
                active: WM.isHyprland && !!overlayWindow.current?.pinnedOpen
                    && !overlayWindow.exiting
                    && !overlayWindow.morphing
                    && card.width > Appearance.sizes.elevationMargin * 2
                windows: [
                    overlayWindow,
                    overlayWindow.current?.hoverTarget?.QsWindow?.window,
                    ...(overlayWindow.current?.extraGrabWindows ?? [])
                ].filter(window => window)
                onCleared: overlayWindow.current?.dismissRequested()
            }

            Connections {
                target: overlayWindow.current?.contentItem ?? null
                ignoreUnknownSignals: true
                function onImplicitWidthChanged() { overlayWindow.retargetNow() }
                function onImplicitHeightChanged() { overlayWindow.retargetNow() }
            }

            function retargetNow() {
                if (overlayWindow.current?.contentDrivesSize) overlayWindow.retarget();
                else retargetTimer.restart();
            }

            onWidthChanged: if (overlayWindow.current) overlayWindow.retarget()
            onHeightChanged: if (overlayWindow.current) overlayWindow.retarget()

            readonly property string barEdge: {
                if (!Config.options.bar.vertical)
                    return Config.options.bar.bottom ? "bottom" : "top";
                return Config.options.bar.bottom ? "right" : "left";
            }
            onBarEdgeChanged: overlayWindow.finishExit()

            readonly property bool barVertical: Config.options.bar.vertical
            readonly property real barThickness: overlayWindow.barVertical
                ? Appearance.sizes.verticalBarWidth
                : Appearance.sizes.barHeight

            SequentialAnimation {
                id: contentEnter
                property Item item: null
                PauseAnimation {
                    duration: Appearance.animation.elementMove.duration
                        - Appearance.animation.elementMoveEnter.duration
                }
                NumberAnimation {
                    target: contentEnter.item
                    property: "opacity"
                    to: 1
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                }
            }

            NumberAnimation {
                id: contentExit
                property: "opacity"
                to: 0
                duration: Appearance.animation.elementMoveExit.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
                onFinished: {
                    const leaving = overlayWindow.outgoing;
                    if (leaving && leaving.contentItem === contentExit.target) {
                        overlayWindow.release(leaving);
                        overlayWindow.outgoing = null;
                    }
                }
            }

            StyledRectangularShadow {
                target: card
                visible: card.visible
                opacity: card.opacity
                cached: !overlayWindow.morphing
            }

            Rectangle {
                id: card
                property bool animate: true

                property real openProgress: 0
                property real openHeight: 0
                property real heroHeight: 0
                readonly property real parkedSize: Appearance.sizes.elevationMargin * 2
                property real alongBar: 0

                width: 0
                height: BarPopupUnroll.cardHeight(card.openHeight, card.heroHeight,
                    card.parkedSize, overlayWindow.exiting, card.openProgress)
                x: overlayWindow.barVertical
                    ? (overlayWindow.barEdge === "right"
                        ? overlayWindow.width - overlayWindow.barThickness - Appearance.sizes.elevationMargin - card.width
                        : overlayWindow.barThickness + Appearance.sizes.elevationMargin)
                    : card.alongBar
                y: overlayWindow.barVertical
                    ? card.alongBar
                    : (overlayWindow.barEdge === "bottom"
                        ? overlayWindow.height - overlayWindow.barThickness - Appearance.sizes.elevationMargin - card.height
                        : overlayWindow.barThickness + Appearance.sizes.elevationMargin)
                opacity: Math.max(0, Math.min(1, card.openProgress))
                visible: width > 0 && height > 0

                color: Appearance.colors.colLayer1Base
                radius: Appearance.rounding.normal + 4
                border.width: Appearance.borderWidth.standard
                border.color: Appearance.colors.colLayer0Border

                readonly property NumberAnimation openAnim: Appearance.animation.elementMove.numberAnimation.createObject(card)
                readonly property NumberAnimation alongBarAnim: Appearance.animation.elementMove.numberAnimation.createObject(card)
                readonly property NumberAnimation widthAnim: Appearance.animation.elementMove.numberAnimation.createObject(card)
                readonly property NumberAnimation heightAnim: Appearance.animation.elementMove.numberAnimation.createObject(card)

                Behavior on openProgress {
                    enabled: card.animate
                    animation: card.openAnim
                }
                Behavior on alongBar {
                    enabled: card.animate && !(overlayWindow.current?.contentDrivesSize ?? false)
                    animation: card.alongBarAnim
                }
                Behavior on width {
                    enabled: card.animate && !(overlayWindow.current?.contentDrivesSize ?? false)
                    animation: card.widthAnim
                }
                Behavior on openHeight {
                    enabled: card.animate && !(overlayWindow.current?.contentDrivesSize ?? false)
                    animation: card.heightAnim
                }

                HoverHandler {
                    id: cardHover
                    onHoveredChanged: overlayWindow.updateHover()
                }

                Item {
                    id: contentHost
                    anchors.fill: parent
                    anchors.margins: overlayWindow.current?.contentPadding ?? 0
                    clip: true

                    Item {
                        id: contentSlot
                        width: parent.width
                        height: Math.max(0, card.openHeight
                            - 2 * (overlayWindow.current?.contentPadding ?? 0))
                    }
                }
            }
        }
    }
}
