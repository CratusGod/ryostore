pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import shell.services
import shell.modules.sidebar as Kit

Item {
    id: root

    required property var screen
    property real us: 1
    property bool active: false
    property real availableWidth: 420 * us
    property real availableHeight: 720 * us

    property string placement: "top-right"
    signal closeRequested()

    readonly property string currentTab: SidebarState.activeTab(screen)
    readonly property var sections: SidebarState.visibleSections.filter(entry =>
        ["connections", "levels", "bottomControls"].indexOf(entry.id) >= 0)
    readonly property real panelWidth: Math.min(420 * us, availableWidth)
    // header margin + header + gap + body + bottom margin, matching the anchors below
    readonly property real panelHeight: Tokens.s4 * us + header.height + Tokens.s3 * us
        + (currentTab === "controls" ? controlsColumn.implicitHeight : 380 * us) + Tokens.s4 * us
    property real footerImplicitWidth: 0

    implicitWidth: Math.max(panelWidth,
        footerImplicitWidth + Tokens.s4 * us * 2)
    implicitHeight: Math.min(panelHeight, availableHeight)

    function showControls(): void {
        SidebarState.selectTab(root.screen, "controls");
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius * root.us
        color: Tokens.paperLift
        border.width: Tokens.border
        border.color: Tokens.line
        clip: true

        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.s4 * root.us
            height: 32 * root.us

            Rectangle {
                id: backButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 28 * root.us
                height: width
                visible: root.currentTab !== "controls"
                radius: Tokens.radius * root.us
                color: backHover.hovered ? Tokens.tint10 : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fValue * root.us
                }
                HoverHandler { id: backHover }
                TapHandler { onTapped: root.showControls() }
            }

            Text {
                anchors.left: backButton.visible ? backButton.right : parent.left
                anchors.right: closeButton.left
                anchors.leftMargin: backButton.visible ? Tokens.s2 * root.us : 0
                anchors.rightMargin: Tokens.s2 * root.us
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentTab === "wifi" ? I18n.tr("Wi-Fi")
                    : root.currentTab === "bluetooth" ? I18n.tr("Bluetooth")
                    : root.currentTab === "plugins" ? I18n.tr("Extensions")
                    : I18n.tr("Controls")
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: Tokens.fBody * root.us
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 28 * root.us
                height: width
                radius: Tokens.radius * root.us
                color: closeHover.hovered ? Tokens.tint10 : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fBody * root.us
                }
                HoverHandler { id: closeHover }
                TapHandler { onTapped: root.closeRequested() }
            }
        }

        Item {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: Tokens.s4 * root.us
            anchors.rightMargin: Tokens.s4 * root.us
            anchors.topMargin: Tokens.s3 * root.us
            anchors.bottomMargin: Tokens.s4 * root.us

            Flickable {
                anchors.fill: parent
                visible: root.currentTab === "controls"
                clip: true
                contentWidth: width
                contentHeight: controlsColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: controlsColumn
                    width: parent.width
                    spacing: Tokens.s3 * root.us

                    Repeater {
                        model: root.sections

                        delegate: Loader {
                            id: sectionLoader
                            required property var modelData
                            width: controlsColumn.width
                            height: item ? item.implicitHeight : 0
                            sourceComponent: modelData.id === "connections" ? connectionsSection
                                : modelData.id === "levels" ? levelsSection : barSection

                            Binding {
                                target: root
                                property: "footerImplicitWidth"
                                value: sectionLoader.item ? sectionLoader.item.implicitWidth : 0
                                when: sectionLoader.modelData.id === "bottomControls"
                            }
                        }
                    }
                }
            }

            Kit.ControlsBoard {
                anchors.fill: parent
                visible: root.currentTab === "wifi" || root.currentTab === "bluetooth"
                s: root.us
                screen: root.screen
                active: root.active && visible
                page: root.currentTab
                onRequestClose: root.closeRequested()
            }

            Kit.ExtensionsBoard {
                anchors.fill: parent
                visible: root.currentTab === "plugins"
                s: root.us
                plugins: pluginHost.cards()
                active: root.active && visible
                onRequestClose: root.closeRequested()
            }
        }
    }

    Kit.SidebarPlugins {
        id: pluginHost
        active: root.active && root.currentTab === "plugins"
    }

    Component {
        id: connectionsSection
        Kit.ControlsConnections {
            width: controlsColumn.width
            s: root.us
            screen: root.screen
            active: root.active && root.currentTab === "controls"
            onOpenPage: page => SidebarState.selectTab(root.screen, page)
        }
    }

    Component {
        id: levelsSection
        Kit.ControlsLevels {
            width: controlsColumn.width
            s: root.us
            screen: root.screen
            active: root.active && root.currentTab === "controls"
        }
    }

    Component {
        id: barSection
        Kit.ControlsBar {
            width: controlsColumn.width
            s: root.us
            screen: root.screen
            active: root.active && root.currentTab === "controls"
            onSession: action => {
                root.closeRequested();
                SessionActions.run(action);
            }
            onOpenExtensions: SidebarState.selectTab(root.screen, "plugins")
            onRequestClose: root.closeRequested()
        }
    }
}
