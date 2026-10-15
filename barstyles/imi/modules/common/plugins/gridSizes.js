.pragma library


const MIN_CELLS = 1;
const MAX_CELLS = 12;

function isCellCount(value) {
    return typeof value === "number" && isFinite(value) && value === Math.floor(value)
        && value >= MIN_CELLS && value <= MAX_CELLS;
}

function normalizeSize(entry) {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) return null;
    const cols = entry.cols === undefined ? 1 : entry.cols;
    const rows = entry.rows === undefined ? 1 : entry.rows;
    if (!isCellCount(cols) || !isCellCount(rows)) return null;
    return { cols: cols, rows: rows };
}

function defaultSize(grid) {
    return normalizeSize(grid);
}

function asSizeList(value) {
    if (Array.isArray(value)) return value;
    if (!value || typeof value !== "object" || typeof value.length !== "number") return null;
    const out = [];
    for (let index = 0; index < value.length; index++) out.push(value[index]);
    return out;
}

function sameSize(a, b) {
    return !!a && !!b && a.cols === b.cols && a.rows === b.rows;
}

function containsSize(list, size) {
    for (const entry of list) {
        if (sameSize(entry, size)) return true;
    }
    return false;
}

function offeredSizes(grid) {
    const fallback = defaultSize(grid);
    if (!fallback) return [];

    const declared = asSizeList(grid.sizes);
    if (declared === null) return [fallback];

    const out = [];
    for (const entry of declared) {
        const size = normalizeSize(entry);
        if (!size) return [fallback];
        if (!containsSize(out, size)) out.push(size);
    }
    if (!containsSize(out, fallback)) return [fallback];
    return out;
}

function resizable(grid) {
    return offeredSizes(grid).length > 1;
}

function formatSize(size) {
    const normalized = normalizeSize(size);
    return normalized ? normalized.cols + "x" + normalized.rows : "";
}

function parseSize(text) {
    if (typeof text !== "string") return null;
    const match = /^\s*(\d+)\s*x\s*(\d+)\s*$/.exec(text);
    if (!match) return null;
    return normalizeSize({ cols: parseInt(match[1], 10), rows: parseInt(match[2], 10) });
}

function resolveSize(grid, stored) {
    const fallback = defaultSize(grid);
    if (!fallback) return null;

    const wanted = parseSize(stored);
    if (wanted && containsSize(offeredSizes(grid), wanted)) return wanted;
    return fallback;
}

function steppedSize(grid, stored, direction) {
    const offered = offeredSizes(grid);
    if (offered.length < 2) return null;
    const current = resolveSize(grid, stored);
    if (!current) return null;
    for (let index = 0; index < offered.length; index++) {
        if (!sameSize(offered[index], current)) continue;
        const next = index + direction;
        if (next < 0 || next >= offered.length) return null;
        return offered[next];
    }
    return null;
}

function migrateSizeMode(options, grid) {
    if (!options || typeof options !== "object" || Array.isArray(options)) return null;
    if (options.sizeMode === undefined) return null;
    if (offeredSizes(grid).length <= 1) return null;

    const next = {};
    for (const key in options) {
        if (key !== "sizeMode") next[key] = options[key];
    }
    if (next.__gridSize === undefined) {
        const wanted = parseSize(options.sizeMode);
        if (wanted && containsSize(offeredSizes(grid), wanted))
            next.__gridSize = formatSize(wanted);
    }
    return next;
}

function nearestSize(candidates, targetWidth, targetHeight) {
    const list = asSizeList(candidates);
    if (list === null) return null;

    let best = null;
    let bestDistance = Infinity;
    for (const candidate of list) {
        const dx = candidate.width - targetWidth;
        const dy = candidate.height - targetHeight;
        const distance = dx * dx + dy * dy;
        if (distance < bestDistance) {
            bestDistance = distance;
            best = candidate;
        }
    }
    return best;
}
