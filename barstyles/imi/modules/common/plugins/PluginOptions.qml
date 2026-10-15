pragma ComponentBehavior: Bound

import QtQuick
import "../../../services"
import QtQuick.Layouts
import ".."
import "../widgets"
import "gridSizes.js" as GridSizes

ColumnLayout {
    id: root

    required property var manifest
    spacing: Appearance.spacing.space25

    readonly property var widgetOptions: manifest.options || []

    readonly property bool hasBlurSurface: manifest.desktopWidget !== undefined
    readonly property var behaviourRows: hasBlurSurface ? [{
        key: "blurEnabled",
        type: "boolean",
        label: "Blur background",
        icon: "blur_on",
        default: manifest.blur?.default ?? (manifest.desktopWidget?.blur === true)
    }, {
        key: "positionLocked",
        type: "boolean",
        label: "Lock position",
        icon: "lock",
        default: manifest.desktopWidget?.locked === true
    }, {
        key: "clickThrough",
        type: "boolean",
        label: "Click through",
        icon: "do_not_touch",
        default: manifest.desktopWidget?.clickThrough === true
    }, {
        key: "keepTranslucent",
        type: "boolean",
        label: "Stay translucent",
        icon: "opacity",
        default: manifest.desktopWidget?.keepTranslucent === true
    }, {
        key: "followParallax",
        type: "boolean",
        label: "Follow parallax",
        icon: "panorama_horizontal",
        default: manifest.desktopWidget?.followParallax !== false
    }] : []

    readonly property var offeredSizes: GridSizes.offeredSizes(manifest.grid)
    readonly property var sizeRows: root.offeredSizes.length > 1 ? [{
        key: "__gridSize",
        type: "choice",
        label: "Size",
        icon: "aspect_ratio",
        default: GridSizes.formatSize(GridSizes.defaultSize(manifest.grid)),
        choices: root.offeredSizes.map(size => ({
            displayName: `${size.cols} × ${size.rows}`,
            value: GridSizes.formatSize(size)
        }))
    }] : []

    Repeater {
        model: root.widgetOptions
        delegate: optionRow
    }

    ContentSubsection {
        id: behaviourSection
        title: Translation.tr("Widget behaviour")

        readonly property string presetPersistLabel: Translation.tr("Keep settings across presets")

        property string hoveredLabel: ""

        readonly property string enabledLabels: {
            const on = [];
            if (PluginState.presetPersisted(root.manifest.id))
                on.push(behaviourSection.presetPersistLabel);
            for (let index = 0; index < root.behaviourRows.length; ++index) {
                const behaviourRow = root.behaviourRows[index];
                if (PluginState.option(root.manifest.id, behaviourRow.key, behaviourRow.default))
                    on.push(behaviourRow.label);
            }
            return on.join("  ·  ");
        }

        FlowButtonGroup {
            id: behaviourBar
            Layout.fillWidth: true
            spacing: Appearance.spacing.space50

            BehaviourToggle {
                id: presetPersistToggle
                label: behaviourSection.presetPersistLabel
                buttonIcon: "push_pin"
                toggled: PluginState.presetPersisted(root.manifest.id)
                onClicked: PluginState.setPresetPersist(root.manifest.id,
                    !PluginState.presetPersisted(root.manifest.id))
            }

            Repeater {
                model: root.behaviourRows
                delegate: BehaviourToggle {
                    required property var modelData
                    label: modelData.label
                    buttonIcon: modelData.icon
                    toggled: PluginState.option(root.manifest.id, modelData.key, modelData.default)
                    onClicked: PluginState.setOption(root.manifest.id, modelData.key,
                        !PluginState.option(root.manifest.id, modelData.key, modelData.default))
                }
            }
        }

        StyledText {
            id: behaviourCaption
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: behaviourSection.hoveredLabel.length > 0
                ? behaviourSection.hoveredLabel
                : (behaviourSection.enabledLabels.length > 0
                    ? Translation.tr("On: %1").arg(behaviourSection.enabledLabels)
                    : Translation.tr("Nothing on"))
        }

        Repeater {
            model: root.sizeRows
            delegate: optionRow
        }
    }

    component BehaviourToggle: IconToolbarButton {
        id: toggle
        property string label: ""
        property string buttonIcon: "tune"

        implicitHeight: 40
        text: toggle.buttonIcon

        onHoveredChanged: {
            if (toggle.hovered)
                behaviourSection.hoveredLabel = toggle.label;
            else if (behaviourSection.hoveredLabel === toggle.label)
                behaviourSection.hoveredLabel = "";
        }
    }

    Component {
        id: optionRow

        Loader {
            id: optionLoader
            required property var modelData
            Layout.fillWidth: true
            property var optionData: modelData
            visible: !optionData.enabledWhen
                || PluginState.option(root.manifest.id, optionData.enabledWhen, false)
            enabled: visible
            Layout.preferredHeight: visible ? implicitHeight : 0

            sourceComponent: {
                switch (optionData.type) {
                case "boolean": return booleanOption;
                case "choice": return choiceOption;
                case "shape": return shapeOption;
                case "color": return colorOption;
                case "number": return numberOption;
                case "text": return textOption;
                default: return null;
                }
            }

            Component {
                id: booleanOption
                ConfigSwitch {
                    Layout.fillWidth: true
                    leftPadding: 0
                    rightPadding: 0
                    buttonIcon: optionLoader.optionData.icon || "tune"
                    text: optionLoader.optionData.label
                    checked: PluginState.option(root.manifest.id, optionLoader.optionData.key, optionLoader.optionData.default)
                    onToggleRequested: PluginState.setOption(root.manifest.id, optionLoader.optionData.key,
                        !PluginState.option(root.manifest.id, optionLoader.optionData.key, optionLoader.optionData.default))
                }
            }

            Component {
                id: choiceOption
                ConfigSelectionArray {
                    Layout.fillWidth: true
                    text: optionLoader.optionData.label
                    icon: optionLoader.optionData.icon || "tune"
                    options: optionLoader.optionData.choices || []
                    currentValue: PluginState.option(root.manifest.id, optionLoader.optionData.key, optionLoader.optionData.default)
                    onSelected: value => PluginState.setOption(root.manifest.id, optionLoader.optionData.key, value)
                }
            }

            Component {
                id: shapeOption
                ConfigSelectionShapeArray {
                    options: (optionLoader.optionData.choices || [])
                        .map(choice => choice.value ?? choice)
                    currentValue: PluginState.option(root.manifest.id, optionLoader.optionData.key, optionLoader.optionData.default)
                    onSelected: value => PluginState.setOption(root.manifest.id, optionLoader.optionData.key, value)
                }
            }

            Component {
                id: colorOption
                ColorSelectionArray {
                    icon: optionLoader.optionData.icon || "palette"
                    text: optionLoader.optionData.label
                    options: (optionLoader.optionData.choices || [])
                        .map(choice => choice.value ?? choice)
                    currentValue: PluginState.option(root.manifest.id, optionLoader.optionData.key, optionLoader.optionData.default)
                    onSelected: value => PluginState.setOption(root.manifest.id, optionLoader.optionData.key, value)
                }
            }

            Component {
                id: numberOption
                ConfigSlider {
                    Layout.fillWidth: true
                    text: optionLoader.optionData.label
                    textWidth: optionLoader.optionData.labelWidth ?? 176
                    buttonIcon: optionLoader.optionData.icon || "tune"
                    usePercentTooltip: optionLoader.optionData.usePercentTooltip === true
                        || (optionLoader.optionData.to ?? 100) <= 1
                    from: optionLoader.optionData.from ?? 0
                    to: optionLoader.optionData.to ?? 100
                    value: PluginState.option(root.manifest.id, optionLoader.optionData.key, optionLoader.optionData.default)
                    onValueModified: {
                        const step = optionLoader.optionData.step ?? 1;
                        const rounded = Math.round(newValue / step) * step;
                        if (rounded !== PluginState.option(root.manifest.id, optionLoader.optionData.key, optionLoader.optionData.default))
                            PluginState.setOption(root.manifest.id, optionLoader.optionData.key, rounded);
                    }
                }
            }

            Component {
                id: textOption
                ConfigTextArea {
                    Layout.fillWidth: true
                    buttonIcon: optionLoader.optionData.icon || "text_fields"
                    text: optionLoader.optionData.label
                    placeholderText: optionLoader.optionData.placeholder || ""
                    fieldWidth: 160
                    value: String(PluginState.option(root.manifest.id,
                        optionLoader.optionData.key, optionLoader.optionData.default))
                    onValueChanged: {
                        const trimmed = value.trim();
                        if (trimmed.length === 0) return;
                        const transformed = optionLoader.optionData.uppercase === true
                            ? trimmed.toUpperCase() : trimmed;
                        const normalized = transformed.slice(0, optionLoader.optionData.maxLength ?? 64);
                        if (normalized !== PluginState.option(root.manifest.id,
                                optionLoader.optionData.key, optionLoader.optionData.default))
                            PluginState.setOption(root.manifest.id, optionLoader.optionData.key, normalized);
                    }
                }
            }
        }
    }
}
