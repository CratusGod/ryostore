.pragma library


function eligible(state) {
    const s = state || {};
    if (!s.enable) return false;
    if (s.optedOut) return false;
    if (s.selecting) return false;
    if (s.editing) return false;
    if (!s.maskPath) return false;
    if (!!s.weActive !== !!s.maskIsWe) return false;
    if (s.wallpaperIsVideo) return false;
    if (s.centeredWallpaper) return false;
    if (s.screenLocked) return false;
    if (s.transitionInFlight) return false;
    return true;
}

function coverRect(sourceWidth, sourceHeight, boxWidth, boxHeight) {
    const sw = positive(sourceWidth);
    const sh = positive(sourceHeight);
    const bw = positive(boxWidth);
    const bh = positive(boxHeight);
    if (sw === 0 || sh === 0 || bw === 0 || bh === 0)
        return { x: 0, y: 0, width: bw, height: bh };
    const scale = Math.max(bw / sw, bh / sh);
    const width = sw * scale;
    const height = sh * scale;
    return { x: (bw - width) / 2, y: (bh - height) / 2, width: width, height: height };
}

function normalisedPoint(rect, x, y) {
    const r = rect || {};
    const width = positive(r.width);
    const height = positive(r.height);
    if (width === 0 || height === 0)
        return null;
    const originX = (typeof r.x === "number" && isFinite(r.x)) ? r.x : 0;
    const originY = (typeof r.y === "number" && isFinite(r.y)) ? r.y : 0;
    if (!isFinite(x) || !isFinite(y))
        return null;
    return {
        x: clamp01((x - originX) / width),
        y: clamp01((y - originY) / height)
    };
}

function promptFromScreen(box, pictureRect, screenX, screenY) {
    const b = box || {};
    if (!isFinite(screenX) || !isFinite(screenY))
        return null;
    return normalisedPoint(pictureRect, screenX - origin(b.x), screenY - origin(b.y));
}

function selectable(state) {
    const s = state || {};
    if (!s.wallpaperPath) return false;
    if (s.previewing) return false;
    if (!!s.weActive !== !!s.maskIsWe) return false;
    if (s.stillMissing) return false;
    if (s.centeredWallpaper) return false;
    if (s.screenLocked) return false;
    return true;
}

function clamp01(value) {
    return value < 0 ? 0 : (value > 1 ? 1 : value);
}

function origin(value) {
    return (typeof value === "number" && isFinite(value)) ? value : 0;
}

function positive(value) {
    return (typeof value === "number" && isFinite(value) && value > 0) ? value : 0;
}
