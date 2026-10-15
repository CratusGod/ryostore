.pragma library


var DESKTOP_TAB = "desktop";

var LOCKSCREEN_TAB = "lockscreen";

var TABS = [DESKTOP_TAB, LOCKSCREEN_TAB];

function tabIndex(tab) {
    const index = TABS.indexOf(tab);
    return index < 0 ? 0 : index;
}

function tabAt(index) {
    return TABS[index] || DESKTOP_TAB;
}

function resolveEscape(state) {
    const s = state || {};
    if (s.menuOpen)
        return "closeMenu";
    if (s.gestureInFlight)
        return "cancelGesture";
    if ((s.selectionCount || 0) > 0)
        return "clearSelection";
    if ((s.tab || DESKTOP_TAB) !== DESKTOP_TAB)
        return "desktopTab";
    return "exit";
}

function enabledWithout(ids, id) {
    const next = [];
    const count = ids && typeof ids.length === "number" ? ids.length : 0;
    for (let index = 0; index < count; index++) {
        if (ids[index] !== id)
            next.push(ids[index]);
    }
    return next;
}

var MIN_SCALE = 0.2;

var MAX_SCALE = 0.86;

function usableArea(input) {
    const screenWidth = (input && input.screenWidth) || 0;
    const screenHeight = (input && input.screenHeight) || 0;
    const top = (input && input.insetTop) || 0;
    const bottom = (input && input.insetBottom) || 0;
    const left = (input && input.insetLeft) || 0;
    const right = (input && input.insetRight) || 0;
    return {
        x: left,
        y: top,
        width: Math.max(0, screenWidth - left - right),
        height: Math.max(0, screenHeight - top - bottom)
    };
}

function viewportGeometry(input) {
    const screenWidth = (input && input.screenWidth) || 0;
    const screenHeight = (input && input.screenHeight) || 0;
    const drawerWidth = (input && input.drawerWidth) || 0;
    const margin = (input && input.margin) || 0;
    const edgeMargin = (input && input.edgeMargin !== undefined)
        ? input.edgeMargin : margin;
    const chromeThickness = (input && input.chromeThickness) || 0;
    if (screenWidth <= 0 || screenHeight <= 0)
        return {
            scale: 1, x: 0, y: 0, width: screenWidth, height: screenHeight,
            area: { x: 0, y: 0, width: screenWidth, height: screenHeight }
        };

    const area = usableArea(input);
    const band = chromeThickness > 0
        ? edgeMargin + chromeThickness + margin : margin;
    const roomX = area.width - drawerWidth - margin * 2
        - (drawerWidth > 0 ? edgeMargin : 0);
    const roomY = area.height - band * 2;
    const scale = Math.max(MIN_SCALE,
        Math.min(MAX_SCALE, roomX / screenWidth, roomY / screenHeight));
    const width = screenWidth * scale;
    const height = screenHeight * scale;

    return {
        scale: scale,
        x: area.x + (area.width - width) / 2,
        y: area.y + (area.height - height) / 2,
        width: width,
        height: height,
        area: area,
        drawer: drawerWidth,
        margin: margin,
        edgeMargin: edgeMargin
    };
}

function drawerTravel(geometry) {
    if (!geometry || !(geometry.width > 0) || !geometry.area)
        return 0;
    const free = (geometry.area.width - geometry.width) / 2;
    const edge = geometry.edgeMargin !== undefined
        ? geometry.edgeMargin : (geometry.margin || 0);
    return Math.max(0,
        (geometry.drawer || 0) + (geometry.margin || 0) + edge - free);
}

function chromeBandFraction(geometry) {
    if (!geometry)
        return 0.5;
    const margin = geometry.margin || 0;
    const edge = geometry.edgeMargin !== undefined ? geometry.edgeMargin : margin;
    const slack = edge + margin;
    return slack > 0 ? edge / slack : 0.5;
}

function atProgress(geometry, progress, drawerShift) {
    const t = Math.max(0, Math.min(1, progress || 0));
    return {
        scale: 1 + (geometry.scale - 1) * t,
        x: (geometry.x - (drawerShift || 0)) * t,
        y: geometry.y * t
    };
}

function cardRect(geometry, progress, screenWidth, screenHeight, drawerShift) {
    const applied = atProgress(geometry, progress, drawerShift);
    return {
        x: applied.x,
        y: applied.y,
        width: screenWidth * applied.scale,
        height: screenHeight * applied.scale
    };
}

function areaRect(geometry, progress, screenWidth, screenHeight) {
    const t = Math.max(0, Math.min(1, progress || 0));
    const area = geometry.area || { x: 0, y: 0, width: screenWidth, height: screenHeight };
    return {
        x: area.x * t,
        y: area.y * t,
        width: screenWidth + (area.width - screenWidth) * t,
        height: screenHeight + (area.height - screenHeight) * t
    };
}

function drawerRect(geometry, progress, drawerProgress, screenWidth, screenHeight) {
    const t = Math.max(0, Math.min(1, progress || 0));
    const p = Math.max(0, drawerProgress || 0) * t;
    const area = areaRect(geometry, progress, screenWidth, screenHeight);
    const card = cardRect(geometry, progress, screenWidth, screenHeight);
    const width = (geometry.drawer || 0) * p;
    const edge = geometry.edgeMargin !== undefined
        ? geometry.edgeMargin : (geometry.margin || 0);
    return {
        x: area.x + area.width - edge - width,
        y: card.y,
        width: width,
        height: card.height
    };
}

function pointInDrawerReveal(reveal, x, y) {
    if (!reveal)
        return false;
    const width = reveal.width || 0;
    const height = reveal.height || 0;
    if (!(width > 0) || !(height > 0))
        return false;
    return x >= reveal.x && x <= reveal.x + width
        && y >= reveal.y && y <= reveal.y + height;
}

function canvasPointFromScreen(geometry, progress, drawerShift, screenX, screenY) {
    const applied = atProgress(geometry, progress, drawerShift);
    if (!(applied.scale > 0))
        return { x: screenX, y: screenY };
    return {
        x: (screenX - applied.x) / applied.scale,
        y: (screenY - applied.y) / applied.scale
    };
}

function dropPosition(input) {
    const grid = (input && input.gridSize) || 12;
    const width = (input && input.widgetWidth) || 0;
    const height = (input && input.widgetHeight) || 0;
    const screenWidth = (input && input.screenWidth) || 0;
    const screenHeight = (input && input.screenHeight) || 0;
    const snap = value => Math.round(value / grid) * grid;
    const x = snap(((input && input.canvasX) || 0) - width / 2);
    const y = snap(((input && input.canvasY) || 0) - height / 2);
    return {
        x: Math.max(0, Math.min(screenWidth - Math.max(width, grid), x)),
        y: Math.max(0, Math.min(screenHeight - Math.max(height, grid), y))
    };
}


var UNDO_LIMIT = 50;

function undoPush(stack, entry) {
    var next = listCopy(stack);
    next.push(entry);
    if (next.length > UNDO_LIMIT)
        next.shift();
    return next;
}

function undoPop(stack) {
    var next = listCopy(stack);
    if (next.length === 0)
        return { stack: next, entry: null };
    var entry = next.pop();
    return { stack: next, entry: entry };
}

function listCopy(list) {
    var out = [];
    var count = list && typeof list.length === "number" ? list.length : 0;
    for (var i = 0; i < count; i++)
        out.push(list[i]);
    return out;
}
