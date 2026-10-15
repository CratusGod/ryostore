import QtQuick
import QtQuick.Layouts
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../../common/plugins"
import "../../common/functions/edit_mode.js" as EditMode
import "../../common/plugins/gridSizes.js" as GridSizes

Item {
    id: root

    property var manifest: null
    property string screenName: ""
    signal dismissRequested()

    readonly property var offeredSizes: GridSizes.offeredSizes(root.manifest?.grid ?? null)
    readonly property var storedSpan: root.manifest
        ? PluginState.gridSize(root.manifest.id, root.screenName) : undefined
    readonly property var currentSize: GridSizes.resolveSize(root.manifest?.grid ?? null,
        root.storedSpan)
    readonly property var stepBack: GridSizes.steppedSize(root.manifest?.grid ?? null,
        root.storedSpan, -1)
    readonly property var stepForward: GridSizes.steppedSize(root.manifest?.grid ?? null,
        root.storedSpan, 1)

    readonly property bool pinned: root.manifest
        ? PluginState.option(root.manifest.id, "positionLocked",
            root.manifest.desktopWidget?.locked === true)
        : false

    function stepSize(direction) {
        if (!root.manifest) return;
        const next = GridSizes.steppedSize(root.manifest.grid ?? null,
            root.storedSpan, direction);
        if (!next) return;
        const id = root.manifest.id;
        const screen = root.screenName;
        const surface = PluginState.currentSurface;
        const before = PluginState.gridSize(id, screen, surface) ?? null;
        GlobalStates.editUndoPush(() => PluginState.setGridSize(id, screen, before, surface));
        PluginState.setGridSize(id, screen, GridSizes.formatSize(next), surface);
    }

    implicitWidth: 260
    implicitHeight: rows.implicitHeight

    GroupedList {
        id: rows
        width: parent.width
        itemVerticalPadding: Appearance.spacing.space200
        bgcolor: Appearance.colors.colLayer0

        Item {
            implicitHeight: 40
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.spacing.space150
                    rightMargin: Appearance.spacing.space150
                }
                spacing: Appearance.spacing.space150
                MaterialSymbol {
                    text: "widgets"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.manifest?.name ?? ""
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
            }
        }

        RippleButton {
            id: pinRow
            objectName: "editMenuPin"
            implicitHeight: 40
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer2
            onClicked: {
                if (!root.manifest) return;
                PluginState.setOption(root.manifest.id, "positionLocked", !root.pinned);
            }
            contentItem: RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.spacing.space150
                    rightMargin: Appearance.spacing.space150
                }
                spacing: Appearance.spacing.space150
                MaterialSymbol {
                    text: "push_pin"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Pin position")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
                MaterialSymbol {
                    visible: root.pinned
                    text: "check"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colPrimary
                }
            }
        }

        Item {
            id: sizeRow
            property bool rowVisible: root.offeredSizes.length > 1
            implicitHeight: 40
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.spacing.space150
                    rightMargin: Appearance.spacing.space150
                }
                spacing: Appearance.spacing.space150
                MaterialSymbol {
                    text: "aspect_ratio"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Size")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
                RippleButton {
                    id: sizeDownButton
                    objectName: "editMenuSizeDown"
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.stepBack !== null
                    onClicked: root.stepSize(-1)
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "chevron_left"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer1
                    }
                }
                StyledText {
                    text: root.currentSize
                        ? `${root.currentSize.cols} × ${root.currentSize.rows}` : ""
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
                RippleButton {
                    id: sizeUpButton
                    objectName: "editMenuSizeUp"
                    implicitWidth: 32
                    implicitHeight: 32
                    enabled: root.stepForward !== null
                    onClicked: root.stepSize(1)
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "chevron_right"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }

        RippleButton {
            id: removeRow
            objectName: "editMenuRemove"
            implicitHeight: 40
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer2
            onClicked: {
                if (!root.manifest) return;
                const before = EditMode.listCopy(Config.options.plugins.enabled);
                GlobalStates.editUndoPush(() =>
                    Config.setNestedValue("plugins.enabled", before));
                Config.setNestedValue("plugins.enabled",
                    EditMode.enabledWithout(Config.options.plugins.enabled, root.manifest.id));
                root.dismissRequested();
            }
            contentItem: RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.spacing.space150
                    rightMargin: Appearance.spacing.space150
                }
                spacing: Appearance.spacing.space150
                MaterialSymbol {
                    text: "delete"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Remove from desktop")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
            }
        }
    }
}
