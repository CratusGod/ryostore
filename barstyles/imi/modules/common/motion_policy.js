.pragma library


var MULTIPLIER_MIN = 0.5;
var MULTIPLIER_MAX = 2.5;
var MULTIPLIER_DEFAULT = 1.0;

var REDUCE_MOTION_DURATION = 0;

var REDUCE_MOTION_VELOCITY = 100000;

function clampMultiplier(value) {
    var number = Number(value);
    if (!isFinite(number)) return MULTIPLIER_DEFAULT;
    if (number < MULTIPLIER_MIN) return MULTIPLIER_MIN;
    if (number > MULTIPLIER_MAX) return MULTIPLIER_MAX;
    return number;
}

function scaleDuration(base, multiplier, reduceMotion) {
    if (reduceMotion) return REDUCE_MOTION_DURATION;
    return Math.max(0, Math.round(Number(base) * clampMultiplier(multiplier)));
}

function scaleVelocity(base, multiplier, reduceMotion) {
    if (reduceMotion) return REDUCE_MOTION_VELOCITY;
    return Math.max(1, Math.round(Number(base) / clampMultiplier(multiplier)));
}

function scaleStep(seconds, multiplier, reduceMotion) {
    if (reduceMotion) return 0;
    var s = Number(seconds);
    if (!isFinite(s) || s <= 0) return 0;
    return s / clampMultiplier(multiplier);
}

var STAGGER_MAX_RANK = 5;

var STAGGER_FRACTION = 0.2;

function staggerStep(baseDuration) {
    return Math.round(Number(baseDuration) * STAGGER_FRACTION);
}

function staggerDelay(rank, step, leadIn) {
    var base = Math.max(0, Number(leadIn) || 0);
    if (rank < 0) return base;
    return base + Math.min(rank, STAGGER_MAX_RANK) * Math.max(0, Number(step) || 0);
}

var ENTRANCE_SCALE_FLOOR = 0.85;

function entranceScaleFrom(rise, reference) {
    var span = Math.max(1, Number(reference) || 0);
    var derived = 1 - Number(rise) / span;
    if (!(derived > ENTRANCE_SCALE_FLOOR)) return ENTRANCE_SCALE_FLOOR;
    return Math.min(1, derived);
}

function convergeFrom(normX, rankParity) {
    var x = Number(normX);
    var dx = 0;
    if (x < -1 / 3) dx = -1;
    else if (x > 1 / 3) dx = 1;
    var dy = (Number(rankParity) % 2 === 0) ? -1 : 1;
    return { dx: dx, dy: dy };
}

var CONVERGE_OVERSHOOT = 1.1;

function convergeSettle(appear, overshoot) {
    var a = Number(appear);
    if (!(a > 0)) return 0;
    if (a >= 1) return 1;
    var s = (overshoot === undefined) ? CONVERGE_OVERSHOOT : Number(overshoot);
    var t = a - 1;
    return 1 + t * t * ((s + 1) * t + s);
}

var CONTAINER_CONTENT_GATE = 0.6;

function contentsArrived(progress, opening) {
    var p = Number(progress);
    return opening ? p >= CONTAINER_CONTENT_GATE : p > 0;
}

function staggerRanks(included) {
    var ranks = [];
    var rank = 0;
    for (var i = 0; i < included.length; i++) {
        if (included[i]) {
            ranks.push(rank);
            rank++;
        } else {
            ranks.push(-1);
        }
    }
    return ranks;
}
