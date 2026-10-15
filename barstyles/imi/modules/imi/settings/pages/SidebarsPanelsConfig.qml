import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import "../../../../services"
import "../../../common"
import "../../../common/functions"
import "../../../common/widgets"

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

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.space200

        ContentSection {
            icon: "splitscreen_left"
            shape: MaterialShape.Shape.Clover4Leaf
            title: Translation.tr("Left Sidebar")

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space100

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: mediaCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: Appearance.borderWidth.standard
                    border.color: "transparent"

                    ColumnLayout {
                        id: mediaCol
                        anchors { fill: parent; margins: Appearance.spacing.space150 }
                        spacing: Appearance.spacing.space100

                        MaterialSymbol {
                            text: "music_note"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: Translation.tr("Media Player")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        Item { Layout.fillHeight: true }
                        GroupedList {
                            Layout.fillWidth: true
                            bgcolor: Appearance.colors.colLayer2
                            ConfigSwitch {
                                buttonIcon: "check"
                                text: Translation.tr("Enable")
                                checked: Config.options.sidebar.media.enable
                                onToggleRequested: Config.options.sidebar.media.enable = !Config.options.sidebar.media.enable
                            }
                            ConfigSwitch {
                                buttonIcon: "radio_button_partial"
                                text: Translation.tr("Follow Album Colors")
                                checked: Config.options.sidebar.media.artColors
                                onToggleRequested: Config.options.sidebar.media.artColors = !Config.options.sidebar.media.artColors
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.space100

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: aiCol.implicitHeight + 24
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        border.width: Appearance.borderWidth.standard
                        border.color: "transparent"

                        ColumnLayout {
                            id: aiCol
                            anchors { fill: parent; margins: Appearance.spacing.space150 }
                            spacing: Appearance.spacing.space100

                            MaterialSymbol {
                                text: "smart_toy"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("AI")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            ConfigSelectionArray {
                                Layout.fillWidth: false
                                Layout.alignment: Qt.AlignRight
                                currentValue: Config.options.policies.ai
                                onSelected: newValue => { Config.options.policies.ai = newValue }
                                options: [
                                    { displayName: Translation.tr("No"), icon: "close", value: 0 },
                                    { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                                    { displayName: Translation.tr("Local"), icon: "sync_saved_locally", value: 2 }
                                ]
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: weebCol.implicitHeight + 24
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        border.width: Appearance.borderWidth.standard
                        border.color: "transparent"

                        ColumnLayout {
                            id: weebCol
                            anchors { fill: parent; margins: Appearance.spacing.space150 }
                            spacing: Appearance.spacing.space100

                            MaterialSymbol {
                                text: "playing_cards"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("Weeb")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            ConfigSelectionArray {
                                Layout.fillWidth: false
                                Layout.alignment: Qt.AlignRight
                                currentValue: Config.options.policies.weeb
                                onSelected: newValue => { Config.options.policies.weeb = newValue }
                                options: [
                                    { displayName: Translation.tr("No"), icon: "close", value: 0 },
                                    { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                                    { displayName: Translation.tr("Closet"), icon: "ev_shadow", value: 2 }
                                ]
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.space50
                implicitHeight: phoneCol.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: Appearance.borderWidth.standard
                border.color: "transparent"

                ColumnLayout {
                    id: phoneCol
                    anchors { fill: parent; margins: Appearance.spacing.space150 }
                    spacing: Appearance.spacing.space100

                    RowLayout {
                        spacing: Appearance.spacing.space100
                        ConfigSwitch {
                            buttonIcon: "smartphone"
                            text: Translation.tr("Enable Phone")
                            infoText: Translation.tr("Shows the paired phone in the left sidebar and mirrors its notifications there instead of on the desktop.")
                            checked: Config.options.sidebar.phone.enable
                            onToggleRequested: Config.options.sidebar.phone.enable = !Config.options.sidebar.phone.enable
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.space50
                implicitHeight: translatorCol.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: Appearance.borderWidth.standard
                border.color: "transparent"

                ColumnLayout {
                    id: translatorCol
                    anchors { fill: parent; margins: Appearance.spacing.space150 }
                    spacing: Appearance.spacing.space100

                    RowLayout {
                        spacing: Appearance.spacing.space100
                        ConfigSwitch {
                            buttonIcon: "translate"
                            text: Translation.tr("Enable Translator")
                            checked: Config.options.sidebar.translator.enable
                            onToggleRequested: Config.options.sidebar.translator.enable = !Config.options.sidebar.translator.enable
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "splitscreen_right"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Right Sidebar")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "planner_banner_ad_pt"
                    text: Translation.tr('Banner')
                    checked: Config.options.sidebar.banner
                    onToggleRequested: Config.options.sidebar.banner = !Config.options.sidebar.banner
                }

                ConfigSwitch {
                    buttonIcon: "music_note"
                    text: Translation.tr('Media Player')
                    checked: Config.options.sidebar.mediaPlayer
                    onToggleRequested: Config.options.sidebar.mediaPlayer = !Config.options.sidebar.mediaPlayer
                }

                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr('Keep right sidebar loaded')
                    checked: Config.options.sidebar.keepRightSidebarLoaded
                    onToggleRequested: Config.options.sidebar.keepRightSidebarLoaded = !Config.options.sidebar.keepRightSidebarLoaded
                }
            }

            ContentSubsection {
                title: Translation.tr("Quick toggles")
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Style")
                        icon: "toggle_on"
                        Layout.fillWidth: false
                        currentValue: Config.options.sidebar.quickToggles.style
                        onSelected: newValue => {
                            Config.options.sidebar.quickToggles.style = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Classic"),
                                icon: "password_2",
                                value: "classic"
                            },
                            {
                                displayName: Translation.tr("Android"),
                                icon: "action_key",
                                value: "android"
                            }
                        ]
                    }
                    ConfigSpinBox {
                        enabled: Config.options.sidebar.quickToggles.style === "android"
                        icon: "add_column_left"
                        text: Translation.tr("Columns")
                        value: Config.options.sidebar.quickToggles.android.columns
                        from: 1
                        to: 8
                        stepSize: 1
                        onValueModified: {
                            Config.options.sidebar.quickToggles.android.columns = newValue;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Sliders")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.sidebar.quickSliders.enable
                        onToggleRequested: Config.options.sidebar.quickSliders.enable = !Config.options.sidebar.quickSliders.enable
                    }

                    ConfigSwitch {
                        buttonIcon: "brightness_6"
                        text: Translation.tr("Brightness")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showBrightness
                        onToggleRequested: Config.options.sidebar.quickSliders.showBrightness = !Config.options.sidebar.quickSliders.showBrightness
                    }

                    ConfigSwitch {
                        buttonIcon: "volume_up"
                        text: Translation.tr("Volume")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showVolume
                        onToggleRequested: Config.options.sidebar.quickSliders.showVolume = !Config.options.sidebar.quickSliders.showVolume
                    }

                    ConfigSwitch {
                        buttonIcon: "mic"
                        text: Translation.tr("Microphone")
                        enabled: Config.options.sidebar.quickSliders.enable
                        checked: Config.options.sidebar.quickSliders.showMic
                        onToggleRequested: Config.options.sidebar.quickSliders.showMic = !Config.options.sidebar.quickSliders.showMic
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Corner open")

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.sidebar.cornerOpen.enable
                        onToggleRequested: Config.options.sidebar.cornerOpen.enable = !Config.options.sidebar.cornerOpen.enable
                    }
                    ConfigSwitch {
                        buttonIcon: "highlight_mouse_cursor"
                        text: Translation.tr("Hover to trigger")
                        checked: Config.options.sidebar.cornerOpen.clickless
                        onToggleRequested: Config.options.sidebar.cornerOpen.clickless = !Config.options.sidebar.cornerOpen.clickless
                    }
                    ConfigSwitch {
                        buttonIcon: "vertical_align_bottom"
                        text: Translation.tr("Place at bottom")
                        checked: Config.options.sidebar.cornerOpen.bottom
                        onToggleRequested: Config.options.sidebar.cornerOpen.bottom = !Config.options.sidebar.cornerOpen.bottom
                    }
                    ConfigSwitch {
                        buttonIcon: "unfold_more_double"
                        text: Translation.tr("Value scroll")
                        checked: Config.options.sidebar.cornerOpen.valueScroll
                        onToggleRequested: Config.options.sidebar.cornerOpen.valueScroll = !Config.options.sidebar.cornerOpen.valueScroll
                    }
                    ConfigSwitch {
                        buttonIcon: "visibility"
                        text: Translation.tr("Visualize region")
                        checked: Config.options.sidebar.cornerOpen.visualize
                        onToggleRequested: Config.options.sidebar.cornerOpen.visualize = !Config.options.sidebar.cornerOpen.visualize
                    }
                    ConfigSwitch {
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        buttonIcon: "ads_click"
                        text: Translation.tr("Force hover at absolute corner")
                        checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                        onToggleRequested: Config.options.sidebar.cornerOpen.clicklessCornerEnd = !Config.options.sidebar.cornerOpen.clicklessCornerEnd
                    }
                    ConfigSpinBox {
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        icon: "arrow_cool_down"
                        text: Translation.tr("Vertical offset")
                        value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                        from: 0; to: 20; stepSize: 1
                        onValueModified: { Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = newValue }
                    }
                    ConfigSpinBox {
                        icon: "arrow_range"
                        text: Translation.tr("Region width")
                        value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                        from: 1; to: 300; stepSize: 1
                        onValueModified: { Config.options.sidebar.cornerOpen.cornerRegionWidth = newValue }
                    }
                    ConfigSpinBox {
                        icon: "height"
                        text: Translation.tr("Region height")
                        value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                        from: 1; to: 300; stepSize: 1
                        onValueModified: { Config.options.sidebar.cornerOpen.cornerRegionHeight = newValue }
                    }
                }
            }
        }
    }
}
