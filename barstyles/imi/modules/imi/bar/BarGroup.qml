import "../../.."
import "../../common"
import QtQuick
import QtQuick.Layouts
import "bar_flip.js" as BarFlip

Item {
    id: root
    property bool vertical: false
    property int currentIndex: 0
    property int totalCount: 0

    property string widgetId: ""

    property var editController: null
    property string editBucket: ""

    property BarFlipRegistry flipRegistry: null
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property bool paintMaterialPill: false
    property real padding: (root.isMaterial && !root.paintMaterialPill) ? 0
        : Config.options.bar.cornerStyle === 2 ? Appearance.spacing.space150
        : Appearance.spacing.space50
    property color bgColor: Appearance.colors.colPrimaryContainer

    readonly property bool atFarEdge: Config.options.bar.bottom
    readonly property real edgeMargin: Appearance.sizes.barMarginTop
    readonly property real windowMargin: Appearance.sizes.barMarginBottom

    readonly property real fullRadius: Appearance.rounding.full
    readonly property real midRadius: Appearance.rounding.unsharpenmore
    property real startRadius: {
        if (totalCount <= 1) return fullRadius;
        if (currentIndex === 0) return fullRadius;
        return midRadius;
    }
    property real endRadius: {
        if (totalCount <= 1) return fullRadius;
        if (currentIndex === totalCount - 1) return fullRadius;
        return midRadius;
    }

    implicitWidth: vertical && root.isMaterial ? Appearance.sizes.baseVerticalBarWidth - 6 : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight

    default property alias items: gridLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : (root.atFarEdge ? root.windowMargin : root.edgeMargin)
            bottomMargin: root.vertical ? 0 : (root.atFarEdge ? root.edgeMargin : root.windowMargin)
            leftMargin: !root.vertical ? 0 : (root.atFarEdge ? root.windowMargin : root.edgeMargin)
            rightMargin: !root.vertical ? 0 : (root.atFarEdge ? root.edgeMargin : root.windowMargin)
        }
        color: (root.isMaterial && !root.paintMaterialPill)
            ? "transparent"
            : (root.isMaterial && root.paintMaterialPill)
                ? root.bgColor
                : (Config.options?.bar.borderless === "transparent"
                    ? "transparent"
                    : Config.options.bar.cornerStyle === 2
                        ? Appearance.colors.colLayer0
                        : Appearance.colors.colLayer1)

        topLeftRadius: (root.isMaterial && root.paintMaterialPill) ? root.fullRadius : (Config.options?.bar.borderless === "separated" ? root.fullRadius : root.startRadius)
        bottomLeftRadius: (root.isMaterial && root.paintMaterialPill) ? root.fullRadius : (Config.options?.bar.borderless === "separated" ? root.fullRadius : root.vertical ? root.endRadius : root.startRadius)
        topRightRadius: (root.isMaterial && root.paintMaterialPill) ? root.fullRadius : (Config.options?.bar.borderless === "separated" ? root.fullRadius : root.vertical ? root.startRadius : root.endRadius)
        bottomRightRadius: (root.isMaterial && root.paintMaterialPill) ? root.fullRadius : (Config.options?.bar.borderless === "separated" ? root.fullRadius : root.endRadius)

        border.width: (root.isMaterial && root.paintMaterialPill) ? 1 : 0
        border.color: Appearance.colors.colLayer0Border

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors.centerIn: parent
        columnSpacing: 0
        rowSpacing: 0
    }

    opacity: editLoader.item && editLoader.item.dragging ? 0.4 : 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    property real flipTravel: 0
    property var flipOrigin: null
    property bool flipPending: false
    property var flipChain: []

    transform: Translate {
        x: root.vertical ? 0 : root.flipTravel
        y: root.vertical ? root.flipTravel : 0
    }

    readonly property NumberAnimation flipAnim:
        Appearance.animation.elementMoveSmall.numberAnimation.createObject(root)

    function flipWalk() {
        const frame = root.flipRegistry ? root.flipRegistry.frame : null;
        const chain = [];
        let node = root;
        while (node && node !== frame) {
            chain.push(node);
            node = node.parent;
        }
        return chain;
    }

    function flipOriginNow() {
        return BarFlip.chainOrigin(root.flipWalk());
    }

    function flipDrawnOrigin() {
        const origin = root.flipOriginNow();
        return root.vertical
            ? { x: origin.x, y: origin.y + root.flipTravel }
            : { x: origin.x + root.flipTravel, y: origin.y };
    }

    function flipMeasure() {
        if (!root.flipPending && !root.flipAnim.running) return;
        const origin = root.flipOriginNow();
        const step = BarFlip.repositionTravel(root.flipTravel, root.flipOrigin,
                                              origin, root.vertical, BarFlip.MIN_TRAVEL);
        root.flipOrigin = origin;
        root.flipPending = false;
        if (!step.play) return;
        root.flipTravel = step.travel;
        root.flipAnim.restart();
    }

    readonly property bool flipAllowed: !GlobalStates.editBarDragActive
    onFlipAllowedChanged: if (!root.flipAllowed) {
        root.flipAnim.stop();
        root.flipTravel = 0;
        root.flipPending = false;
    }

    Connections {
        target: root.flipAnim
        function onFinished() {
            root.flipTravel = 0;
        }
    }

    Component.onCompleted: {
        if (!root.flipRegistry) return;
        root.flipAnim.target = root;
        root.flipAnim.property = "flipTravel";
        root.flipAnim.to = 0;
        root.flipChain = root.flipWalk();
        for (const node of root.flipChain) {
            node.xChanged.connect(root, root.flipMeasure);
            node.yChanged.connect(root, root.flipMeasure);
        }
        const recalled = root.flipAllowed ? root.flipRegistry.recall(root.widgetId) : null;
        if (!recalled) return;
        root.flipOrigin = recalled;
        root.flipPending = true;
    }

    Component.onDestruction: {
        if (!root.flipRegistry) return;
        root.flipRegistry.deposit(root.widgetId, root.flipDrawnOrigin());
        for (const node of root.flipChain) {
            node.xChanged.disconnect(root, root.flipMeasure);
            node.yChanged.disconnect(root, root.flipMeasure);
        }
    }

    Loader {
        id: editLoader
        anchors.fill: parent
        z: 100
        active: root.editController !== null && GlobalStates.editMode
        sourceComponent: BarWidgetEditItem {
            controller: root.editController
            bucket: root.editBucket
            widgetId: root.widgetId
            visibleIndex: root.currentIndex
        }
    }
}
