/* OmnibarGuardianBadge.qml
 * Guardian syntax pre-validator alert badge.
 * Shows warning + auto-fix button when a bad IP octet or typo is detected.
 */
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string message:  ""
    property string autoFix:  ""

    signal applyFix(string fixed)

    visible: message !== ""
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    height:  visible ? guardianRow.implicitHeight + 20 : 0
    Behavior on height { NumberAnimation { duration: 150 } }

    radius: 16
    color:  Qt.alpha("#1a0f00", 0.8)
    border.color: Qt.alpha("#f59e0b", 0.376)
    border.width: 1

    RowLayout {
        id: guardianRow
        anchors.centerIn: parent
        spacing: 12

        Text {
            text:  "⚠"
            color: "#f59e0b"
            font.pixelSize: 14
        }

        Text {
            text:  root.message
            color: "#fde68a"
            font.family:      "monospace"
            font.pixelSize:   10
            font.bold:        true
            font.letterSpacing: 1
        }

        Rectangle {
            visible: root.autoFix !== ""
            width:  fixLabel.implicitWidth + 16
            height: 24
            radius: 8
            color:  fixHover.containsMouse ? Qt.alpha("#f59e0b", 0.251) : Qt.alpha("#f59e0b", 0.125)
            border.color: Qt.alpha("#f59e0b", 0.502)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: fixLabel
                anchors.centerIn: parent
                text:  "AUTHORIZE AUTO-FIX"
                color: "#fde68a"
                font.family:      "monospace"
                font.pixelSize:   8
                font.bold:        true
                font.letterSpacing: 2
            }

            MouseArea {
                id: fixHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.applyFix(root.autoFix)
            }
        }
    }
}
