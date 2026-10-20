.pragma library



function cardState(available, reachable, connecting, active) {
    if (!available) return "unavailable";
    if (active) return "active";
    if (connecting) return "connecting";
    if (!reachable) return "offline";
    return "ready";
}

function mirrorState(flags) {
    const f = flags || {};
    if (!f.available) return "unavailable";
    if (f.running) return "active";
    if (f.launching) return "connecting";
    if (!f.reachable) return "offline";
    if (f.adbDevice === false) return "offline";
    if (errorHeadline(f.error).length > 0) return "offline";
    return "ready";
}

function micState(flags) {
    const f = flags || {};
    const linked = f.reachable && !(f.needsAdbDevice && f.adbDevice === false);
    return cardState(f.available, linked, f.connecting, f.active);
}

function errorHeadline(text) {
    return String(text || "").split("\n")[0].trim();
}


function mirrorTitleKey(flags) {
    const f = flags || {};
    if (!f.available) return "install";
    if (f.running) return "running";
    if (f.launching) return "connecting";
    return "open";
}

function mirrorSubtitleKey(flags) {
    const f = flags || {};
    if (!f.available) return "install";
    if (!f.reachable) return "offline";
    if (f.running) return "running";
    if (f.launching) return "launching";
    if (errorHeadline(f.error).length > 0) return "error";
    if (f.adbDevice === false) return "noDevice";
    return "ready";
}

function webcamTitleKey(available) {
    return available ? "webcam" : "install";
}

function webcamSubtitleKey(flags) {
    const f = flags || {};
    if (!f.available) return "install";
    if (!f.reachable) return "offline";
    if (f.connecting) return "connecting";
    if (f.active) return String(f.device || "").length > 0 ? "device" : "running";
    if (errorHeadline(f.error).length > 0) return "error";
    return "ready";
}

function micTitleKey(available) {
    return available ? "mic" : "install";
}

function micSubtitleKey(flags) {
    const f = flags || {};
    if (!f.available) return "install";
    if (!f.reachable) return "offline";
    if (f.connecting) return "connecting";
    if (f.active) return f.muted ? "muted" : "active";
    if (f.needsAdbDevice && f.adbDevice === false) return "noDevice";
    if (errorHeadline(f.error).length > 0) return "error";
    return "ready";
}


function elapsedMs(startedAtSeconds, nowMs) {
    const started = Number(startedAtSeconds) || 0;
    if (started <= 0) return 0;
    return Math.max(0, Number(nowMs) - started * 1000);
}

function formatElapsed(ms) {
    const total = Math.max(0, Math.floor(Number(ms) / 1000));
    if (total < 60) return total + "s";
    const minutes = Math.floor(total / 60);
    const seconds = total % 60;
    if (minutes < 60) return minutes + "m " + (seconds < 10 ? "0" : "") + seconds + "s";
    const hours = Math.floor(minutes / 60);
    const restMinutes = minutes % 60;
    return hours + "h " + (restMinutes < 10 ? "0" : "") + restMinutes + "m";
}


// Install hints use Ryoku's host seam, which names packages for this edition
// (Arch, CachyOS, Fedora or Void), so a single command fits every machine.
function distroPills() {
    return [
        { key: "ryoku", label: "Ryoku" }
    ];
}

function knownDistro(distro) {
    const key = String(distro || "");
    return distroPills().some(pill => pill.key === key);
}

function initialDistro(detected) {
    return knownDistro(detected) ? String(detected) : "ryoku";
}

function commandFor(dependency, distro) {
    const commands = dependency && dependency.commands;
    if (!commands) return "";
    const command = commands[String(distro || "")];
    return typeof command === "string" ? command : "";
}

function firstCommand(text) {
    for (const line of String(text || "").split("\n")) {
        const trimmed = line.trim();
        if (trimmed.length === 0 || trimmed.charAt(0) === "#") continue;
        return trimmed;
    }
    return String(text || "").trim();
}

function copyArgv(text) {
    return ["wl-copy", "--", String(text === undefined || text === null ? "" : text)];
}


function filterApps(apps, query) {
    const needle = String(query || "").trim().toLowerCase();
    const source = apps || [];
    const kept = [];
    for (let i = 0; i < source.length; i++) {
        const app = source[i];
        if (!app) continue;
        if (needle.length === 0) {
            kept.push(app);
            continue;
        }
        const name = String(app.name || "").toLowerCase();
        const packageName = String(app.package || "").toLowerCase();
        if (name.includes(needle) || packageName.includes(needle)) kept.push(app);
    }
    return kept;
}

function appLabel(app) {
    const name = String((app && app.name) || "").trim();
    if (name.length > 0) return name;
    const packageName = String((app && app.package) || "");
    const segments = packageName.split(".");
    return segments[segments.length - 1] || packageName;
}
