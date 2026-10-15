import QtQuick
import QtQuick.Layouts
import "../../../../../services"
import "../../../../common"
import "../../../../common/models/quickToggles"
import "../../../../common/functions"
import "../../../../common/widgets"
import "../../../../common/functions/layout_ops.js" as LayoutOps

GroupButton {
    id: root
    
    required property int buttonIndex
    required property var buttonData
    required property bool expandedSize
    required property real baseCellWidth
    required property real baseCellHeight
    required property real cellSpacing
    required property int cellSize
    property var dropIndicatorRef: null
    property bool isUnused: false 
    property var gridRef: null
    property var pagerRef: null
    property int pageIndex: 0

    signal openMenu()
    signal moveRequested(int fromIndex, int toIndex)
    signal addRequested(string type)
    signal removeRequested(int index)
    signal resizeRequested(int index, int size)
    signal moveAcrossRequested(int fromIndex, int toPage, int toIndex)
    property bool panelOpen: false

    property QuickToggleModel toggleModel
    property string name: toggleModel?.name ?? ""
    property string statusText: (toggleModel?.hasStatusText) ? (toggleModel?.statusText || (toggled ? Translation.tr("On") : Translation.tr("Off"))) : ""
    property string tooltipText: toggleModel?.tooltipText ?? ""
    property string buttonIcon: toggleModel?.icon ?? "close"
    property bool available: toggleModel?.available ?? true
    toggled: toggleModel?.toggled ?? false
    property var mainAction: toggleModel?.mainAction ?? null
    altAction: toggleModel?.hasMenu ? (() => root.openMenu()) : (toggleModel?.altAction ?? null)

    property bool editMode: false

    baseWidth: root.baseCellWidth * cellSize + cellSpacing * (cellSize - 1)
    baseHeight: root.baseCellHeight
    enableImplicitWidthAnimation: !editMode && root.hovered
    enableImplicitHeightAnimation: !editMode && root.hovered
    Behavior on baseWidth {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on baseHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    Component.onCompleted: {
        root.appear = 0;
        Qt.callLater(() => {
            const wave = root.gridRef?.entranceWave ?? null;
            if (wave && (wave.active.length > 0 || wave.pendingEnter))
                return;
            if (!root.panelOpen) {
                root.appear = 1;
                return;
            }
            lateArrival.restart();
        });
    }
    NumberAnimation {
        id: lateArrival
        target: root
        property: "appear"
        to: 1
        duration: Appearance.animation.elementMoveFast.duration
        easing.type: Appearance.animation.elementMoveFast.type
        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
    }

    x: (root.buttonData?.layoutSlot ?? 0) * (root.baseCellWidth + root.cellSpacing)
    y: (root.buttonData?.layoutRow ?? 0) * (root.baseCellHeight + root.cellSpacing)
    Behavior on x {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on y {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    transform: Translate {
        x: -(root.width - root.baseWidth) / 2
    }

    enabled: available || editMode
    padding: Appearance.spacing.space100
    horizontalPadding: padding
    verticalPadding: padding

    colBackground: Appearance.colors.colLayer2
    colBackgroundToggled: (altAction && expandedSize) ? Appearance.colors.colLayer2 : Appearance.colors.colPrimary
    colBackgroundToggledHover: (altAction && expandedSize) ? Appearance.colors.colLayer2Hover : Appearance.colors.colPrimaryHover
    colBackgroundToggledActive: (altAction && expandedSize) ? Appearance.colors.colLayer2Active : Appearance.colors.colPrimaryActive
    buttonRadius: toggled ? Appearance.rounding.large : height / 2
    buttonRadiusPressed: Appearance.rounding.normal
    property color colText: (toggled && !(altAction && expandedSize) && enabled) ? Appearance.colors.colOnPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer2, enabled ? 0 : 0.7)
    property color colIcon: expandedSize ? ((root.toggled) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer3) : colText

    onClicked: {
        if (root.expandedSize && root.altAction) root.altAction();
        else root.mainAction();
    }

    contentItem: RowLayout {
        spacing: Appearance.spacing.space50
        anchors {
            centerIn: root.expandedSize ? undefined : parent
            fill: root.expandedSize ? parent : undefined
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        MouseArea {
            id: iconMouseArea
            hoverEnabled: true
            acceptedButtons: (root.expandedSize && root.altAction) ? Qt.LeftButton : Qt.NoButton
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.topMargin: root.verticalPadding
            Layout.bottomMargin: root.verticalPadding
            implicitHeight: iconBackground.implicitHeight
            implicitWidth: iconBackground.implicitWidth
            cursorShape: Qt.PointingHandCursor
            onClicked: root.mainAction()

            Rectangle {
                id: iconBackground
                anchors.fill: parent
                implicitWidth: height
                radius: root.radius - root.verticalPadding
                color: {
                    const baseColor = root.toggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
                    const transparentizeAmount = (root.altAction && root.expandedSize) ? 0 : 1
                    return ColorUtils.transparentize(baseColor, transparentizeAmount)
                }
                Behavior on radius { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: root.toggled ? 1 : 0
                    iconSize: root.expandedSize ? 22 : 24
                    color: root.colIcon
                    text: root.buttonIcon
                }

                Loader {
                    anchors.fill: parent
                    active: (root.expandedSize && root.altAction)
                    sourceComponent: Rectangle {
                        radius: iconBackground.radius
                        color: ColorUtils.transparentize(root.colIcon, iconMouseArea.containsPress ? 0.88 : iconMouseArea.containsMouse ? 0.95 : 1)
                        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                    }
                }
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            visible: root.expandedSize
            active: visible
            sourceComponent: Column {
                spacing: -Appearance.spacing.space25
                StyledText {
                    anchors { left: parent.left; right: parent.right }
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    font.weight: 600
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.name
                }
                StyledText {
                    visible: root.statusText
                    anchors { left: parent.left; right: parent.right }
                    font { pixelSize: Appearance.font.pixelSize.smaller; weight: 100 }
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.statusText
                }
            }
        }
    }

    Item {
        id: editModeInteraction
        visible: root.editMode && !root.isUnused
        anchors.fill: parent

        property bool isDragging: false

        DragHandler {
            id: dragHandler
            target: null

            function siblingsIn(grid) {
                const siblings = [];
                if (!grid) return siblings;
                for (let i = 0; i < grid.children.length; i++) {
                    const sib = grid.children[i];
                    if (!sib || !sib.visible || !sib.buttonData) continue;
                    siblings.push(sib);
                }
                return siblings;
            }

            function findNearestIn(grid, sceneX, sceneY) {
                const siblings = siblingsIn(grid);
                const centres = siblings.map(sib =>
                    sib.buttonData.itemId === root.buttonData.itemId
                        ? null
                        : sib.mapToItem(null, sib.width / 2, sib.height / 2));
                const nearest = LayoutOps.indexAt(centres, Qt.point(sceneX, sceneY), null);
                return nearest === -1 ? null : siblings[nearest];
            }

            function crossingPages() {
                return root.pagerRef && root.pagerRef.currentPage !== root.pageIndex;
            }

            onActiveChanged: {
                editModeInteraction.isDragging = active;
                if (root.pagerRef) root.pagerRef.dragActive = active;

                if (!active) {
                    if (root.dropIndicatorRef) root.dropIndicatorRef.visible = false;
                    const landing = root.pagerRef?.currentIndicator() ?? null;
                    if (landing) landing.visible = false;
                    const sceneX = centroid.scenePosition.x;
                    const sceneY = centroid.scenePosition.y;
                    if (crossingPages()) {
                        const grid = root.pagerRef.currentGrid();
                        const nearest = grid ? findNearestIn(grid, sceneX, sceneY) : null;
                        let insertAt = 0;
                        if (nearest) {
                            const centre = nearest.mapToItem(null, nearest.width / 2, 0).x;
                            insertAt = nearest.buttonIndex + (sceneX > centre ? 1 : 0);
                        }
                        root.moveAcrossRequested(root.buttonIndex,
                            root.pagerRef.currentPage, insertAt);
                    } else {
                        const nearest = findNearestIn(root.gridRef, sceneX, sceneY);
                        if (nearest)
                            root.moveRequested(root.buttonIndex, nearest.buttonIndex);
                    }
                    if (root.pagerRef) root.pagerRef.dragEnded();
                }
            }

            onCentroidChanged: {
                if (!active) return;
                const sceneX = centroid.scenePosition.x;
                const sceneY = centroid.scenePosition.y;
                if (root.pagerRef) root.pagerRef.dragHoverAt(sceneX);

                const crossing = crossingPages();
                const grid = crossing ? root.pagerRef.currentGrid() : root.gridRef;
                const indicator = crossing ? root.pagerRef.currentIndicator()
                                           : root.dropIndicatorRef;
                if (root.dropIndicatorRef && indicator !== root.dropIndicatorRef)
                    root.dropIndicatorRef.visible = false;
                if (!grid || !indicator) return;

                const nearest = findNearestIn(grid, sceneX, sceneY);
                if (nearest) {
                    const centre = nearest.mapToItem(null, nearest.width / 2, 0).x;
                    const goesAfter = sceneX > centre;
                    const nearestLocal = nearest.mapToItem(grid, 0, 0);
                    indicator.x = goesAfter
                        ? nearestLocal.x + nearest.width + 1
                        : nearestLocal.x - 5;
                    indicator.y = nearestLocal.y;
                    indicator.height = nearest.height;
                    indicator.visible = true;
                } else if (crossing) {
                    indicator.x = 0;
                    indicator.y = 0;
                    indicator.height = root.baseCellHeight;
                    indicator.visible = true;
                } else {
                    indicator.visible = false;
                }
            }
        }

        HoverHandler {
            cursorShape: editModeInteraction.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }
    }

    MouseArea {
        visible: root.editMode && root.isUnused
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.addRequested(root.buttonData.type)
    }

    Rectangle {
        id: deleteBtn
        visible: root.editMode && !root.isUnused
        z: 10
        width: 20
        height: 20
        radius: Appearance.rounding.full
        color: deleteHover.containsMouse ? Appearance.colors.colError : ColorUtils.transparentize(Appearance.colors.colError, 0.15)
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Appearance.spacing.space50
        anchors.rightMargin: Appearance.spacing.space50

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "close"
            iconSize: 13
            color: Appearance.colors.colOnError 
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        MouseArea {
            id: deleteHover
            anchors.fill: parent
            anchors.margins: -Appearance.spacing.space50
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.removeRequested(root.buttonIndex)
        }
    }

    Rectangle {
        id: resizeBtn
        visible: root.editMode && !root.isUnused
        z: 10
        width: 20
        height: 20
        radius: Appearance.rounding.unsharpenslight
        color: resizeHover.containsMouse ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.15)
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: Appearance.spacing.space50
        anchors.rightMargin: Appearance.spacing.space50

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "open_in_full"
            iconSize: 13
            color: Appearance.colors.colOnPrimary
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        MouseArea {
            id: resizeHover
            anchors.fill: parent
            anchors.margins: -Appearance.spacing.space50
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            preventStealing: true

            property real pressSceneX: 0
            property real pressSize: 1

            onPressed: event => {
                const scene = resizeBtn.mapToItem(null, event.x, event.y);
                pressSceneX = scene.x;
                pressSize = root.cellSize;
            }
            onPositionChanged: event => {
                if (!pressed) return;
                const scene = resizeBtn.mapToItem(null, event.x, event.y);
                const dx = scene.x - pressSceneX;
                const steps = Math.round(dx / root.baseCellWidth);
                const newSize = Math.max(1, Math.min(3, pressSize + steps));
                if (newSize !== root.cellSize)
                    root.resizeRequested(root.buttonIndex, newSize);
            }
        }
    }

    StyledToolTip {
        extraVisibleCondition: root.tooltipText !== ""
        text: root.tooltipText
    }
}