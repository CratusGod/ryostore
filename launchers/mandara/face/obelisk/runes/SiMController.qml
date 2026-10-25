/* SiMController.qml — the Obelisk's resolver (the port's hand)
 * ==========================================================
 * In Jurai shell this file was the Neural Orchestrator: it
 * bridged the lens to the Python core, the ROM registry and
 * Insei. The core did not cross into the launcher. What stands
 * here keeps the controller's exact public shape — the Obelisk
 * and the lens cannot tell the difference — and resolves
 * locally, in the open:
 *
 *   sections / flatModel / activeIdx / selectedItem — hers
 *   setSearchQuery (60ms debounce, version-guarded)  — hers
 *   transformApp / transformFile                    — hers
 *   scoreItems (exact 1000 · prefix 500 · contains
 *     100 · usage × 25)                             — hers
 *   INTENTS · APPLICATIONS · FILESYSTEM sections    — hers
 *
 * The sources changed, and PROVENANCE says so: desktop entries
 * come from the host (DesktopEntries, launched through
 * AppLaunch), files from a plain find under the home, intents
 * from her own RuneRegistry instead of the neural classifier,
 * and a line nothing answers to becomes a command — her road,
 * not a conversation. ROMs, the arsenal wrap and askInsei are
 * gone with the court they served.
 */
import QtQuick
import Quickshell
import Quickshell.Io
import "../../tw" as TW
import "." as Runes
import shell.services

