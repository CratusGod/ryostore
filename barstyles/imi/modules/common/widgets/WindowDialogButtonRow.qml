import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../functions"
import "."

RowLayout {
    id: root
    spacing: Appearance.spacing.space100

    readonly property bool hasFilledAction: {
        for (const child of root.children)
            if (child.dialogActionFilled === true)
                return true;
        return false;
    }
}
