
const EDGES = ["top", "bottom", "left", "right"];

function normalizedEdge(edge) {
    const value = String(edge === undefined || edge === null ? "bottom" : edge)
        .trim()
        .toLowerCase();
    return EDGES.indexOf(value) !== -1 ? value : "bottom";
}

function isVertical(edge) {
    return normalizedEdge(edge) === "left" || normalizedEdge(edge) === "right";
}

function directedSides(edge, inward, outward) {
    const e = normalizedEdge(edge);
    switch (e) {
    case "top":
        return { top: outward, bottom: inward, left: 0, right: 0 };
    case "left":
        return { top: 0, bottom: 0, left: outward, right: inward };
    case "right":
        return { top: 0, bottom: 0, left: inward, right: outward };
    case "bottom":
    default:
        return { top: inward, bottom: outward, left: 0, right: 0 };
    }
}

function axisMargins(edge, start, end, cross) {
    const e = normalizedEdge(edge);
    if (isVertical(e))
        return { top: start, bottom: end, left: cross, right: cross };
    return { top: cross, bottom: cross, left: start, right: end };
}

function inwardVector(edge) {
    switch (normalizedEdge(edge)) {
    case "top":
        return { x: 0, y: 1 };
    case "left":
        return { x: 1, y: 0 };
    case "right":
        return { x: -1, y: 0 };
    case "bottom":
    default:
        return { x: 0, y: -1 };
    }
}

function outwardSide(edge) {
    return normalizedEdge(edge);
}

function popupGravity(edge) {
    switch (normalizedEdge(edge)) {
    case "top":
        return "bottom";
    case "left":
        return "right";
    case "right":
        return "left";
    case "bottom":
    default:
        return "top";
    }
}

function popupAnchorSides(edge) {
    switch (normalizedEdge(edge)) {
    case "top":
        return { edges: ["bottom"], gravity: ["top"] };
    case "left":
        return { edges: ["right"], gravity: ["left"] };
    case "right":
        return { edges: ["left"], gravity: ["right"] };
    case "bottom":
    default:
        return { edges: ["top"], gravity: ["bottom"] };
    }
}

function barEdge(vertical, bottom) {
    if (vertical)
        return bottom ? "right" : "left";
    return bottom ? "bottom" : "top";
}

function thickness(bodyHeight, elevationMargin, gapsOut) {
    return (bodyHeight || 0) + (elevationMargin || 0) + (gapsOut || 0);
}
