.pragma library


var BREAK_PX = 60;
var BOW_PX = 14;
var BOW_EASE = 1.15;
var BULGE_PEAK = 0.85;
var CORNER_FOLLOW = 1.0;
var SHARPEN = 0.5;


function giveAxis(pull, breakPx) {
    var limit = breakPx > 0 ? breakPx : BREAK_PX;
    var steps = Math.trunc(pull / limit);
    return { steps: steps, remainder: pull - steps * limit };
}

function stepSize(offered, current, dCols, dRows) {
    if (!offered || offered.length === 0 || !current) return current;
    var best = null;
    var bestPreferred = false;
    var bestDistance = Infinity;
    for (var i = 0; i < offered.length; i++) {
        var candidate = offered[i];
        if (dCols > 0 && candidate.cols <= current.cols) continue;
        if (dCols < 0 && candidate.cols >= current.cols) continue;
        if (dRows > 0 && candidate.rows <= current.rows) continue;
        if (dRows < 0 && candidate.rows >= current.rows) continue;
        var preferred = dCols !== 0
            ? candidate.rows === current.rows
            : candidate.cols === current.cols;
        var distance = dCols !== 0
            ? Math.abs(candidate.cols - current.cols)
            : Math.abs(candidate.rows - current.rows);
        if (best === null
                || (preferred && !bestPreferred)
                || (preferred === bestPreferred && distance < bestDistance)) {
            best = candidate;
            bestPreferred = preferred;
            bestDistance = distance;
        }
    }
    return best ?? current;
}


function bow(pull, breakPx, bowPx, ease) {
    var limit = breakPx > 0 ? breakPx : BREAK_PX;
    var reach = bowPx !== undefined ? bowPx : BOW_PX;
    var exponent = ease !== undefined ? ease : BOW_EASE;
    var t = Math.max(-1, Math.min(1, pull / limit));
    return Math.sign(t) * Math.pow(Math.abs(t), exponent) * reach;
}


function cornerRadii(cap, bowX, bowY, bowPx, sharpen) {
    var reach = bowPx !== undefined ? bowPx : BOW_PX;
    var grip = sharpen !== undefined ? sharpen : SHARPEN;
    var tx = reach > 0 ? Math.max(-1, Math.min(1, bowX / reach)) : 0;
    var ty = reach > 0 ? Math.max(-1, Math.min(1, bowY / reach)) : 0;
    var load = Math.min(1, Math.hypot(tx, ty));
    return {
        tl: cap,
        tr: cap * (1 + grip * 0.5 * Math.abs(ty)),
        br: Math.max(2, cap * (1 - grip * load)),
        bl: cap * (1 + grip * 0.5 * Math.abs(tx))
    };
}


function outline(w, h, bowX, bowY, radii, peak, follow) {
    var p = peak !== undefined ? peak : BULGE_PEAK;
    var f = follow !== undefined ? follow : CORNER_FOLLOW;
    var rTL = Math.min(radii.tl, w / 2, h / 2);
    var rTR = Math.min(radii.tr, w / 2, h / 2);
    var rBR = Math.min(radii.br, w / 2, h / 2);
    var rBL = Math.min(radii.bl, w / 2, h / 2);
    var cx = w + bowX * f;
    var cy = h + bowY * f;
    var midY = rTR + ((cy - rBR) - rTR) * p;
    var midX = rBL + ((cx - rBR) - rBL) * p;
    return { segments: [
        { op: "move", x: rTL, y: 0 },
        { op: "line", x: w - rTR, y: 0 },
        { op: "quad", cx: w, cy: 0, x: w, y: rTR },
        { op: "quad", cx: w + bowX, cy: midY, x: cx, y: cy - rBR },
        { op: "quad", cx: cx, cy: cy, x: cx - rBR, y: cy },
        { op: "quad", cx: midX, cy: h + bowY, x: rBL, y: h },
        { op: "quad", cx: 0, cy: h, x: 0, y: h - rBL },
        { op: "line", x: 0, y: rTL },
        { op: "quad", cx: 0, cy: 0, x: rTL, y: 0 }
    ] };
}
