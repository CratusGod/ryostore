import QtQuick
import QtQuick.Layouts
import ".."
import "."

ColumnLayout {
    id: root
    property bool expanded: true
    property int currentIndex: 0
    spacing: Appearance.spacing.space100
}
