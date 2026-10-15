import QtQuick
import QtQuick.Layouts
import "../../../.."
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../../common/plugins"
import Quickshell.Hyprland
import "../../../common/functions/screenSelection.js" as ScreenSelection
import "../../../common/functions/layout_ops.js" as LayoutOps

ContentPage {
    id: page
    forceWidth: true

    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
            }

            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }

        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.scrollToY(pos.y)
        }
    }

    function availableFor() {
        return BarWidgets.offerFor([
            ...Config.options.bar.layouts.leftLayout,
            ...Config.options.bar.layouts.middleLayout,
            ...Config.options.bar.layouts.rightLayout
        ], Config.options.bar.borderless)
    }

    function getWidgetName(id) {
        return BarWidgets.nameFor(id)
    }

    ColumnLayout {
        id: mainLayout 
        Layout.fillWidth: true   
        Layout.fillHeight: true
        spacing: Appearance.spacing.space250

        ContentSection {
            id: screensSection
            icon: "monitor"
            shape: MaterialShape.Shape.ClamShell
            title: Translation.tr("Screens")
            readonly property bool chooserMeaningful: Hyprland.monitors.values.length > 1
                || Config.options.bar.screenList.length > 0

            ContentSubsection {
                visible: screensSection.chooserMeaningful
                title: Translation.tr("Show bar on")

                ColumnLayout {
                    id: monitorsCol
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.space25

                    Rectangle {
                        id: allRow
                        Layout.fillWidth: true
                        implicitHeight: allSwitchItem.implicitHeight
                            + Appearance.spacing.space200 + Appearance.spacing.space100
                        color: Appearance.colors.colLayer1
                        topLeftRadius: Appearance.rounding.normal
                        topRightRadius: Appearance.rounding.normal
                        bottomLeftRadius: Appearance.rounding.unsharpenmore
                        bottomRightRadius: Appearance.rounding.unsharpenmore

                        ConfigSwitch {
                            id: allSwitchItem
                            anchors { fill: parent; margins: Appearance.spacing.space100 }
                            buttonIcon: "tv_displays"
                            text: Translation.tr("All")
                            checked: Config.options.bar.screenList.length === 0
                            onToggleRequested: {
                                if (Config.options.bar.screenList.length > 0)
                                    Config.options.bar.screenList = []
                            }
                        }
                    }

                    Repeater {
                        model: Hyprland.monitors
                        delegate: Rectangle {
                            id: monitorRow
                            required property var modelData
                            required property int index
                            readonly property bool isLast: index === Hyprland.monitors.values.length - 1

                            Layout.fillWidth: true
                            implicitHeight: switchItem.implicitHeight
                                + Appearance.spacing.space200 + Appearance.spacing.space100
                            color: Appearance.colors.colLayer1
                            topLeftRadius:     Appearance.rounding.unsharpenmore
                            topRightRadius:    Appearance.rounding.unsharpenmore
                            bottomLeftRadius:  isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                            bottomRightRadius: isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore

                            ConfigSwitch {
                                id: switchItem
                                anchors { fill: parent; margins: Appearance.spacing.space100 }
                                buttonIcon: "monitor"
                                text: monitorRow.modelData.name
                                checked: ScreenSelection.includes(Config.options.bar.screenList, monitorRow.modelData.name)
                                onToggleRequested: {
                                    const allNames = Hyprland.monitors.values.map(m => m.name)
                                    const shown = ScreenSelection.includes(
                                        Config.options.bar.screenList, monitorRow.modelData.name)
                                    const result = ScreenSelection.toggle(
                                        Config.options.bar.screenList, allNames,
                                        monitorRow.modelData.name, !shown)
                                    if (!result.accepted) return
                                    Config.options.bar.screenList = result.list
                                }
                            }
                        }
                    }
                }
            }
            StyledText {
                visible: !screensSection.chooserMeaningful
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Appearance.colors.colSubtext
                text: Translation.tr("Only one screen is connected. With more than one, you can choose which of them show the bar.")
            }
        }

        ContentSection {
            id: barLayoutSection
            icon: "splitscreen_add"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Bar layout")

            property int dragBucket: -1
            property int dragIndex: -1
            readonly property var layoutLists: [leftList, centerList, rightList]

            function storedLayout(bucket) {
                if (bucket === 0) return Config.options.bar.layouts.leftLayout;
                if (bucket === 1) return Config.options.bar.layouts.middleLayout;
                return Config.options.bar.layouts.rightLayout;
            }
            function writeLayout(bucket, list) {
                if (bucket === 0) Config.options.bar.layouts.leftLayout = list;
                else if (bucket === 1) Config.options.bar.layouts.middleLayout = list;
                else Config.options.bar.layouts.rightLayout = list;
            }
            function dropBuckets() {
                const buckets = [];
                for (let b = 0; b < 3; b++)
                    buckets.push(barLayoutSection.layoutLists[b].bucketFor(
                        b === barLayoutSection.dragBucket ? barLayoutSection.dragIndex : -1));
                return buckets;
            }
            function beginDrag(bucket, index) {
                barLayoutSection.dragBucket = bucket;
                barLayoutSection.dragIndex = index;
            }
            function dragMoved(target) {
                for (let b = 0; b < 3; b++) {
                    if (!target || target.bucket !== b) {
                        barLayoutSection.layoutLists[b].gapIndex = -1;
                        continue;
                    }
                    barLayoutSection.layoutLists[b].gapIndex =
                        (b === barLayoutSection.dragBucket)
                            ? LayoutOps.moveTargetForInsertion(barLayoutSection.dragIndex, target.index)
                            : target.index;
                }
            }
            function endDrag() {
                barLayoutSection.dragBucket = -1;
                barLayoutSection.dragIndex = -1;
                for (let b = 0; b < 3; b++)
                    barLayoutSection.layoutLists[b].gapIndex = -1;
            }
            function commitDrop(bucket, index, target) {
                if (!target) return;
                if (target.bucket === bucket) {
                    const dest = LayoutOps.moveTargetForInsertion(index, target.index);
                    if (dest === index) return;
                    barLayoutSection.writeLayout(bucket,
                        LayoutOps.move(barLayoutSection.storedLayout(bucket), index, dest));
                    return;
                }
                const source = barLayoutSection.storedLayout(bucket);
                const id = source[index];
                barLayoutSection.writeLayout(bucket, LayoutOps.remove(source, index));
                barLayoutSection.writeLayout(target.bucket, LayoutOps.insert(
                    barLayoutSection.storedLayout(target.bucket), id, target.index));
            }
            function rowInfoFor(id) {
                const found = BarWidgets.available.find(entry => entry.id === id);
                return { icon: found?.icon ?? "widgets", title: BarWidgets.nameFor(id) };
            }

            component BarLayoutList: ReorderableList {
                id: layoutList
                property int bucket: -1
                Layout.fillWidth: true
                rowFor: id => barLayoutSection.rowInfoFor(id)
                available: page.availableFor()
                addButtonText: Translation.tr("Add widget")
                bucketsProvider: () => barLayoutSection.dropBuckets()
                onRowDragStarted: index => barLayoutSection.beginDrag(layoutList.bucket, index)
                onRowDragMoved: target => barLayoutSection.dragMoved(target)
                onRowDropped: (index, target) => {
                    barLayoutSection.commitDrop(layoutList.bucket, index, target);
                    barLayoutSection.endDrag();
                }
                onRowDragEnded: barLayoutSection.endDrag()
                onAddRequested: id => barLayoutSection.writeLayout(layoutList.bucket,
                    LayoutOps.insert(barLayoutSection.storedLayout(layoutList.bucket),
                        id, barLayoutSection.storedLayout(layoutList.bucket).length))
                onRemoveRequested: index => barLayoutSection.writeLayout(layoutList.bucket,
                    LayoutOps.remove(barLayoutSection.storedLayout(layoutList.bucket), index))
            }

            ContentSubsection {
                title: Config.options.bar.vertical ? Translation.tr("Top") : Translation.tr("Left")
                BarLayoutList {
                    id: leftList
                    bucket: 0
                    model: Config.options.bar.layouts.leftLayout
                }
            }
            ContentSubsection {
                title: Translation.tr("Center")
                BarLayoutList {
                    id: centerList
                    bucket: 1
                    model: Config.options.bar.layouts.middleLayout
                }
            }
            ContentSubsection {
                title: Config.options.bar.vertical ? Translation.tr("Bottom") : Translation.tr("Right")
                BarLayoutList {
                    id: rightList
                    bucket: 2
                    model: Config.options.bar.layouts.rightLayout
                }
            }
        }

        ContentSection {
            icon: "pivot_table_chart"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Positioning & Styles")
            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Bar position")
                    icon: "swap_vert"
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        { displayName: Translation.tr("Top"),    icon: "arrow_upward",   value: 0 },
                        { displayName: Translation.tr("Left"),   icon: "arrow_back",     value: 2 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
                        { displayName: Translation.tr("Right"),  icon: "arrow_forward",  value: 3 }
                    ]
                }
                ConfigSelectionArray {
                    text: Translation.tr("Bar style")
                    icon: "style"
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => { Config.options.bar.cornerStyle = newValue; }
                    options: [
                        { displayName: Translation.tr("Hug"),     icon: "line_curve", value: 0 },
                        { displayName: Translation.tr("Float"),   icon: "view_day",   value: 1 },
                        { displayName: Translation.tr("Islands"), icon: "crop_3_2",   value: 2 },
                        { displayName: Translation.tr("M3"), icon: "interests",   value: 3 },
                        { displayName: Translation.tr("Float Islands"), icon: "view_week", value: 4 }
                    ]
                }
                ConfigSelectionArray {
                    text: Translation.tr("Group style")
                    icon: "tab_group"
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => { Config.options.bar.borderless = newValue; }
                    options: [
                        { displayName: Translation.tr(""),          icon: "block",          value: "transparent" },
                        { displayName: Translation.tr("Pills"),     icon: "pill",           value: "pills" },
                        { displayName: Translation.tr("Separated"), icon: "view_column_2",  value: "separated" }
                    ]
                }
                ConfigRow{
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "variable_insert"
                        text: Translation.tr("Show Background")
                        enabled: Config.options.bar.cornerStyle === 0 || Config.options.bar.cornerStyle === 1 || Config.options.bar.cornerStyle === 4
                        checked: Config.options.bar.showBackground
                        onToggleRequested: Config.options.bar.showBackground = !Config.options.bar.showBackground
                    }
                    ConfigSelectionArray {
                        text: Translation.tr("Autohide")
                        icon: "preview_off"
                        currentValue: Config.options.bar.autoHide.enable
                        onSelected: newValue => { Config.options.bar.autoHide.enable = newValue; }
                        options: [
                            { displayName: Translation.tr("No"),  icon: "close", value: false },
                            { displayName: Translation.tr("Yes"), icon: "check", value: true }
                        ]
                    }
                }
                ConfigSwitch {
                    buttonIcon: "ev_shadow"
                    text: Translation.tr("Bar shadow")
                    enabled: Config.options.bar.showBackground
                        && (Config.options.bar.cornerStyle === 0 || Config.options.bar.cornerStyle === 1 || Config.options.bar.cornerStyle === 4)
                    checked: Config.options.bar.shadow
                    onToggleRequested: Config.options.bar.shadow = !Config.options.bar.shadow
                }
                ConfigSlider {
                    text: Translation.tr("Background opacity")
                    buttonIcon: "opacity"
                    enabled: Config.options.bar.showBackground
                        && Config.options.appearance.transparency.enable
                    value: Config.options.bar.backgroundOpacity
                    from: 0
                    to: 1
                    stopIndicatorValues: [1]
                    onValueModified: {
                        Config.options.bar.backgroundOpacity = newValue;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "cancel_presentation"
                    text: Translation.tr("Auto-dismiss popups on hide")
                    enabled: Config.options.bar.autoHide.enable
                    checked: Config.options.bar.autoHide.dismissPopups
                    onToggleRequested: Config.options.bar.autoHide.dismissPopups = !Config.options.bar.autoHide.dismissPopups
                }
            }
        }


        ContentSection {
            shape: MaterialShape.Shape.Square
            icon: "privacy_tip"
            title: Translation.tr("Privacy")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "block"
                    text: Translation.tr("Allow force stopping an app's capture")
                    checked: Config.options.bar.privacyIndicator.allowForceStop
                    onToggleRequested: Config.options.bar.privacyIndicator.allowForceStop = !Config.options.bar.privacyIndicator.allowForceStop
                }
            }
        }

        ContentSection {
            shape: MaterialShape.Shape.Square
            icon: "inbox_customize"
            title: Translation.tr("Tray")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "keep"; text: Translation.tr("Make icons pinned by default")
                    checked: Config.options.tray.invertPinnedItems
                    onToggleRequested: Config.options.tray.invertPinnedItems = !Config.options.tray.invertPinnedItems
                }
                ConfigSwitch {
                    buttonIcon: "colors"; text: Translation.tr("Tint icons")
                    checked: Config.options.tray.monochromeIcons
                    onToggleRequested: Config.options.tray.monochromeIcons = !Config.options.tray.monochromeIcons
                }
            }
        }

        ContentSection {
            icon: "vertical_align_center"
            shape: MaterialShape.Shape.Diamond
            title: Translation.tr("Divider")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.bar.divider.style
                    onSelected: newValue => { Config.options.bar.divider.style = newValue; }
                    options: [
                        { displayName: Translation.tr("Line"),  icon: "more_vert",       value: "rect" },
                        { displayName: Translation.tr("Dot"),   icon: "fiber_manual_record", value: "dot" },
                        { displayName: Translation.tr("Space"), icon: "space_bar",       value: "space" }
                    ]
                }
                ConfigSpinBox {
                    icon: "width"
                    enabled: Config.options.bar.divider.style === "space"
                    text: Translation.tr("Space width (px)")
                    value: Config.options.bar.divider.spacing
                    from: 4
                    to: 100
                    stepSize: 2
                    onValueModified: {
                        Config.options.bar.divider.spacing = newValue;
                    }
                }
            }
        }

        ContentSection {
            icon: "buttons_alt"
            shape: MaterialShape.Shape.SoftBurst
            title: Translation.tr("Utility buttons")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "screenshot_region"
                        text: Translation.tr("Screen snip")
                        checked: Config.options.bar.utilButtons.showScreenSnip
                        onToggleRequested: Config.options.bar.utilButtons.showScreenSnip = !Config.options.bar.utilButtons.showScreenSnip
                    }
                    ConfigSwitch {
                        buttonIcon: "colorize"
                        text: Translation.tr("Color picker")
                        checked: Config.options.bar.utilButtons.showColorPicker
                        onToggleRequested: Config.options.bar.utilButtons.showColorPicker = !Config.options.bar.utilButtons.showColorPicker
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "keyboard"
                        text: Translation.tr("Keyboard toggle")
                        checked: Config.options.bar.utilButtons.showKeyboardToggle
                        onToggleRequested: Config.options.bar.utilButtons.showKeyboardToggle = !Config.options.bar.utilButtons.showKeyboardToggle
                    }
                    ConfigSwitch {
                        buttonIcon: "mic"
                        text: Translation.tr("Mic toggle")
                        checked: Config.options.bar.utilButtons.showMicToggle
                        onToggleRequested: Config.options.bar.utilButtons.showMicToggle = !Config.options.bar.utilButtons.showMicToggle
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Dark/Light toggle")
                        checked: Config.options.bar.utilButtons.showDarkModeToggle
                        onToggleRequested: Config.options.bar.utilButtons.showDarkModeToggle = !Config.options.bar.utilButtons.showDarkModeToggle
                    }
                    ConfigSwitch {
                        buttonIcon: "speed"
                        text: Translation.tr("Performance Profile")
                        checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                        onToggleRequested: Config.options.bar.utilButtons.showPerformanceProfileToggle = !Config.options.bar.utilButtons.showPerformanceProfileToggle
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "screen_record"
                        text: Translation.tr("Record Screen")
                        checked: Config.options.bar.utilButtons.showScreenRecord
                        onToggleRequested: Config.options.bar.utilButtons.showScreenRecord = !Config.options.bar.utilButtons.showScreenRecord
                    }
                    ConfigSwitch {
                        buttonIcon: "imagesmode"
                        text: Translation.tr("Wallpapers Toggle")
                        checked: Config.options.bar.utilButtons.showWallpaperToggle
                        onToggleRequested: Config.options.bar.utilButtons.showWallpaperToggle = !Config.options.bar.utilButtons.showWallpaperToggle
                    }
                }
            }
        }

        ContentSection {
            shape: MaterialShape.Shape.Cookie12Sided
            icon: "steppers"; title: Translation.tr("Workspaces")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "counter_1"; text: Translation.tr("Always show numbers")
                    checked: Config.options.bar.workspaces.alwaysShowNumbers
                    onToggleRequested: Config.options.bar.workspaces.alwaysShowNumbers = !Config.options.bar.workspaces.alwaysShowNumbers
                }
                ConfigSelectionArray {
                    text: Translation.tr("Numbers style")
                    icon: "looks_3"
                    currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                    onSelected: newValue => {
                        Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Normal"),    icon: "timer_10",        value: '[]' },
                        { displayName: Translation.tr("Han chars"), icon: "glyphs",          value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]' },
                        { displayName: Translation.tr("Roman"),     icon: "account_balance", value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]' }
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "award_star"; text: Translation.tr("Show app icons")
                    checked: Config.options.bar.workspaces.showAppIcons
                    onToggleRequested: Config.options.bar.workspaces.showAppIcons = !Config.options.bar.workspaces.showAppIcons
                }
                ConfigSwitch {
                    buttonIcon: "monitor"; text: Translation.tr("Show workspaces from all monitors")
                    checked: Config.options.bar.workspaces.showAllMonitors
                    onToggleRequested: Config.options.bar.workspaces.showAllMonitors = !Config.options.bar.workspaces.showAllMonitors
                }
                ConfigSpinBox {
                    icon: "view_column"; text: Translation.tr("Workspaces shown")
                    value: Config.options.bar.workspaces.shown
                    from: 1; to: 30
                    onValueModified: { Config.options.bar.workspaces.shown = newValue; }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Indicator style")
                    icon: "page_control"
                    currentValue: Config.options.bar.workspaces.indicatorStyle ?? "icon"
                    onSelected: newValue => {
                        Config.options.bar.workspaces.indicatorStyle = newValue
                    }
                    options: [
                        { displayName: Translation.tr("Dots"),  icon: "radio_button_checked",   value: "dot" },
                        { displayName: Translation.tr("Icons"), icon: "interests",              value: "icon" },
                    ]
                }
            }
        }

        ContentSection {
            icon: "empty_dashboard"
            shape: MaterialShape.Shape.Burst
            title: Translation.tr("Resources")

            GroupedList {
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "planner_review"
                        text: Translation.tr("CPU")
                        checked: Config.options.bar.resources.alwaysShowCpu
                        onToggleRequested: Config.options.bar.resources.alwaysShowCpu = !Config.options.bar.resources.alwaysShowCpu
                    }
                    ConfigSwitch {
                        buttonIcon: "thermostat"
                        text: Translation.tr("CPU Temperature")
                        checked: Config.options.bar.resources.alwaysShowCpuTemp
                        onToggleRequested: Config.options.bar.resources.alwaysShowCpuTemp = !Config.options.bar.resources.alwaysShowCpuTemp
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "memory"
                        text: Translation.tr("RAM")
                        checked: Config.options.bar.resources.alwaysShowRam
                        onToggleRequested: Config.options.bar.resources.alwaysShowRam = !Config.options.bar.resources.alwaysShowRam
                    }
                    ConfigSwitch {
                        buttonIcon: "monitor"
                        text: Translation.tr("GPU")
                        checked: Config.options.bar.resources.alwaysShowGpu
                        onToggleRequested: Config.options.bar.resources.alwaysShowGpu = !Config.options.bar.resources.alwaysShowGpu
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "storage"
                        text: Translation.tr("Disk")
                        checked: Config.options.bar.resources.alwaysShowDisk
                        onToggleRequested: Config.options.bar.resources.alwaysShowDisk = !Config.options.bar.resources.alwaysShowDisk
                    }
                    ConfigSwitch {
                        buttonIcon: "swap_horiz"
                        text: Translation.tr("Swap")
                        checked: Config.options.bar.resources.alwaysShowSwap
                        onToggleRequested: Config.options.bar.resources.alwaysShowSwap = !Config.options.bar.resources.alwaysShowSwap
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "thermostat"
                        text: Translation.tr("GPU Temperature")
                        checked: Config.options.bar.resources.alwaysShowGpuTemp
                        onToggleRequested: Config.options.bar.resources.alwaysShowGpuTemp = !Config.options.bar.resources.alwaysShowGpuTemp
                    }
                    ConfigSwitch {
                        buttonIcon: "memory"
                        text: Translation.tr("VRAM")
                        checked: Config.options.bar.resources.alwaysShowVram
                        onToggleRequested: Config.options.bar.resources.alwaysShowVram = !Config.options.bar.resources.alwaysShowVram
                    }
                }
                ConfigSelectionArray {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.bar.resources.style
                    onSelected: newValue => { Config.options.bar.resources.style = newValue; }
                    options: [
                        { displayName: Translation.tr("Filled"),    icon: "incomplete_circle",  value: "filled" },
                        { displayName: Translation.tr("Outline"),   icon: "circles",            value: "outline" }
                    ]
                }
                ConfigSwitch {
                    buttonIcon: "decimal_increase"; text: Translation.tr("Show Percentage")
                    checked: Config.options.bar.resources.showValue
                    onToggleRequested: Config.options.bar.resources.showValue = !Config.options.bar.resources.showValue
                }
                ConfigSpinBox {
                    icon: "av_timer"
                    text: Translation.tr("Polling interval (ms)")
                    value: Config.options.resources.updateInterval
                    from: 100
                    to: 10000
                    stepSize: 100
                    onValueModified: {
                        Config.options.resources.updateInterval = newValue;
                    }
                }
            }
        }

        ContentSection {
            icon: "music_note"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("Media")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "keep"; text: Translation.tr("Pin media controls")
                    checked: Config.options.bar.media.alwaysVisible
                    onToggleRequested: Config.options.bar.media.alwaysVisible = !Config.options.bar.media.alwaysVisible
                }
                ConfigSwitch {
                    buttonIcon: "titlecase"; text: Translation.tr("Show only title")
                    checked: Config.options.bar.media.onlyTitle
                    onToggleRequested: Config.options.bar.media.onlyTitle = !Config.options.bar.media.onlyTitle
                }
                ConfigSpinBox {
                    icon: "width"
                    text: Translation.tr("Max media width")
                    value: Config.options.bar.media.maxWidth
                    from: 100
                    to: 500
                    stepSize: 10
                    onValueModified: {
                        Config.options.bar.media.maxWidth = newValue;
                    }
                }
            }
        }

        ContentSection {
            shape: MaterialShape.Shape.Puffy
            icon: "tooltip"; title: Translation.tr("Tooltips")
            GroupedList {
                ConfigSwitch {
                    buttonIcon: "ads_click"; text: Translation.tr("Click to show")
                    checked: Config.options.bar.tooltips.clickToShow
                    onToggleRequested: Config.options.bar.tooltips.clickToShow = !Config.options.bar.tooltips.clickToShow
                }
            }
        }
    }
}
