.pragma library

.import "quick_toggle_layout.js" as Layout
.import "layout_ops.js" as LayoutOps


function _isList(value) {
    return !!value && typeof value !== "string" && typeof value.length === "number";
}

function _entries(rawList, seen) {
    var out = [];
    if (!_isList(rawList)) return out;
    for (var i = 0; i < rawList.length; i++) {
        var raw = rawList[i];
        if (!raw || typeof raw.type !== "string" || raw.type.length === 0) continue;
        if (seen[raw.type]) continue;
        seen[raw.type] = true;
        out.push({ type: raw.type, size: Layout.sizeOf(raw) });
    }
    return out;
}

function normalise(pagesRaw, legacyToggles) {
    var seen = {};
    var pages = [];
    if (_isList(pagesRaw)) {
        for (var i = 0; i < pagesRaw.length; i++) {
            if (_isList(pagesRaw[i])) pages.push(_entries(pagesRaw[i], seen));
        }
    }
    if (pages.length === 0) {
        var legacy = _entries(legacyToggles, seen);
        return legacy.length > 0 ? [legacy] : [[]];
    }
    return pages;
}

function _copy(pages) {
    return (pages || []).map(function (page) {
        return (page || []).map(function (entry) {
            return { type: entry.type, size: entry.size };
        });
    });
}

function withAddedPage(pages) {
    var next = _copy(pages);
    next.push([]);
    return next;
}

function pruned(pages) {
    var next = _copy(pages).filter(function (page) { return page.length > 0; });
    return next.length > 0 ? next : [[]];
}

function clampPage(pages, current) {
    var last = (pages ? pages.length : 1) - 1;
    return Math.max(0, Math.min(typeof current === "number" ? current : 0, last));
}

function usedTypes(pages) {
    var used = {};
    for (var i = 0; i < (pages ? pages.length : 0); i++)
        for (var j = 0; j < pages[i].length; j++)
            used[pages[i][j].type] = true;
    return used;
}

function withMove(pages, fromPage, fromIndex, toPage, toIndex) {
    var next = _copy(pages);
    if (fromPage < 0 || fromPage >= next.length) return next;
    if (toPage < 0 || toPage >= next.length) return next;
    if (fromPage === toPage) {
        next[fromPage] = LayoutOps.move(next[fromPage], fromIndex, toIndex);
        return next;
    }
    if (fromIndex < 0 || fromIndex >= next[fromPage].length) return next;
    var entry = next[fromPage].splice(fromIndex, 1)[0];
    var at = Math.max(0, Math.min(typeof toIndex === "number" ? toIndex : 0,
        next[toPage].length));
    next[toPage].splice(at, 0, entry);
    return next;
}

function withInsert(pages, pageIndex, entry) {
    var next = _copy(pages);
    if (pageIndex < 0 || pageIndex >= next.length) return next;
    if (!entry || typeof entry.type !== "string") return next;
    if (usedTypes(next)[entry.type]) return next;
    next[pageIndex].push({ type: entry.type, size: Layout.sizeOf(entry) });
    return next;
}

function withRemove(pages, pageIndex, index) {
    var next = _copy(pages);
    if (pageIndex < 0 || pageIndex >= next.length) return next;
    next[pageIndex] = LayoutOps.remove(next[pageIndex], index);
    return next;
}

function withResize(pages, pageIndex, index, size) {
    var next = _copy(pages);
    if (pageIndex < 0 || pageIndex >= next.length) return next;
    if (index < 0 || index >= next[pageIndex].length) return next;
    next[pageIndex][index].size = size;
    return next;
}

function signatureOf(pages, columns) {
    return (pages || []).map(function (page) {
        return Layout.signatureOf(page, columns);
    }).join("|");
}
