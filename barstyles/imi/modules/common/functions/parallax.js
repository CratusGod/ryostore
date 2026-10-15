.pragma library


const CENTRE = 0.5;

function clamp01(value) {
    if (!isFinite(value)) return CENTRE;
    return Math.max(0, Math.min(1, value));
}

function number(value, fallback) {
    return (typeof value === "number" && isFinite(value)) ? value : fallback;
}

function workspaceFraction(workspaceIndex, totalWorkspaces) {
    const total = number(totalWorkspaces, 1);
    if (total <= 1) return CENTRE;
    return clamp01(number(workspaceIndex, 0) / (total - 1));
}

function fractions(state) {
    state = state || {};
    const vertical = !!state.vertical;
    const workspace = state.enableWorkspace === false
        ? CENTRE
        : workspaceFraction(state.workspaceIndex, state.totalWorkspaces);

    let x = vertical ? CENTRE : workspace;
    let y = vertical ? workspace : CENTRE;

    if (state.enableSidebar !== false) {
        const nudge = number(state.sidebarFraction, 0);
        if (state.sidebarRightOpen) x += nudge;
        if (state.sidebarLeftOpen) x -= nudge;
    }

    return { x: clamp01(x), y: clamp01(y) };
}

function offsets(state) {
    state = state || {};
    const f = fractions(state);
    const overflowX = Math.max(0, number(state.overflowX, 0));
    const overflowY = Math.max(0, number(state.overflowY, 0));
    return {
        x: -overflowX * f.x,
        y: -overflowY * f.y
    };
}

function widgetOffset(wallpaperOffset, factor) {
    return number(wallpaperOffset, 0) * number(factor, 0);
}

function widgetOffsets(state, factor) {
    state = state || {};
    const f = fractions(state);
    const scale = number(factor, 0);
    const overflowX = Math.max(0, number(state.overflowX, 0));
    const overflowY = Math.max(0, number(state.overflowY, 0));
    return {
        x: -overflowX * (f.x - CENTRE) * scale,
        y: -overflowY * (f.y - CENTRE) * scale
    };
}

function sampleOrigin(canvasOffset, widgetPos, wallpaperOffset) {
    canvasOffset = canvasOffset || {};
    widgetPos = widgetPos || {};
    wallpaperOffset = wallpaperOffset || {};
    return {
        x: number(canvasOffset.x, 0) + number(widgetPos.x, 0) - number(wallpaperOffset.x, 0),
        y: number(canvasOffset.y, 0) + number(widgetPos.y, 0) - number(wallpaperOffset.y, 0)
    };
}

function parallaxCancel(canvasOffset, follows) {
    if (follows === false) return -number(canvasOffset, 0);
    return 0;
}

function drawnFromPlacement(placement, cancel) {
    return number(placement, 0) + number(cancel, 0);
}

function placementFromDrawn(drawn, cancel) {
    return number(drawn, 0) - number(cancel, 0);
}
