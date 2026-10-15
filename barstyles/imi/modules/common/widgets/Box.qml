pragma ComponentBehavior: Bound
import QtQuick

Grid {
    id: root
    
    property bool vertical: false
    columns: vertical ? 1 : -1
    rows: vertical ? -1 : 1

    property alias spacing: root.rowSpacing
    columnSpacing: rowSpacing
}
