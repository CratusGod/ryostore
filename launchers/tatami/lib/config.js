.pragma library

// What Tatami reads from launcher.json, cleaned. Settings writes the file, but
// anyone can edit it by hand and an older or newer Settings may leave other
// shapes in it, so every key is checked here and anything odd falls back to the
// default instead of reaching the shelf. The ranges are the ones Settings
// offers, so a value it could have saved passes through unchanged.

var DEFAULTS = {
    hiddenApps: [],
    pinnedApps: [],
    sectionOrder: [],
    hiddenSections: [],
    overlayOpacity: 0.94,
    bgBlur: 0,
    columns: 8,
    matWidth: 144
};

var LIMITS = {
    overlayOpacity: [0.3, 1],
    bgBlur: [0, 30],
    columns: [3, 16],
    matWidth: [90, 240]
};

// A list from the config may arrive as a QML list rather than an Array, so it
// is read by length. Anything but a non-empty string is dropped, and so is a
// repeat; a bare string or an object is not a list at all.
function strings(value) {
    var out = [];
    if (value === null || typeof value !== "object" || typeof value.length !== "number")
        return out;
    var seen = {};
    for (var i = 0, limit = Math.min(value.length, 2000); i < limit && out.length < 2000; i++) {
        var item = value[i];
        if (typeof item !== "string")
            continue;
        item = item.trim();
        if (item.length === 0 || seen[item] === true)
            continue;
        seen[item] = true;
        out.push(item);
    }
    return out;
}

// A finite number inside its range; anything else (text, null, NaN, a list)
// is the default. whole rounds to a whole number.
function number(value, key, whole) {
    if (typeof value !== "number" || !isFinite(value))
        return DEFAULTS[key];
    var n = whole ? Math.round(value) : value;
    return Math.max(LIMITS[key][0], Math.min(LIMITS[key][1], n));
}

function clean(raw) {
    var src = raw || {};
    return {
        hiddenApps: strings(src.hiddenApps),
        pinnedApps: strings(src.pinnedApps),
        sectionOrder: strings(src.sectionOrder),
        hiddenSections: strings(src.hiddenSections),
        overlayOpacity: number(src.overlayOpacity, "overlayOpacity", false),
        bgBlur: number(src.bgBlur, "bgBlur", true),
        columns: number(src.columns, "columns", true),
        matWidth: number(src.matWidth, "matWidth", true)
    };
}
