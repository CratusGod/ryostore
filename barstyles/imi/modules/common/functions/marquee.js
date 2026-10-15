.pragma library


var MS_PER_PIXEL = 28;

var MIN_TRAVEL_MS = 3500;

var DWELL_MS = 1200;

var REDUCED_DWELL_MS = 3000;

var OVERFLOW_SLACK = 1;

function _finite(value) {
    var number = Number(value);
    return isFinite(number) ? number : 0;
}

function overflows(contentWidth, boxWidth) {
    var box = _finite(boxWidth);
    if (box <= 0)
        return false;
    return _finite(contentWidth) > box + OVERFLOW_SLACK;
}

function travelDistance(contentWidth, boxWidth) {
    if (!overflows(contentWidth, boxWidth))
        return 0;
    return _finite(contentWidth) - _finite(boxWidth);
}

function travelDuration(contentWidth, boxWidth) {
    var distance = travelDistance(contentWidth, boxWidth);
    if (distance <= 0)
        return 0;
    return Math.max(MIN_TRAVEL_MS, Math.round(distance * MS_PER_PIXEL));
}

function dwell(reduceMotion) {
    return reduceMotion ? REDUCED_DWELL_MS : DWELL_MS;
}
