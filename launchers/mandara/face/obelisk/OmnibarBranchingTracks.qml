/* OmnibarBranchingTracks.qml
 * Quantum Superposition — BranchingTracks from the TSX.
 * When the query contains [opt1|opt2], renders each resolved timeline
 * as a separate track row below the input.
 */
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string query: ""

    signal trackSelected(string resolved)

    // Parse [opt1|opt2|...] from query
    property var options: {
        var m = query.match(/\[(.*?)\]/)
        if (!m) return []
        return m[1].split("|")
    }

    property string baseQuery: {
        var m = query.match(/\[(.*?)\]/)
        if (!m) return query
        return query  // kept for replacement below
    }

    visible:        options.length > 1
    implicitHeight: visible ? trackCol.implicitHeight : 0
    Behavior on implicitHeight { NumberAnimation { duration: 180 } }

    Column {
        id: trackCol
        width: parent.width
        spacing: 6
        topPadding: 8

        Repeater {
            model: root.options

            delegate: RowLayout {
                width: trackCol.width
                spacing: 10

                // Branch connector
                Item {
                    width: 32; height: 1
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 1
                        color: Qt.alpha("#6366f1", 0.188)
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4; height: 4; radius: 2
                        color: "#818cf8"
                    }
                }

                // Timeline pill
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 10
                    color:  trackHover.containsMouse ? Qt.rgba(0.38, 0.40, 0.98, 0.12) : Qt.rgba(0, 0, 0, 0.4)
                    border.color: trackHover.containsMouse ? Qt.alpha("#6366f1", 0.314) : Qt.alpha("#6366f1", 0.125)
                    border.width: 1
                    Behavior on color        { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        Text {
                            text:  "Resolved Timeline " + (index + 1) + ":"
                            color: Qt.alpha("#ffffff", 0.188)
                            font.family:    "monospace"
                            font.pixelSize: 9
                        }

                        Text {
                            Layout.fillWidth: true
                            // Replace [opt1|opt2] with this option
                            text: {
                                var m = root.query.match(/\[.*?\]/)
                                return m ? root.query.replace(m[0], modelData) : root.query
                            }
                            color: "#818cf8"
                            font.family:    "monospace"
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 4; height: 4; radius: 2
                            color: trackHover.containsMouse ? "#818cf8" : Qt.alpha("#6366f1", 0.188)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 900 }
                                NumberAnimation { to: 1.0; duration: 900 }
                            }
                        }
                    }

                    MouseArea {
                        id: trackHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            var m = root.query.match(/\[.*?\]/)
                            root.trackSelected(m ? root.query.replace(m[0], modelData) : root.query)
                        }
                    }
                }
            }
        }
    }
}
