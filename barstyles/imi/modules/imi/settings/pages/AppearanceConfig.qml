import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common"
import "../../../common/functions"
import "../../../common/widgets"

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "opacity"
        title: Translation.tr("Surfaces")

        GroupedList {
            ConfigSwitch {
                buttonIcon: "layers"
                text: Translation.tr("Transparency")
                description: Translation.tr("Let the wallpaper show through the shell's plates")
                checked: Config.options.appearance.transparency.enable
                onToggleRequested: Config.options.appearance.transparency.enable = !Config.options.appearance.transparency.enable
            }
            ConfigSwitch {
                buttonIcon: "auto_awesome"
                text: Translation.tr("Automatic")
                description: Translation.tr("Derive the amount from the wallpaper's own colour")
                enabled: Config.options.appearance.transparency.enable
                checked: Config.options.appearance.transparency.automatic
                onToggleRequested: Config.options.appearance.transparency.automatic = !Config.options.appearance.transparency.automatic
            }
            ConfigSlider {
                Layout.fillWidth: true
                text: Translation.tr("Background")
                buttonIcon: "wallpaper"
                enabled: Config.options.appearance.transparency.enable
                    && !Config.options.appearance.transparency.automatic
                value: Config.options.appearance.transparency.backgroundTransparency
                from: 0
                to: 1
                stopIndicatorValues: [0, 1]
                onValueModified: newValue => {
                    Config.options.appearance.transparency.backgroundTransparency = newValue;
                }
            }
            ConfigSlider {
                Layout.fillWidth: true
                text: Translation.tr("Content")
                buttonIcon: "layers"
                enabled: Config.options.appearance.transparency.enable
                    && !Config.options.appearance.transparency.automatic
                value: Config.options.appearance.transparency.contentTransparency
                from: 0
                to: 1
                stopIndicatorValues: [0, 1]
                onValueModified: newValue => {
                    Config.options.appearance.transparency.contentTransparency = newValue;
                }
            }
            ConfigSwitch {
                buttonIcon: "palette"
                text: Translation.tr("Tint the background")
                description: Translation.tr("Pull the plate's base towards the theme's primary")
                checked: Config.options.appearance.extraBackgroundTint
                onToggleRequested: Config.options.appearance.extraBackgroundTint = !Config.options.appearance.extraBackgroundTint
            }
            ConfigSelectionArray {
                text: Translation.tr("Screen corners")
                icon: "rounded_corner"
                currentValue: Config.options.appearance.fakeScreenRounding
                options: [
                    { displayName: Translation.tr("Off"), icon: "crop_square", value: 0 },
                    { displayName: Translation.tr("Always"), icon: "check", value: 1 },
                    { displayName: Translation.tr("Not fullscreen"), icon: "fullscreen_exit", value: 2 }
                ]
                onSelected: newValue => {
                    Config.options.appearance.fakeScreenRounding = newValue;
                }
            }
        }
    }

    ContentSection {
        icon: "animation"
        title: Translation.tr("Motion")

        GroupedList {
            ConfigSlider {
                Layout.fillWidth: true
                text: Translation.tr("Animation speed")
                buttonIcon: "speed"
                enabled: !Config.options.appearance.motion.reduceMotion
                value: Config.options.appearance.motion.multiplier
                usePercentTooltip: false
                from: 0.5
                to: 2.5
                stopIndicatorValues: [1]
                onValueModified: newValue => {
                    Config.options.appearance.motion.multiplier = newValue;
                }
            }
            ConfigSwitch {
                buttonIcon: "accessibility_new"
                text: Translation.tr("Reduce motion")
                checked: Config.options.appearance.motion.reduceMotion
                onToggleRequested: Config.options.appearance.motion.reduceMotion = !Config.options.appearance.motion.reduceMotion
            }
        }
    }
}
