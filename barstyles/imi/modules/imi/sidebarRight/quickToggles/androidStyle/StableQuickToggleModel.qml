import QtQuick
import "../../../../common/functions/quick_toggle_layout.js" as QuickToggleLayout

ListModel {
    id: root

    property int gridRows: 0

    function sync(entries, columns) {
        const desired = QuickToggleLayout.pack(entries, columns);

        const current = [];
        for (let i = 0; i < root.count; i++) current.push(root.get(i));

        for (const op of QuickToggleLayout.syncPlan(current, desired)) {
            if (op.op === "remove") root.remove(op.index, 1);
            else if (op.op === "insert") root.insert(op.index, op.entry);
            else if (op.op === "move") root.move(op.from, op.to, 1);
            else if (op.op === "update") {
                for (const role of QuickToggleLayout.PAYLOAD_ROLES)
                    root.setProperty(op.index, role, op.entry[role]);
            }
        }

        root.gridRows = QuickToggleLayout.rowCount(desired);
    }
}
