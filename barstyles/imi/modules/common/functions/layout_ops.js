.pragma library


function indexAt(centres, point, axis) {
    if (!centres || !point) return -1;
    var best = -1;
    var bestDistance = Infinity;
    for (var i = 0; i < centres.length; i++) {
        var centre = centres[i];
        if (!centre) continue;
        var distance;
        if (axis === "x" || axis === "y") {
            distance = Math.abs(point[axis] - centre[axis]);
        } else {
            var dx = point.x - centre.x;
            var dy = point.y - centre.y;
            distance = dx * dx + dy * dy;
        }
        if (distance < bestDistance) {
            bestDistance = distance;
            best = i;
        }
    }
    return best;
}

function isIndex(list, index) {
    return typeof index === "number" && index >= 0 && index < list.length;
}

function moveInPlace(list, from, to) {
    if (!list) return list;
    if (from === to) return list;
    if (!isIndex(list, from) || !isIndex(list, to)) return list;
    var item = list.splice(from, 1)[0];
    list.splice(to, 0, item);
    return list;
}

function move(list, from, to) {
    if (!list) return list;
    return moveInPlace(list.slice(), from, to);
}


function insert(list, item, at) {
    if (!list) return list;
    var copy = list.slice();
    if (typeof at !== "number" || at < 0 || at > copy.length) return copy;
    copy.splice(at, 0, item);
    return copy;
}

function remove(list, at) {
    if (!list) return list;
    var copy = list.slice();
    if (!isIndex(copy, at)) return copy;
    copy.splice(at, 1);
    return copy;
}

function dropTarget(buckets, point, axis) {
    if (!buckets || !point) return null;
    var best = null;
    var bestDistance = Infinity;
    for (var b = 0; b < buckets.length; b++) {
        var bucket = buckets[b];
        if (!bucket) continue;
        var centres = bucket.centres || [];
        var sawSlot = false;
        for (var i = 0; i < centres.length; i++) {
            var centre = centres[i];
            if (!centre) continue;
            sawSlot = true;
            var distance = Math.abs(point[axis] - centre[axis]);
            if (distance < bestDistance) {
                bestDistance = distance;
                best = { bucket: b, index: i + (point[axis] > centre[axis] ? 1 : 0) };
            }
        }
        if (!sawSlot && bucket.anchor) {
            var anchorDistance = Math.abs(point[axis] - bucket.anchor[axis]);
            if (anchorDistance < bestDistance) {
                bestDistance = anchorDistance;
                best = { bucket: b, index: 0 };
            }
        }
    }
    return best;
}


function nthVisible(flags, n) {
    if (!flags) return -1;
    var seen = 0;
    for (var i = 0; i < flags.length; i++) {
        if (!flags[i]) continue;
        if (seen === n) return i;
        seen++;
    }
    return -1;
}

function insertionForVisible(flags, insertion) {
    var stored = nthVisible(flags, insertion);
    return stored === -1 ? (flags ? flags.length : 0) : stored;
}

function moveTargetForInsertion(from, insertion) {
    return insertion > from ? insertion - 1 : insertion;
}

function partedSlot(index, dragIndex, gapIndex) {
    var slot = index;
    if (dragIndex >= 0 && index > dragIndex) slot -= 1;
    if (gapIndex >= 0 && slot >= gapIndex) slot += 1;
    return slot;
}