Item {
    id: root

    // ── Public API (hers, unchanged) ─────────────────────────────
    property string searchQuery: ""
    property var    sections:    []
    property var    flatModel:   []
    property int    activeIdx:   -1
    property var    selectedItem: activeIdx >= 0 ? flatModel[activeIdx] : null
    property bool   isSearching:  false

    // ── Communication state — at rest; there is no core ─────────
    property string currentPrompt:   ""
    property string currentResponse: ""
    property string thinkingPhase:   "idle"
    property bool   isStreaming:     false
    property string lastToolExecuted: ""
    property bool   toolExecuting:   false

    signal itemExecuted(var item)

    // ── ROM state — the ROMs did not cross; the seat stays ──────
    property string activeRomPath: ""
    property string activeRomName: ""

    function closeRom() {
        activeRomPath = ""
        activeRomName = ""
        setSearchQuery("")
        currentResponse = ""
        isStreaming = false
        thinkingPhase = "idle"
    }

    // ── Internal state ───────────────────────────────────────────
    property int _searchVersion: 0

    Timer {
        id: searchDebounce
        interval: 60
        onTriggered: root.performSearch()
    }

    function setSearchQuery(query) {
        searchQuery = query;
        _searchVersion++;
        searchDebounce.restart();
    }

    // File search rides a process; its answer lands after the
    // synchronous roads have already spoken, and merges in.
    property var _pendingQuery: ""
    Process {
        id: fileSearch
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var q = root._pendingQuery;
                var name = q.startsWith("/") ? q.substring(1)
                    : q.toLowerCase().startsWith("files ") ? q.substring(6) : q;
                var rows = [];
                var lines = text.split("\n");
                for (var i = 0; i < lines.length && rows.length < 12; i++) {
                    var p = lines[i].trim();
                    if (p.length === 0) continue;
                    rows.push(root.transformFile({
                        path: p,
                        name: p.split("/").pop(),
                        isDir: false
                    }));
                }
                root._mergeFiles(rows);
            }
        }
    }

    function _mergeFiles(fileRows) {
        if (root._pendingQuery !== root.searchQuery.trim())
            return;
        var items = [];
        for (var s = 0; s < root.sections.length; s++)
            for (var i = 0; i < root.sections[s].items.length; i++)
                if (root.sections[s].items[i].category !== "files")
                    items.push(root.sections[s].items[i]);
        for (var f = 0; f < fileRows.length; f++)
            items.push(fileRows[f]);
        var defs = [
            { id: "actions", title: "INTENTS",      icon: "bolt",   priority: 0 },
            { id: "apps",    title: "APPLICATIONS", icon: "apps",   priority: 1 },
            { id: "files",   title: "FILESYSTEM",   icon: "folder", priority: 2 }
        ];
        var newSections = groupBySection(scoreItems(items, root.searchQuery), defs);
        sections = newSections;
        flatModel = flattenSections(newSections);
        if (activeIdx < 0 && flatModel.length > 0)
            activeIdx = getFirstItemIndex();
        isSearching = false;
    }

    function performSearch() {
        var currentVersion = _searchVersion;
        isSearching = true;

        var allItems = [];
        var q = searchQuery.trim();
        if (q.length === 0) {
            sections = [];
            flatModel = [];
            activeIdx = -1;
            isSearching = false;
            return;
        }

        // 0. Her name is a door (his word, 2026-10-25): a line
        // opening with "rashin" goes straight to the compass
        // window, carrying the rest of the line as its seed.
        var routed = false;
        var ql0 = q.toLowerCase();
        if (ql0 === "rashin" || ql0.startsWith("rashin ")) {
            var seed0 = q.slice(6).trim();
            allItems.push({
                id: "rashin:" + seed0,
                label: seed0 ? "Ask Rashin" : "Open Rashin",
                icon: "羅",
                category: "rashin",
                data: { seed: seed0 },
                score: 1100
            });
            routed = true;
        }

        // 1. App search — the live desktop entries, matched on
        // name, id, or startup class, as hers always were.
        var wanted = q.toLowerCase();
        var apps = [];
        var seenIds = {};
        var entries = DesktopEntries.applications.values || [];
        for (var i = 0; i < entries.length && apps.length < 12; i++) {
            var e = entries[i];
            if (!e || !e.name || e.noDisplay === true) continue;
            var hay = (e.name + " " + (e.id || "") + " " + (e.startupClass || "")).toLowerCase();
            if (hay.indexOf(wanted) < 0) continue;
            if (e.id && seenIds[e.id]) continue;
            if (e.id) seenIds[e.id] = true;
            apps.push(e);
        }
        for (var a = 0; !routed && a < apps.length; a++)
            allItems.push(transformApp(apps[a]));

        // 2. Intent search — her own RuneRegistry answers, where
        // the neural classifier used to. A matched rune becomes
        // an intent carrying the rest of the line as its argument.
        var rune = null;
        try { rune = Runes.RuneRegistry.match(q); } catch (err) { rune = null; }
        if (!routed && rune) {
            var rest = (q.startsWith("~" + rune.id) || q.startsWith("?" + rune.id))
                ? q.slice(rune.id.length + 1).trim()
                : q.slice(rune.label.length).trim();
            // Segment templates (his word, 2026-10-25): "{arg}"
            // takes the rest of the line into the command;
            // takesArg:false segments stand alone.
            var fullCmd = rune.cmd || "";
            if (fullCmd.indexOf("{arg}") >= 0)
                fullCmd = fullCmd.split("{arg}").join(rest);
            else if (rest.length > 0 && rune.takesArg !== false)
                fullCmd = (fullCmd + " " + rest).trim();
            allItems.push({
                id: "intent:" + rune.id,
                label: rune.label + (rest.length > 0 ? " " + rest : ""),
                icon: rune.icon,
                category: "actions",
                data: { cmd: fullCmd, rune: rune, arg: rest,
                        mode: fullCmd.startsWith("~") ? fullCmd.slice(1) : "" },
                score: 1100
            });
        }

        // 3. A line nothing answers to: if it is natural
        // language, Rashin answers — the line is redirected
        // to the compass window (his word, 2026-10-25). Else
        // it is a command — her road. The Run label carries a
        // length limit (her author's word): a pasted wall of
        // letters must not trail out of her — the row names
        // the run, elided; the full line still rides data.cmd
        // and executes whole.
        if (allItems.length === 0) {
            if (isNaturalLanguage(q)) {
                allItems.push({
                    id: "rashin:" + q,
                    label: "Ask Rashin",
                    icon: "羅",
                    category: "rashin",
                    data: { seed: q },
                    score: 300
                });
            } else {
                var shown = q.length > 32 ? q.slice(0, 32) + "…" : q
                allItems.push({
                    id: "command:" + q,
                    label: "Run  " + shown,
                    icon: "›",
                    category: "actions",
                    data: { cmd: q },
                    score: 300
                });
            }
        }

        // 4. Score and group (hers).
        var sectionsDef = [
            { id: "rashin",  title: "RASHIN",       icon: "羅",     priority: 0 },
            { id: "actions", title: "INTENTS",      icon: "bolt",   priority: 1 },
            { id: "apps",    title: "APPLICATIONS", icon: "apps",   priority: 2 },
            { id: "files",   title: "FILESYSTEM",   icon: "folder", priority: 3 }
        ];
        var scoredItems = scoreItems(allItems, searchQuery);
        var newSections = groupBySection(scoredItems, sectionsDef);

        if (currentVersion !== _searchVersion) return;

        sections = newSections;
        flatModel = flattenSections(newSections);
        activeIdx = flatModel.length > 0 ? getFirstItemIndex() : -1;
        isSearching = false;

        // 5. File search — if the query is path-shaped or asks
        // for files, as hers always did. Async; merges on landing.
        var sunFiles = TW.SiMOrchestrator.driveMode === "sun" && q.length >= 3 && !routed;
        if (q.startsWith("/") || q.toLowerCase().startsWith("files ") || sunFiles) {
            var fileQuery = q.startsWith("/") ? q.substring(1)
                : q.toLowerCase().startsWith("files ") ? q.substring(6) : q;
            if (fileQuery.length >= 2) {
                root._pendingQuery = q;
                fileSearch.command = ["find", Quickshell.env("HOME") || "",
                    "-maxdepth", "4", "-iname", "*" + fileQuery + "*",
                    "-not", "-path", "*/.*"];
                fileSearch.running = true;
            }
        }
    }

    // ── Natural language recognition (his word, 2026-10-25) ──
    // A line is language, not a command, when it closes with a
    // question, or runs three-plus words carrying the small
    // words speech is built from. Gibberish and command-shaped
    // lines stay on the Run road; language goes to Rashin.
    function isNaturalLanguage(text) {
        var t = (text || "").trim();
        if (t.endsWith("?")) return true;
        var words = t.toLowerCase().split(/\s+/);
        if (words.length < 3) return false;
        var small = { "the": 1, "a": 1, "an": 1, "to": 1, "of": 1, "and": 1,
            "or": 1, "is": 1, "are": 1, "was": 1, "can": 1, "could": 1,
            "would": 1, "should": 1, "what": 1, "how": 1, "why": 1,
            "when": 1, "where": 1, "who": 1, "tell": 1, "me": 1, "my": 1,
            "please": 1, "write": 1, "say": 1, "says": 1, "mean": 1,
            "means": 1, "do": 1, "does": 1, "did": 1, "you": 1, "your": 1,
            "it": 1, "that": 1, "this": 1, "with": 1, "for": 1, "on": 1,
            "in": 1, "about": 1, "think": 1, "feel": 1, "want": 1,
            "need": 1, "like": 1, "make": 1, "help": 1 };
        for (var i = 0; i < words.length; i++)
            if (small[words[i]]) return true;
        return false;
    }

    // ── Helper logic (hers, verbatim where it counts) ────────────
    function transformApp(app) {
        return {
            id: app.id || app.exec,
            label: app.name,
            icon: app.icon,
            category: "apps",
            data: app,
            score: 0
        };
    }

    function transformFile(file) {
        return {
            id: file.path,
            label: file.name,
            icon: file.icon || (file.isDir ? "folder" : "description"),
            category: "files",
            data: file,
            score: 0
        };
    }

    function scoreItems(items, query) {
        if (!query) return items;
        var q = query.toLowerCase();
        return items.map(it => {
            var label = it.label.toLowerCase();
            if (label === q) it.score = 1000;
            else if (label.startsWith(q)) it.score = 500;
            else if (label.includes(q)) it.score = 100;
            else it.score = Math.max(it.score, 0);

            // Boost based on historical usage frequency (hers)
            var usage = TW.SiMOrchestrator.itemUseCounts[it.id] || 0;
            it.score += usage * 25;

            // The breath's bias (his word, 2026-10-25): under
            // Sun her work-and-making bench rides warmer; under
            // Celestial, games and media; Moon stays pure.
            if (it.category === "apps") {
                var mode = TW.SiMOrchestrator.driveMode;
                var keys = mode === "sun"
                    ? ["mail", "calendar", "office", "document", "note", "task", "code", "editor", "terminal", "git", "studio", "design", "pdf"]
                    : mode === "celestial"
                    ? ["game", "steam", "media", "music", "video", "photo", "stream", "movie", "retro", "emulat", "jellyfin", "spotify"]
                    : null;
                if (keys) {
                    var d = it.data || {};
                    var hay2 = (it.label + " " + (d.id || "") + " " + (d.comment || "") + " " + (d.genericName || "")).toLowerCase();
                    for (var k = 0; k < keys.length; k++)
                        if (hay2.indexOf(keys[k]) >= 0) { it.score += 150; break; }
                }
            }

            return it;
        }).filter(it => it.score > 0).sort((a, b) => b.score - a.score);
    }

    function groupBySection(items, defs) {
        var groups = {};
        items.forEach(it => {
            if (!groups[it.category]) groups[it.category] = [];
            groups[it.category].push(it);
        });

        var out = [];
        defs.forEach(def => {
            if (groups[def.id] && groups[def.id].length > 0) {
                out.push({
                    id: def.id,
                    title: def.title,
                    icon: def.icon,
                    items: groups[def.id]
                });
            }
        });
        return out;
    }

    function flattenSections(sections) {
        var out = [];
        sections.forEach(s => {
            out.push({ isHeader: true, title: s.title, icon: s.icon });
            s.items.forEach(it => {
                out.push({ isHeader: false, item: it });
            });
        });
        return out;
    }

    function getFirstItemIndex() {
        for (var i = 0; i < flatModel.length; i++) {
            if (!flatModel[i].isHeader) return i;
        }
        return -1;
    }

    function selectNext() {
        if (flatModel.length === 0) return;
        var start = activeIdx;
        do {
            activeIdx = (activeIdx + 1) % flatModel.length;
        } while (flatModel[activeIdx].isHeader && activeIdx !== start);
    }

    function selectPrevious() {
        if (flatModel.length === 0) return;
        var start = activeIdx;
        do {
            activeIdx = (activeIdx - 1 + flatModel.length) % flatModel.length;
        } while (flatModel[activeIdx].isHeader && activeIdx !== start);
    }

    // Section jumps (Page / Ctrl+arrows): land on the first
    // entry of the next or previous company — INTENTS,
    // APPLICATIONS, FILESYSTEM, RASHIN — wrapping whole.
    function selectSection(dir) {
        if (flatModel.length === 0) return;
        var n = flatModel.length;
        for (var step = 1; step <= n; step++) {
            var idx = ((activeIdx + dir * step) % n + n) % n;
            if (flatModel[idx].isHeader) {
                var j = idx;
                for (var k = 0; k < n; k++) {
                    j = ((j + dir) % n + n) % n;
                    if (!flatModel[j].isHeader) { activeIdx = j; return; }
                }
                return;
            }
        }
    }

    // The nth entry by number (Ctrl+1–9 casts outright, as the
    // portal's badges always promised): 1-based over entries,
    // headers not counted.
    function castOrdinal(num) {
        var c = 0;
        for (var i = 0; i < flatModel.length; i++) {
            if (flatModel[i].isHeader) continue;
            c++;
            if (c === num) { activeIdx = i; executeSelected(); return; }
        }
    }

    function executeSelected() {
        if (selectedItem && !selectedItem.isHeader) {
            var item = selectedItem.item;
            TW.SiMOrchestrator.recordUsage(item.id);
            if (item.category === "apps") {
                AppLaunch.run(item.data, null);
                itemExecuted(item);
            } else if (item.category === "rashin") {
                TW.SiMOrchestrator.requestRashin((item.data && item.data.seed) || "");
                itemExecuted(item);
            } else if (item.category === "actions") {
                var cmd = (item.data && item.data.cmd) || "";
                var arg = (item.data && item.data.arg) || "";
                if (cmd.startsWith("~")) {
                    // A breath, executed: she changes how she drives.
                    TW.SiMOrchestrator.setDriveMode(cmd.slice(1));
                    itemExecuted(item);
                } else if (cmd.startsWith("@session:")) {
                    // Session rides the host seam, as the store's
                    // law requires — never a raw init tool.
                    SessionActions.run(cmd.slice(9));
                    itemExecuted(item);
                } else if (cmd === "@rashin") {
                    TW.SiMOrchestrator.requestRashin(arg);
                    itemExecuted(item);
                } else if (cmd === "@open") {
                    // The typed road for the open segment: the
                    // best-named application launches outright.
                    var entries2 = DesktopEntries.applications.values || [];
                    var hit = null;
                    for (var oi = 0; oi < entries2.length; oi++) {
                        var oe = entries2[oi];
                        if (oe && oe.name && oe.noDisplay !== true
                                && oe.name.toLowerCase().indexOf(arg.toLowerCase()) >= 0) { hit = oe; break; }
                    }
                    if (hit) { AppLaunch.run(hit, null); itemExecuted(item); }
                } else if (cmd === "@files") {
                    // The typed road for find: she stays open
                    // and the filesystem answers in her rack.
                    setSearchQuery("files " + arg);
                } else {
                    if (cmd.startsWith("/")) cmd = cmd.substring(1);
                    if (cmd.length > 0)
                        TW.SiMOrchestrator.runNativeCommand(cmd);
                    itemExecuted(item);
                }
            } else if (item.category === "files") {
                Qt.openUrlExternally("file://" + item.data.path);
                itemExecuted(item);
            }
        }
    }

    // ── The portal's feed — runes first, then her apps ───────────
    // The Lucid portal used to drink from the neural classifier;
    // it drinks from the resolver now. Her runes lead (her
    // grammar first), and the applications answering to the
    // word stand behind them — an app picked from the portal
    // launches, it does not lock as a chip.
    function suggestions(query, lockedTokens) {
        var out = [];
        var runes = [];
        try { runes = Runes.RuneRegistry.suggestions(query, lockedTokens); } catch (e) { runes = []; }
        for (var i = 0; i < runes.length && out.length < 8; i++) {
            var r = Object.assign({}, runes[i]);
            r.kind = "rune";
            out.push(r);
        }
        var q = (query || "").trim().toLowerCase();
        var word = q.split(/\s+/).pop() || "";
        if ((!lockedTokens || lockedTokens.length === 0) && word.length >= 2) {
            var entries = DesktopEntries.applications.values || [];
            var added = 0;
            for (var a = 0; a < entries.length && added < 4 && out.length < 8; a++) {
                var e = entries[a];
                if (!e || !e.name || e.noDisplay === true) continue;
                if (e.name.toLowerCase().indexOf(word) < 0) continue;
                out.push({
                    id: e.id || e.name,
                    kind: "app",
                    label: e.name,
                    preview: e.comment || "",
                    icon: "◈",
                    color: "#22D3EE",
                    isPreset: false
                });
                added++;
            }
        }
        return out;
    }

    // A portal pick that is an application launches it — her
    // usage memory hears it, as an execution from the rack
    // would be heard.
    function launchSuggestion(item) {
        if (!item || item.kind !== "app")
            return;
        var entries = DesktopEntries.applications.values || [];
        for (var i = 0; i < entries.length; i++) {
            var e = entries[i];
            if (e && (e.id === item.id || e.name === item.id)) {
                TW.SiMOrchestrator.recordUsage(item.id);
                AppLaunch.run(e, null);
                itemExecuted({ id: item.id, category: "apps" });
                return;
            }
        }
    }

    // ── The ghost's second source — her own top answer ──────────
    // When no rune completes the word, the label of her best
    // answer may: the remainder ghosts behind the line.
    readonly property string ghostCompletion: {
        var q = searchQuery.trim();
        if (q.length === 0) return "";
        for (var i = 0; i < flatModel.length; i++) {
            if (flatModel[i].isHeader) continue;
            var it = flatModel[i].item;
            if (!it || !it.label || it.category === "actions" || it.category === "rashin") return "";
            var label = it.label;
            if (label.toLowerCase().startsWith(q.toLowerCase()) && label.length > q.length)
                return label.substring(q.length);
            return "";
        }
        return "";
    }
}
