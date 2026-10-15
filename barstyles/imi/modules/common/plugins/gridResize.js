.pragma library


function resizeDurationMs(previewing, dragMs, commitMs) {
    return previewing ? dragMs : commitMs;
}

function contentSwapHalfMs(durationMs) {
    if (typeof durationMs !== "number" || !isFinite(durationMs)) return 0;
    return Math.max(0, Math.round(durationMs / 2));
}

function animatesSpanSwap(shown, next) {
    return typeof shown === "string" && typeof next === "string"
        && shown !== "" && next !== "" && shown !== next;
}
