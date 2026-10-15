.pragma library

.import "layout_ops.js" as LayoutOps


function sizeOf(entry) {
    var size = Math.round(Number(entry && entry.size));
    return (isFinite(size) && size >= 1) ? size : 1;
}

function columnsOf(columns) {
    var count = Math.floor(Number(columns));
    return (isFinite(count) && count >= 1) ? count : 1;
}

function idFor(type, occurrence) {
    return occurrence === 1 ? type : type + "#" + occurrence;
}

function pack(entries, columns) {
    var cols = columnsOf(columns);
    var packed = [];
    var occurrences = {};
    var row = 0;
    var used = 0;

    for (var i = 0; i < (entries ? entries.length : 0); i++) {
        var entry = entries[i];
        if (!entry || !entry.type) continue;

        var size = sizeOf(entry);
        if (used > 0 && used + size > cols) {
            row++;
            used = 0;
        }

        var occurrence = (occurrences[entry.type] || 0) + 1;
        occurrences[entry.type] = occurrence;

        packed.push({
            itemId: idFor(entry.type, occurrence),
            type: entry.type,
            size: size,
            layoutRow: row,
            layoutSlot: used,
            sourceIndex: i
        });
        used += size;
    }

    return packed;
}

function cellWidth(contentWidth, spacing, columns) {
    var cols = columnsOf(columns);
    return (contentWidth - spacing * (cols - 1)) / cols;
}

function rowCount(packed) {
    if (!packed || packed.length === 0) return 0;
    return packed[packed.length - 1].layoutRow + 1;
}

var PAYLOAD_ROLES = ["size", "layoutRow", "layoutSlot", "sourceIndex"];
var IDENTITY_ROLES = ["itemId", "type"];

function indexOfId(rows, itemId) {
    for (var i = 0; i < rows.length; i++) {
        if (rows[i].itemId === itemId) return i;
    }
    return -1;
}

function payloadDiffers(row, wanted) {
    for (var i = 0; i < PAYLOAD_ROLES.length; i++) {
        var role = PAYLOAD_ROLES[i];
        if (row[role] !== wanted[role]) return true;
    }
    return false;
}

function syncPlan(current, desired) {
    var ops = [];
    var mirror = (current || []).map(function (row) {
        var copy = {};
        IDENTITY_ROLES.concat(PAYLOAD_ROLES).forEach(function (role) {
            copy[role] = row[role];
        });
        return copy;
    });
    var wantedList = desired || [];

    var wanted = {};
    for (var w = 0; w < wantedList.length; w++) wanted[wantedList[w].itemId] = true;

    for (var i = mirror.length - 1; i >= 0; i--) {
        if (wanted[mirror[i].itemId]) continue;
        ops.push({ op: "remove", index: i });
        mirror = LayoutOps.remove(mirror, i);
    }

    for (var target = 0; target < wantedList.length; target++) {
        var entry = wantedList[target];
        var at = indexOfId(mirror, entry.itemId);

        if (at !== -1 && mirror[at].type !== entry.type) {
            ops.push({ op: "remove", index: at });
            mirror = LayoutOps.remove(mirror, at);
            at = -1;
        }

        if (at === -1) {
            ops.push({ op: "insert", index: target, entry: entry });
            mirror = LayoutOps.insert(mirror, entry, target);
            continue;
        }

        if (at !== target) {
            ops.push({ op: "move", from: at, to: target });
            mirror = LayoutOps.move(mirror, at, target);
        }

        if (payloadDiffers(mirror[target], entry)) {
            ops.push({ op: "update", index: target, entry: entry });
            mirror[target] = entry;
        }
    }

    return ops;
}

function signatureOf(entries, columns) {
    return pack(entries, columns).map(function (entry) {
        return entry.itemId + ":" + entry.type + ":" + entry.size + ":"
            + entry.layoutRow + ":" + entry.layoutSlot + ":" + entry.sourceIndex;
    }).join(",");
}
