.pragma library

// The shelf Tatami lays out: every visible desktop entry, sorted by name and
// filed under one section, then narrowed by the chosen section and the query.

// Each section claims freedesktop categories. An entry files under the first
// of its own categories that a section claims, so an app lands where it lists
// itself first rather than wherever a secondary tag would put it.
var SECTIONS = [
    { id: "internet", label: "Internet", claims: ["Network", "WebBrowser", "Email", "Chat", "InstantMessaging", "IRCClient", "FileTransfer", "P2P"] },
    { id: "media", label: "Media", claims: ["AudioVideo", "Audio", "Video", "Music", "Player", "Recorder", "Midi", "Mixer"] },
    { id: "graphics", label: "Graphics", claims: ["Graphics", "Photography", "2DGraphics", "3DGraphics", "RasterGraphics", "VectorGraphics", "Scanning", "Viewer"] },
    { id: "develop", label: "Develop", claims: ["Development", "IDE", "Debugger", "RevisionControl", "WebDevelopment", "Building", "GUIDesigner"] },
    { id: "office", label: "Office", claims: ["Office", "WordProcessor", "Spreadsheet", "Presentation", "Calendar", "ContactManagement", "Finance", "Publishing"] },
    { id: "games", label: "Games", claims: ["Game", "ActionGame", "AdventureGame", "ArcadeGame", "BoardGame", "CardGame", "Emulator", "LogicGame", "Simulation", "StrategyGame"] },
    { id: "system", label: "System", claims: ["System", "Settings", "DesktopSettings", "HardwareSettings", "Monitor", "TerminalEmulator", "PackageManager", "Security"] },
    { id: "utility", label: "Utility", claims: ["Utility", "Accessories", "FileManager", "FileTools", "TextEditor", "Archiving", "Calculator", "Clock", "Education", "Science"] }
];

function sectionOf(entry) {
    var categories = entry && entry.categories ? entry.categories : [];
    for (var i = 0; i < categories.length; i++)
        for (var j = 0; j < SECTIONS.length; j++)
            if (SECTIONS[j].claims.indexOf(String(categories[i])) >= 0)
                return SECTIONS[j].id;
    return "other";
}

function nameOf(entry) {
    return String(entry && entry.name || "");
}

// collect files every displayable entry once, alphabetically.
function collect(entries) {
    var shelf = [];
    for (var i = 0; i < entries.length; i++) {
        var entry = entries[i];
        if (!entry || entry.noDisplay || nameOf(entry).length === 0)
            continue;
        shelf.push({ entry: entry, name: nameOf(entry), key: nameOf(entry).toLowerCase(), section: sectionOf(entry) });
    }
    shelf.sort(function (a, b) { return a.key.localeCompare(b.key); });
    return shelf;
}

// sections lists All, then each section with apps in it, in shelf order.
function sections(shelf) {
    var counts = {};
    for (var i = 0; i < shelf.length; i++)
        counts[shelf[i].section] = (counts[shelf[i].section] || 0) + 1;
    var list = [{ id: "all", label: "All", count: shelf.length }];
    for (var j = 0; j < SECTIONS.length; j++)
        if (counts[SECTIONS[j].id])
            list.push({ id: SECTIONS[j].id, label: SECTIONS[j].label, count: counts[SECTIONS[j].id] });
    if (counts.other)
        list.push({ id: "other", label: "Other", count: counts.other });
    return list;
}

// rank orders a match: the name starting with the query beats a word in it
// starting so, which beats the query anywhere in the name, which beats it in
// the generic name, keywords or comment. -1 is no match.
function rank(item, query) {
    if (query.length === 0)
        return 0;
    if (item.key.indexOf(query) === 0)
        return 0;
    var words = item.key.split(/[\s\-_.]+/);
    for (var i = 1; i < words.length; i++)
        if (words[i].indexOf(query) === 0)
            return 1;
    if (item.key.indexOf(query) >= 0)
        return 2;
    var entry = item.entry;
    var extra = [String(entry.genericName || ""), String(entry.comment || "")]
        .concat(entry.keywords ? Array.prototype.slice.call(entry.keywords).map(String) : [])
        .join("\n").toLowerCase();
    return extra.indexOf(query) >= 0 ? 3 : -1;
}

// filter narrows the shelf to one section and the query, best match first. A
// query searches every section, so typing never hides an app behind a tab.
function filter(shelf, section, query) {
    var q = String(query || "").trim().toLowerCase();
    var hits = [];
    for (var i = 0; i < shelf.length; i++) {
        var item = shelf[i];
        if (q.length === 0 && section !== "all" && item.section !== section)
            continue;
        var score = rank(item, q);
        if (score >= 0)
            hits.push({ item: item, score: score, order: i });
    }
    hits.sort(function (a, b) { return a.score - b.score || a.order - b.order; });
    return hits.map(function (hit) { return hit.item; });
}
