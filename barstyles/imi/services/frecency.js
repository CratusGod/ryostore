.pragma library


var STORE_VERSION = 1;

var MINUTE = 60 * 1000;
var HOUR = 60 * MINUTE;
var DAY = 24 * HOUR;
var WEEK = 7 * DAY;
var MONTH = 30 * DAY;

var BUCKETS = [
    { within: HOUR, weight: 100 },
    { within: DAY, weight: 50 },
    { within: WEEK, weight: 20 },
    { within: MONTH, weight: 5 }
];
var OLDER_WEIGHT = 1;

var MAX_LAUNCHES_PER_APP = 32;
var MAX_APPS = 256;

var BOOST_CEILING = 1.0;
var HALF_BOOST = 100;

function emptyStore() {
    return { "version": STORE_VERSION, "apps": {} };
}

function _entryFor(store, appId) {
    if (!store || !store.apps)
        return null;
    var entry = store.apps[appId];
    if (!entry || !Array.isArray(entry.launches))
        return null;
    return entry;
}

function parseStore(text) {
    if (text === undefined || text === null || String(text).trim().length === 0)
        return null;
    var parsed;
    try {
        parsed = JSON.parse(text);
    } catch (e) {
        return null;
    }
    if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed))
        return null;
    if (parsed.apps === null || typeof parsed.apps !== "object" || Array.isArray(parsed.apps))
        return null;

    var store = emptyStore();
    for (var id in parsed.apps) {
        var entry = parsed.apps[id];
        if (entry === null || typeof entry !== "object" || Array.isArray(entry))
            continue;
        var launches = Array.isArray(entry.launches)
            ? entry.launches.filter(function (ts) { return typeof ts === "number" && isFinite(ts); })
            : [];
        var total = typeof entry.total === "number" && isFinite(entry.total)
            ? Math.max(entry.total, launches.length)
            : launches.length;
        if (launches.length === 0 && total === 0)
            continue;
        store.apps[String(id)] = { "launches": launches.slice(-MAX_LAUNCHES_PER_APP), "total": total };
    }
    return store;
}

function serializeStore(store) {
    return JSON.stringify(store && store.apps ? store : emptyStore());
}

function recordLaunch(store, appId, now) {
    var id = String(appId === undefined || appId === null ? "" : appId);
    var base = (store && store.apps) ? store : emptyStore();
    if (id.length === 0)
        return base;

    var next = { "version": STORE_VERSION, "apps": {} };
    for (var key in base.apps)
        next.apps[key] = base.apps[key];

    var existing = _entryFor(base, id);
    var launches = existing ? existing.launches.slice(0) : [];
    launches.push(typeof now === "number" ? now : Date.now());
    var total = (existing && typeof existing.total === "number" ? existing.total : 0) + 1;
    next.apps[id] = { "launches": launches.slice(-MAX_LAUNCHES_PER_APP), "total": total };

    return _prune(next, typeof now === "number" ? now : Date.now());
}

function _prune(store, now) {
    var ids = Object.keys(store.apps);
    if (ids.length <= MAX_APPS)
        return store;

    ids.sort(function (a, b) { return scoreFor(store, b, now) - scoreFor(store, a, now); });
    var pruned = { "version": STORE_VERSION, "apps": {} };
    for (var i = 0; i < MAX_APPS; i++)
        pruned.apps[ids[i]] = store.apps[ids[i]];
    return pruned;
}

function _weightForAge(age) {
    var elapsed = age < 0 ? 0 : age;
    for (var i = 0; i < BUCKETS.length; i++) {
        if (elapsed < BUCKETS[i].within)
            return BUCKETS[i].weight;
    }
    return OLDER_WEIGHT;
}

function scoreFor(store, appId, now) {
    var entry = _entryFor(store, String(appId === undefined || appId === null ? "" : appId));
    if (!entry)
        return 0;

    var at = typeof now === "number" ? now : Date.now();
    var score = 0;
    for (var i = 0; i < entry.launches.length; i++)
        score += _weightForAge(at - entry.launches[i]);

    var forgotten = Math.max(0, entry.total - entry.launches.length);
    return score + forgotten * OLDER_WEIGHT;
}

function boost(matchScore, frecencyScore) {
    var match = typeof matchScore === "number" && isFinite(matchScore) ? matchScore : 0;
    var frecency = typeof frecencyScore === "number" && isFinite(frecencyScore) && frecencyScore > 0
        ? frecencyScore : 0;
    return match * (1 + BOOST_CEILING * (frecency / (frecency + HALF_BOOST)));
}
