/* CommandReference.qml — Inline Command Matrix UI
 * =================================================
 * A searchable, category-based command reference for the Launcher.
 * Pulls from the CommandMatrix singleton.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../tw" as TW
import "./" as Runes

Item {
    id: root
    
    property color  morphColor: TW.SiMOrchestrator.prismaticColor
    property string activeMode: "moon"
    
    signal commandSelected(string cmd)

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // ── Category Selector ──
        Row {
            Layout.fillWidth: true
            spacing: 8
            
            Repeater {
                model: ["sun", "moon", "celestial"]
                delegate: Rectangle {
                    width: 32; height: 32; radius: 16
                    color: root.activeMode === modelData ? Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.2) : "transparent"
                    border.color: root.activeMode === modelData ? root.morphColor : Qt.rgba(1, 1, 1, 0.1)
                    
                    Text {
                        anchors.centerIn: parent
                        text: Runes.CommandMatrix.modes[modelData].icon
                        color: root.activeMode === modelData ? root.morphColor : "#888"
                        font.pixelSize: 14
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.activeMode = modelData
                    }
                    
                    ToolTip.visible: ma.containsMouse
                    ToolTip.text: Runes.CommandMatrix.modes[modelData].desc
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }

        // ── Mode Description ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: Runes.CommandMatrix.modes[root.activeMode].id.toUpperCase()
                color: root.morphColor
                font.family: TW.TransparentWorld.fontFamilyMono
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 2
            }
            Text {
                text: "— " + Runes.CommandMatrix.modes[root.activeMode].desc
                color: TW.TransparentWorld.textDim
                font.family: TW.TransparentWorld.fontFamily
                font.pixelSize: 10
            }
        }

        // ── Commands List ──
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: Runes.CommandMatrix.getCommands(root.activeMode)

            delegate: Rectangle {
                width: parent.width
                height: 36
                color: maRow.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12

                    Text {
                        text: modelData.cmd
                        color: "white"
                        font.family: TW.TransparentWorld.fontFamilyMono
                        font.pixelSize: 12
                        Layout.preferredWidth: 160
                    }

                    Text {
                        text: modelData.desc
                        color: TW.TransparentWorld.textDim
                        font.family: TW.TransparentWorld.fontFamily
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: !!modelData.badge
                        width: _badgeTxt.implicitWidth + 12
                        height: 18
                        radius: 4
                        color: "transparent"
                        border.color: modelData.badge ? modelData.badge.color : "transparent"
                        Text {
                            id: _badgeTxt
                            anchors.centerIn: parent
                            text: modelData.badge ? modelData.badge.text : ""
                            color: parent.border.color
                            font.family: TW.TransparentWorld.fontFamilyMono
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                MouseArea {
                    id: maRow
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.commandSelected(modelData.cmd)
                }
            }
        }
    }
}
