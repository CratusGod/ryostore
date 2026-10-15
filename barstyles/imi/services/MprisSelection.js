.pragma library

const BUS_PREFIX = "org.mpris.MediaPlayer2.";

const PROXY_PLAYER_IDS = ["playerctld"];

function playerIdFromBusName(busName) {
    let name = String(busName ?? "").trim().toLowerCase();
    if (name.startsWith(BUS_PREFIX.toLowerCase()))
        name = name.slice(BUS_PREFIX.length);
    return name.replace(/\.instance[^.]*$/i, "");
}

function playerId(player) {
    return playerIdFromBusName(player?.dbusName);
}

function isProxyPlayer(player) {
    return PROXY_PLAYER_IDS.indexOf(playerId(player)) !== -1;
}

function isSuppressedDuplicate(player, hasPlasmaIntegration) {
    const busName = String(player?.dbusName ?? "");
    if (busName.endsWith(".mpd") && !busName.endsWith(BUS_PREFIX + "mpd"))
        return true;
    if (!hasPlasmaIntegration)
        return false;
    if (player?.isPlaying)
        return false;
    const id = playerId(player);
    return id.startsWith("firefox") || id.startsWith("chromium");
}

function candidatePlayers(players, filterDuplicates) {
    const real = Array.from(players ?? []).filter(player => !isProxyPlayer(player));
    if (!filterDuplicates)
        return real;
    const hasPlasmaIntegration = real.some(player => playerId(player) === "plasma-browser-integration");
    return real.filter(player => !isSuppressedDuplicate(player, hasPlasmaIntegration));
}

function hasUsableMetadata(player) {
    return String(player?.trackTitle ?? "").trim().length > 0
        || String(player?.trackArtist ?? "").trim().length > 0;
}

function preferredPlayer(candidates) {
    const available = Array.from(candidates ?? []);
    return available.find(player => player?.isPlaying && hasUsableMetadata(player))
        ?? available.find(player => player?.isPlaying)
        ?? available.find(player => hasUsableMetadata(player))
        ?? available[0]
        ?? null;
}

function matchesPreference(player, preference) {
    const wanted = String(preference ?? "").trim().toLowerCase();
    if (wanted.length === 0)
        return false;
    const id = playerId(player);
    if (id === wanted)
        return true;
    return id.includes(wanted)
        || String(player?.identity ?? "").toLowerCase().includes(wanted)
        || String(player?.desktopEntry ?? "").toLowerCase().includes(wanted);
}

function preferenceMatches(candidates, preference) {
    return Array.from(candidates ?? []).filter(player => matchesPreference(player, preference));
}

function normalizePreferredPlayer(value) {
    const raw = String(value ?? "").trim().toLowerCase();
    if (raw.length === 0)
        return "";
    const first = raw.split(/[,;]/)[0].trim().split(/\s+/)[0];
    return playerIdFromBusName(first);
}

function selectPlayer(candidates, preference) {
    const matches = preferenceMatches(candidates, preference);
    if (matches.length > 0)
        return preferredPlayer(matches);
    return preferredPlayer(candidates);
}

function collapseDuplicates(players) {
    const all = Array.from(players ?? []);
    const filtered = [];
    const used = new Set();

    for (let i = 0; i < all.length; ++i) {
        if (used.has(i))
            continue;

        const p1 = all[i];
        const group = [i];

        for (let j = i + 1; j < all.length; ++j) {
            const p2 = all[j];
            const titlesOverlap = p1.trackTitle && p2.trackTitle
                && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle));
            const timingMatches = Math.abs(p1.position - p2.position) <= 2
                && Math.abs(p1.length - p2.length) <= 2;

            if (titlesOverlap || timingMatches)
                group.push(j);
        }

        let chosenIdx = group.find(idx => all[idx].trackArtUrl?.length > 0);
        if (chosenIdx === undefined)
            chosenIdx = group[0];

        filtered.push(all[chosenIdx]);
        group.forEach(idx => used.add(idx));
    }
    return filtered;
}

function meaningfulPlayers(candidates, preference) {
    const matches = preferenceMatches(candidates, preference);
    return collapseDuplicates(matches.length > 0 ? matches : Array.from(candidates ?? []));
}

function playerOptions(candidates, preference) {
    const rows = [];
    const seen = {};

    for (const player of Array.from(candidates ?? [])) {
        const id = playerId(player);
        if (id.length === 0)
            continue;
        const existing = seen[id];
        if (existing !== undefined) {
            if (!existing.isPlaying && player?.isPlaying) {
                existing.isPlaying = true;
                existing.trackTitle = String(player?.trackTitle ?? "");
            } else if (existing.trackTitle.length === 0) {
                existing.trackTitle = String(player?.trackTitle ?? "");
            }
            continue;
        }
        const row = {
            value: id,
            name: String(player?.identity ?? "").trim() || id,
            trackTitle: String(player?.trackTitle ?? ""),
            isPlaying: !!player?.isPlaying,
            available: true
        };
        seen[id] = row;
        rows.push(row);
    }

    const wanted = String(preference ?? "").trim().toLowerCase();
    if (wanted.length > 0 && !rows.some(row => row.value === wanted)) {
        const matches = preferenceMatches(candidates, wanted);
        rows.push({
            value: wanted,
            name: String(matches[0]?.identity ?? "").trim() || wanted,
            trackTitle: String(matches[0]?.trackTitle ?? ""),
            isPlaying: matches.some(player => !!player?.isPlaying),
            available: matches.length > 0
        });
    }

    return rows;
}
