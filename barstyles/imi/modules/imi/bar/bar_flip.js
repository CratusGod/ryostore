.pragma library


var MIN_TRAVEL = 1;

function chainOrigin(nodes) {
    var x = 0;
    var y = 0;
    var count = nodes && typeof nodes.length === "number" ? nodes.length : 0;
    for (var i = 0; i < count; i++) {
        var node = nodes[i];
        if (!node) continue;
        x += node.x;
        y += node.y;
    }
    return { x: x, y: y };
}

function invert(recorded, current) {
    if (!recorded || !current) return { x: NaN, y: NaN };
    return { x: recorded.x - current.x, y: recorded.y - current.y };
}

function alongAxis(offset, vertical) {
    if (!offset) return NaN;
    return vertical ? offset.y : offset.x;
}

function repositionTravel(held, recorded, current, vertical, minTravel) {
    var delta = alongAxis(invert(recorded, current), vertical);
    if (!(Math.abs(delta) >= minTravel)) return { travel: held, play: false };
    return { travel: held + delta, play: true };
}
