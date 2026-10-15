import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../../common/plugins"

Item {
    id: root
    clip: true

    property real panelWidth: Appearance.sizes.editModeDrawerWidth

    property Item ghostParent: null

    signal addRequested(var manifest, real dropX, real dropY)
    signal toggleRequested(var manifest)
    signal barAddRequested(string widgetId, string bucket)
    signal dockToggleRequested(string appId)
    signal lockToggleRequested(string key)
    signal lockWidgetToggleRequested(string pluginId)
    signal lockLayoutResetRequested()
    signal lockPresenceResetRequested()

    property string screenName: ""
    readonly property bool lockLayoutForked: PluginState.lockLayoutForked(root.screenName)
    readonly property bool lockPresenceForked: PluginState.lockPresenceForked()

    readonly property bool dropWouldRemove: root.screenName !== ""
        && GlobalStates.editDrawerDropScreen === root.screenName

    property string section: "widgets"
    property string barBucket: "right"

    readonly property var desktopManifests: PluginManager.availablePlugins.filter(manifest =>
        PluginManager.pluginSurfaces(manifest).includes("desktop-widget")
        && manifest.startupSafe !== false)

    readonly property var enabledIds: Config.options.plugins.enabled

    readonly property var barOffer: BarWidgets.offerFor([
        ...Config.options.bar.layouts.leftLayout,
        ...Config.options.bar.layouts.middleLayout,
        ...Config.options.bar.layouts.rightLayout
    ], Config.options.bar.borderless)

    readonly property bool barVertical: Config.options.bar.vertical

    property var dragManifest: null

    readonly property var lockIslandRows: [
        { kind: "island", key: "showToolbars", name: Translation.tr("Toolbars"),
            icon: "call_to_action",
            description: Translation.tr("The islands beside the password field") },
        { kind: "island", key: "showMedia", name: Translation.tr("Media player"),
            icon: "music_note",
            description: Translation.tr("Playback info while music is playing") },
        { kind: "island", key: "showWidgets", name: Translation.tr("Desktop widgets"),
            icon: "widgets",
            description: root.lockPresenceForked
                ? Translation.tr("Show the widgets picked below while locked")
                : Translation.tr("Show every desktop widget while locked") }
    ]

    readonly property var lockWidgetRows: Config.options.lock.showWidgets
        ? root.desktopManifests.map(manifest => ({
            kind: "widget",
            id: manifest.id,
            name: manifest.name,
            icon: "widgets",
            description: manifest.description ?? ""
        }))
        : []

    readonly property var lockRows: root.lockIslandRows.concat(root.lockWidgetRows)

    readonly property bool opening: GlobalStates.editDrawerOpen
    readonly property bool contentsIn: Appearance.animation.contentsArrived(
        GlobalStates.editDrawerProgress, root.opening)

    readonly property real entranceRise: Appearance.spacing.space250
    readonly property real entranceScaleFrom: Math.max(0.85,
        1 - root.entranceRise / Math.max(1, root.panelWidth))
    function entranceScale(appear) {
        return root.entranceScaleFrom + (1 - root.entranceScaleFrom) * appear;
    }
    function entranceOffset(appear) {
        return (1 - appear) * root.entranceRise;
    }

    onOpeningChanged: {
        if (root.opening)
            entrance.park();
    }

    onContentsInChanged: {
        if (root.contentsIn)
            entrance.enter();
        else
            entrance.settle();
    }

    Rectangle {
        id: panel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.panelWidth
        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.verylarge

        Rectangle {
            anchors.fill: parent
            radius: panel.radius
            color: root.dropWouldRemove
                ? Appearance.colors.colLayer2Active : "transparent"
            Behavior on color {
                animation: Appearance.animation.elementMoveFaster.colorAnimation.createObject(this)
            }
        }

        ColumnLayout {
            id: drawerColumn
            anchors.fill: parent
            anchors.margins: Appearance.spacing.space150
            spacing: Appearance.spacing.space100

            StaggerWave {
                id: entrance
                target: drawerColumn
            }

            RowLayout {
                id: addHeaderRow
                property real appear: 1
                opacity: addHeaderRow.appear
                scale: root.entranceScale(addHeaderRow.appear)
                transform: Translate { y: root.entranceOffset(addHeaderRow.appear) }
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.leftMargin: Appearance.spacing.space75
                Layout.rightMargin: Appearance.spacing.space75
                spacing: Appearance.spacing.space100

                MaterialSymbol {
                    text: "add_circle"
                    iconSize: 22
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Add")
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnSurface
                }
            }

            RowLayout {
                id: sectionChipRow
                property real appear: 1
                opacity: sectionChipRow.appear
                scale: root.entranceScale(sectionChipRow.appear)
                transform: Translate { y: root.entranceOffset(sectionChipRow.appear) }
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.leftMargin: Appearance.spacing.space75
                spacing: Appearance.spacing.space25

                SelectionGroupButton {
                    leftmost: true
                    buttonText: Translation.tr("Widgets")
                    toggled: root.section === "widgets"
                    onClicked: root.section = "widgets"
                }
                SelectionGroupButton {
                    buttonText: Translation.tr("Bar")
                    toggled: root.section === "bar"
                    onClicked: root.section = "bar"
                }
                SelectionGroupButton {
                    buttonText: Translation.tr("Dock")
                    toggled: root.section === "dock"
                    onClicked: root.section = "dock"
                }
                SelectionGroupButton {
                    rightmost: true
                    buttonText: Translation.tr("Lock")
                    toggled: root.section === "lock"
                    onClicked: root.section = "lock"
                }
            }

            StyledText {
                id: sectionHint
                property real appear: 1
                opacity: sectionHint.appear
                scale: root.entranceScale(sectionHint.appear)
                transform: Translate { y: root.entranceOffset(sectionHint.appear) }
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.leftMargin: Appearance.spacing.space75
                Layout.rightMargin: Appearance.spacing.space75
                text: root.section === "widgets"
                    ? Translation.tr("Drag a widget onto the desktop to place it, or click to add or remove it.")
                    : root.section === "bar"
                        ? Translation.tr("Click a widget to add it to the picked bar section, then drag it into place on the bar.")
                        : root.section === "dock"
                            ? Translation.tr("Click an app to pin or unpin it, then drag it into place on the dock.")
                            : Translation.tr("Choose what the lock screen shows. The Lockscreen tab previews it.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
                wrapMode: Text.Wrap
            }

            ListView {
                id: list
                property real appear: 1
                opacity: list.appear
                scale: root.entranceScale(list.appear)
                transform: Translate { y: root.entranceOffset(list.appear) }
                visible: root.section === "widgets"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Appearance.spacing.space25
                model: root.section === "widgets" ? root.desktopManifests : []

                delegate: MouseArea {
                    id: entry
                    required property var modelData
                    readonly property bool widgetEnabled: root.enabledIds.includes(entry.modelData.id)

                    width: list.width
                    height: 60
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true

                    property real pressX: 0
                    property real pressY: 0
                    property bool dragActive: false

                    onPressed: (mouse) => {
                        entry.pressX = mouse.x;
                        entry.pressY = mouse.y;
                        entry.dragActive = false;
                    }
                    onPositionChanged: (mouse) => {
                        if (!entry.pressed) return;
                        if (!entry.dragActive
                                && Math.abs(mouse.x - entry.pressX) < drag.threshold
                                && Math.abs(mouse.y - entry.pressY) < drag.threshold)
                            return;
                        entry.dragActive = true;
                        root.dragManifest = entry.modelData;
                        const point = entry.mapToItem(root.ghostParent ?? root, mouse.x, mouse.y);
                        ghost.x = point.x - ghost.width / 2;
                        ghost.y = point.y - ghost.height / 2;
                    }
                    onReleased: (mouse) => {
                        const wasDrag = entry.dragActive;
                        entry.dragActive = false;
                        root.dragManifest = null;
                        if (wasDrag) {
                            const point = entry.mapToItem(root.ghostParent ?? root, mouse.x, mouse.y);
                            root.addRequested(entry.modelData, point.x, point.y);
                        } else {
                            root.toggleRequested(entry.modelData);
                        }
                    }
                    onCanceled: {
                        entry.dragActive = false;
                        root.dragManifest = null;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.large
                        color: entry.pressed ? Appearance.colors.colLayer2Active
                            : entry.containsMouse ? Appearance.colors.colLayer2Hover
                            : "transparent"
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFaster.colorAnimation.createObject(this)
                        }
                    }

                    CatalogueRow {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacing.space100
                        anchors.rightMargin: Appearance.spacing.space100
                        rowSpacing: Appearance.spacing.space100

                        rowIcon: "widgets"
                        rowIconSize: 22
                        rowIconColor: Appearance.colors.colOnSurfaceVariant
                        title: entry.modelData.name
                        titleFont.pixelSize: Appearance.font.pixelSize.normal
                        titleColor: Appearance.colors.colOnSurface
                        titleFillsWidth: true
                        titleElides: true
                        description: entry.modelData.description ?? ""
                        descriptionColor: Appearance.colors.colOnSurfaceVariant
                        descriptionWraps: false

                        affordance: [
                            MaterialSymbol {
                                text: entry.widgetEnabled ? "check_circle" : "add"
                                iconSize: 20
                                color: entry.widgetEnabled
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colOnSurfaceVariant
                            }
                        ]
                    }
                }
            }

            RowLayout {
                id: barBucketRow
                property real appear: 1
                opacity: barBucketRow.appear
                scale: root.entranceScale(barBucketRow.appear)
                transform: Translate { y: root.entranceOffset(barBucketRow.appear) }
                visible: root.section === "bar"
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.leftMargin: Appearance.spacing.space75
                spacing: Appearance.spacing.space25

                SelectionGroupButton {
                    leftmost: true
                    buttonText: root.barVertical ? Translation.tr("Top") : Translation.tr("Left")
                    toggled: root.barBucket === "left"
                    onClicked: root.barBucket = "left"
                }
                SelectionGroupButton {
                    buttonText: Translation.tr("Middle")
                    toggled: root.barBucket === "middle"
                    onClicked: root.barBucket = "middle"
                }
                SelectionGroupButton {
                    rightmost: true
                    buttonText: root.barVertical ? Translation.tr("Bottom") : Translation.tr("Right")
                    toggled: root.barBucket === "right"
                    onClicked: root.barBucket = "right"
                }
            }

            ListView {
                id: barList
                property real appear: 1
                opacity: barList.appear
                scale: root.entranceScale(barList.appear)
                transform: Translate { y: root.entranceOffset(barList.appear) }
                visible: root.section === "bar"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Appearance.spacing.space25
                model: root.section === "bar" ? root.barOffer : []

                delegate: RippleButton {
                    required property var modelData
                    width: barList.width
                    implicitHeight: 48
                    buttonRadius: Appearance.rounding.large
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: root.barAddRequested(modelData.id, root.barBucket)

                    contentItem: CatalogueRow {
                        anchors {
                            fill: parent
                            leftMargin: Appearance.spacing.space100
                            rightMargin: Appearance.spacing.space100
                        }
                        rowSpacing: Appearance.spacing.space100

                        rowIcon: modelData.icon || "extension"
                        rowIconSize: 22
                        rowIconColor: Appearance.colors.colOnSurfaceVariant
                        title: modelData.name
                        titleFont.pixelSize: Appearance.font.pixelSize.normal
                        titleColor: Appearance.colors.colOnSurface
                        titleFillsWidth: true
                        titleElides: true

                        affordance: [
                            MaterialSymbol {
                                text: "add"
                                iconSize: 20
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        ]
                    }
                }
            }

            MaterialTextField {
                id: appSearchField
                property real appear: 1
                opacity: appSearchField.appear
                scale: root.entranceScale(appSearchField.appear)
                transform: Translate { y: root.entranceOffset(appSearchField.appear) }
                visible: root.section === "dock"
                Layout.fillWidth: true
                placeholderText: Translation.tr("Search apps")
            }

            ListView {
                id: appList
                property real appear: 1
                opacity: appList.appear
                scale: root.entranceScale(appList.appear)
                transform: Translate { y: root.entranceOffset(appList.appear) }
                visible: root.section === "dock"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Appearance.spacing.space25
                model: root.section !== "dock" ? []
                    : appSearchField.text.length > 0
                        ? AppSearch.fuzzyQuery(appSearchField.text)
                        : AppSearch.list

                delegate: RippleButton {
                    id: appRow
                    required property var modelData
                    readonly property string appId: (modelData.id ?? "").toLowerCase()
                    readonly property bool pinned: TaskbarApps.apps.some(
                        app => app.appId === appRow.appId && app.pinned)

                    width: appList.width
                    implicitHeight: 48
                    buttonRadius: Appearance.rounding.large
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: root.dockToggleRequested(appRow.appId)

                    contentItem: CatalogueRow {
                        anchors {
                            fill: parent
                            leftMargin: Appearance.spacing.space100
                            rightMargin: Appearance.spacing.space100
                        }
                        rowSpacing: Appearance.spacing.space100

                        iconComponent: Image {
                            sourceSize.width: 26
                            sourceSize.height: 26
                            source: Quickshell.iconPath(appRow.modelData.icon, "image-missing")
                        }
                        title: appRow.modelData.name ?? appRow.appId
                        titleFont.pixelSize: Appearance.font.pixelSize.normal
                        titleColor: Appearance.colors.colOnSurface
                        titleFillsWidth: true
                        titleElides: true

                        affordance: [
                            MaterialSymbol {
                                text: appRow.pinned ? "check_circle" : "add"
                                iconSize: 20
                                color: appRow.pinned
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colOnSurfaceVariant
                            }
                        ]
                    }
                }
            }

            ListView {
                id: lockList
                property real appear: 1
                opacity: lockList.appear
                scale: root.entranceScale(lockList.appear)
                transform: Translate { y: root.entranceOffset(lockList.appear) }
                visible: root.section === "lock"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Appearance.spacing.space25
                model: root.section === "lock" ? root.lockRows : []

                delegate: RippleButton {
                    id: lockRow
                    required property var modelData
                    readonly property bool isWidget: lockRow.modelData.kind === "widget"
                    readonly property bool islandOn: lockRow.modelData.key === "showToolbars"
                        ? Config.options.lock.showToolbars
                        : lockRow.modelData.key === "showMedia"
                            ? Config.options.lock.showMedia
                            : Config.options.lock.showWidgets
                    readonly property bool rowOn: lockRow.isWidget
                        ? PluginState.lockWidgetEnabled(lockRow.modelData.id)
                        : lockRow.islandOn

                    width: lockList.width
                    implicitHeight: 60
                    buttonRadius: Appearance.rounding.large
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: lockRow.isWidget
                        ? root.lockWidgetToggleRequested(lockRow.modelData.id)
                        : root.lockToggleRequested(lockRow.modelData.key)

                    contentItem: CatalogueRow {
                        anchors {
                            fill: parent
                            leftMargin: lockRow.isWidget
                                ? Appearance.spacing.space300
                                : Appearance.spacing.space100
                            rightMargin: Appearance.spacing.space100
                        }
                        rowSpacing: Appearance.spacing.space100

                        rowIcon: lockRow.modelData.icon
                        rowIconSize: 22
                        rowIconColor: Appearance.colors.colOnSurfaceVariant
                        title: lockRow.modelData.name
                        titleFont.pixelSize: Appearance.font.pixelSize.normal
                        titleColor: Appearance.colors.colOnSurface
                        titleFillsWidth: true
                        titleElides: true
                        description: lockRow.modelData.description ?? ""
                        descriptionColor: Appearance.colors.colOnSurfaceVariant
                        descriptionWraps: false

                        affordance: [
                            MaterialSymbol {
                                text: lockRow.rowOn ? "check_circle" : "add"
                                iconSize: 20
                                color: lockRow.rowOn
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colOnSurfaceVariant
                            }
                        ]
                    }
                }
            }

            RippleButton {
                id: lockPresenceRow
                visible: root.section === "lock" && Config.options.lock.showWidgets
                enabled: root.lockPresenceForked
                Layout.fillWidth: true
                Layout.fillHeight: false
                implicitHeight: 60
                buttonRadius: Appearance.rounding.large
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active
                onClicked: root.lockPresenceResetRequested()

                contentItem: CatalogueRow {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.spacing.space100
                        rightMargin: Appearance.spacing.space100
                    }
                    rowSpacing: Appearance.spacing.space100

                    rowIcon: root.lockPresenceForked ? "call_split" : "link"
                    rowIconSize: 22
                    rowIconColor: Appearance.colors.colOnSurfaceVariant
                    title: root.lockPresenceForked
                        ? Translation.tr("Widget choice is separate")
                        : Translation.tr("Widget choice follows the desktop")
                    titleFont.pixelSize: Appearance.font.pixelSize.normal
                    titleColor: Appearance.colors.colOnSurface
                    titleFillsWidth: true
                    titleElides: true
                    description: root.lockPresenceForked
                        ? Translation.tr("Click to show the desktop's widgets again")
                        : Translation.tr("Pick a widget above to choose the lock screen's own")
                    descriptionColor: Appearance.colors.colOnSurfaceVariant
                    descriptionWraps: false

                    affordance: [
                        MaterialSymbol {
                            visible: root.lockPresenceForked
                            text: "restart_alt"
                            iconSize: 20
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    ]
                }
            }

            RippleButton {
                id: lockLayoutRow
                visible: root.section === "lock"
                enabled: root.lockLayoutForked
                Layout.fillWidth: true
                Layout.fillHeight: false
                implicitHeight: 60
                buttonRadius: Appearance.rounding.large
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active
                onClicked: root.lockLayoutResetRequested()

                contentItem: CatalogueRow {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.spacing.space100
                        rightMargin: Appearance.spacing.space100
                    }
                    rowSpacing: Appearance.spacing.space100

                    rowIcon: root.lockLayoutForked ? "call_split" : "link"
                    rowIconSize: 22
                    rowIconColor: Appearance.colors.colOnSurfaceVariant
                    title: root.lockLayoutForked
                        ? Translation.tr("Widget layout is separate")
                        : Translation.tr("Widget layout follows the desktop")
                    titleFont.pixelSize: Appearance.font.pixelSize.normal
                    titleColor: Appearance.colors.colOnSurface
                    titleFillsWidth: true
                    titleElides: true
                    description: root.lockLayoutForked
                        ? Translation.tr("Click to use the desktop layout again")
                        : Translation.tr("Move a widget here to arrange the lock screen on its own")
                    descriptionColor: Appearance.colors.colOnSurfaceVariant
                    descriptionWraps: false

                    affordance: [
                        MaterialSymbol {
                            visible: root.lockLayoutForked
                            text: "restart_alt"
                            iconSize: 20
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    ]
                }
            }
        }
    }

    Rectangle {
        id: ghost
        parent: root.ghostParent ?? root
        visible: root.dragManifest !== null
        width: ghostRow.implicitWidth + Appearance.spacing.space200
        height: 40
        radius: height / 2
        color: Appearance.colors.colSecondaryContainer

        RowLayout {
            id: ghostRow
            anchors.centerIn: parent
            spacing: Appearance.spacing.space50

            MaterialSymbol {
                text: "widgets"
                iconSize: 20
                color: Appearance.colors.colOnSecondaryContainer
            }
            StyledText {
                text: root.dragManifest?.name ?? ""
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnSecondaryContainer
            }
        }
    }
}
