/* RuneRegistry.qml — Rune Catalog & Lookup
 * ==========================================
 * Subsystem 2 of 3 in the Obelisk runes architecture.
 *
 * Single source of truth for all rune definitions.
 * Each rune maps an intent fragment to a command, icon, color, and fold.
 *
 * Colors always come from TW.SiMOrchestrator tokens — never hardcoded.
 *
 * API:
 *   RuneRegistry.resolve(id)    → rune object or undefined
 *   RuneRegistry.match(input)   → best rune match or null
 *   RuneRegistry.catalog        → full array (read-only)
 *
 * The port adds three roads the neural classifier used to walk
 * (NLU did not cross — see PROVENANCE):
 *   RuneRegistry.classify(input)          → { rune, confidence }
 *   RuneRegistry.ghostText(input)         → completion suffix
 *   RuneRegistry.suggestions(query, toks) → portal/pill entries
 */
pragma Singleton
import QtQuick
import "../../tw" as TW

QtObject {
    id: registry

    // ── Catalog ───────────────────────────────────────────────────────
    readonly property var catalog: [
        // ── The daily tongue (his word, 2026-10-25) ─────────────
        // The segment system was fluent in the hunt; the hunt is
        // shelved and the segments came home. Everything fits
        // three houses now — Sun (doing), Moon (living), Celestial
        // (playing) — and a segment's color is its house's color.
        // The hunt catalog stands in this repo's history, whole.
        // A segment is data: a word, a house, a command template;
        // "{arg}" takes the rest of the line, an "action" rides a
        // door in the Obelisk instead of assembling, and
        // takesArg:false segments stand alone.
        // ── SUN — doing: the bench of making and work ───────────
        { id: "open",     house: "sun", icon: "◈",  label: "open",  color: TW.SiMOrchestrator.styleAccents["sun"], action: "open",  cmd: "@open",    desc: "open an app by name",            terminal: true },
        { id: "edit",     house: "sun", icon: "✎",  label: "edit",  color: TW.SiMOrchestrator.styleAccents["sun"], cmd: "xdg-open {arg}", desc: "open a file or folder",     terminal: true },
        { id: "term",     house: "sun", icon: "❯",  label: "term",  color: TW.SiMOrchestrator.styleAccents["sun"], cmd: "ghostty", takesArg: false, desc: "a fresh terminal",  terminal: true },
        { id: "find",     house: "sun", icon: "⊕",  label: "find",  color: TW.SiMOrchestrator.styleAccents["sun"], action: "files", cmd: "@files",   desc: "search the filesystem",        terminal: true },
        // ── MOON — living: the daily round, the house's levers ──
        { id: "ask",      house: "moon", icon: "羅", label: "ask",   color: TW.SiMOrchestrator.styleAccents["moon"], action: "rashin", cmd: "@rashin", desc: "ask Rashin — the line rides to the compass", terminal: true },
        { id: "note",     house: "moon", icon: "✐",  label: "note",  color: TW.SiMOrchestrator.styleAccents["moon"], cmd: 'mkdir -p ~/Notes && printf "[%s] %s\n" "$(date +%FT%T)" "{arg}" >> ~/Notes/inbox.md', desc: "keep a note in ~/Notes/inbox.md", terminal: true },
        { id: "timer",    house: "moon", icon: "◷",  label: "timer", color: TW.SiMOrchestrator.styleAccents["moon"], cmd: 'sleep {arg} && notify-send Mandara "time — your timer is done"', desc: "timer <25m> — she calls when it ends", terminal: true },
        { id: "clip",     house: "moon", icon: "⧉",  label: "clip",  color: TW.SiMOrchestrator.styleAccents["moon"], cmd: 'printf %s "{arg}" | wl-copy', desc: "copy the line to the clipboard", terminal: true },
        { id: "lock",     house: "moon", icon: "◐",  label: "lock",  color: TW.SiMOrchestrator.styleAccents["moon"], cmd: "@session:lock", takesArg: false, desc: "lock the session", terminal: true },
        { id: "sleep",    house: "moon", icon: "◌",  label: "sleep", color: TW.SiMOrchestrator.styleAccents["moon"], cmd: "@session:suspend", takesArg: false, desc: "suspend the machine", terminal: true },
        { id: "vol",      house: "moon", icon: "♪",  label: "vol",   color: TW.SiMOrchestrator.styleAccents["moon"], cmd: "wpctl set-volume @DEFAULT_AUDIO_SINK@ {arg}%", desc: "volume <0-100>", terminal: true },
        { id: "mute",     house: "moon", icon: "∅",  label: "mute",  color: TW.SiMOrchestrator.styleAccents["moon"], cmd: "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", takesArg: false, desc: "mute / unmute", terminal: true },
        { id: "wifi",     house: "moon", icon: "≋",  label: "wifi",  color: TW.SiMOrchestrator.styleAccents["moon"], cmd: "ghostty -e nmtui", takesArg: false, desc: "the network console", terminal: true },
        { id: "bright",   house: "moon", icon: "☼",  label: "bright", color: TW.SiMOrchestrator.styleAccents["moon"], cmd: "brightnessctl set {arg}%", desc: "brightness <0-100>", terminal: true },
        // ── CELESTIAL — playing: delight and capture ────────────
        { id: "play",     house: "celestial", icon: "▶",  label: "play",  color: TW.SiMOrchestrator.styleAccents["celestial"], cmd: "playerctl play",     takesArg: false, desc: "play the media",        terminal: true },
        { id: "pause",    house: "celestial", icon: "‖",  label: "pause", color: TW.SiMOrchestrator.styleAccents["celestial"], cmd: "playerctl pause",    takesArg: false, desc: "pause the media",       terminal: true },
        { id: "next",     house: "celestial", icon: "»",  label: "next",  color: TW.SiMOrchestrator.styleAccents["celestial"], cmd: "playerctl next",     takesArg: false, desc: "the next track",        terminal: true },
        { id: "prev",     house: "celestial", icon: "«",  label: "prev",  color: TW.SiMOrchestrator.styleAccents["celestial"], cmd: "playerctl previous", takesArg: false, desc: "the previous track",    terminal: true },
        { id: "shot",     house: "celestial", icon: "◉",  label: "shot",  color: TW.SiMOrchestrator.styleAccents["celestial"], cmd: 'grim ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png && notify-send Mandara "shot kept in Pictures"', takesArg: false, desc: "keep a screenshot in Pictures", terminal: true },
        // ── The Breaths themselves — the doors between houses ──
        { id: "sun",      house: "sun",       icon: "☀",  label: "sun",      color: TW.SiMOrchestrator.styleAccents["sun"],      action: "mode", cmd: "~sun",       takesArg: false, desc: "drive Sun — focus",        terminal: true },
        { id: "moon",     house: "moon",      icon: "☽",  label: "moon",     color: TW.SiMOrchestrator.styleAccents["moon"],     action: "mode", cmd: "~moon",      takesArg: false, desc: "drive Moon — the daily round", terminal: true },
        { id: "celestial", house: "celestial", icon: "✧",  label: "celestial", color: TW.SiMOrchestrator.styleAccents["celestial"], action: "mode", cmd: "~celestial", takesArg: false, desc: "drive Celestial — play", terminal: true },
        { id: "star",     house: "celestial", icon: "✧",  label: "star",     color: TW.SiMOrchestrator.styleAccents["celestial"], action: "mode", cmd: "~celestial", takesArg: false, desc: "drive Celestial — play", terminal: true },
    ]

    // ── API ───────────────────────────────────────────────────────────

    // resolve(id) → rune object or undefined
    function resolve(id) {
        for (var i = 0; i < catalog.length; i++) {
            if (catalog[i].id === id) return catalog[i]
        }
        return undefined
    }

    // match(input) → best rune or null
    // Also matches bare IPv4/hostname as a target chip.
    function match(input) {
        var q   = input.trim().toLowerCase()
        var raw = input.trim()

        // Direct id / label match
        for (var i = 0; i < catalog.length; i++) {
            var r = catalog[i]
            if (q === r.id || q === r.label)              return r
            if (q === "~" + r.id   && r.terminal)         return r
            if (q === "?" + r.id   && r.terminal)         return r
        }

        // Fuzzy: input starts with rune id + space
        for (var j = 0; j < catalog.length; j++) {
            var rr = catalog[j]
            if (q.startsWith(rr.id + " ") || q.startsWith(rr.label + " ")) return rr
        }

        // Prefix match — ≥3 chars, unambiguous
        if (q.length >= 3) {
            var hits = []
            for (var k = 0; k < catalog.length; k++) {
                var pr = catalog[k]
                if (pr.id.startsWith(q) || pr.label.startsWith(q)) hits.push(pr)
            }
            if (hits.length === 1) return hits[0]
        }

        // IPv4 → target chip
        if (/^(\d{1,3}\.){3}\d{1,3}(:\d+)?$/.test(raw))
            return { id: raw, label: raw, icon: "◉", color: "#10b981", cmd: raw, terminal: false, isTarget: true }

        // Hostname → target chip
        if (/^[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$/.test(raw))
            return { id: raw, label: raw, icon: "◉", color: "#10b981", cmd: raw, terminal: false, isTarget: true }

        return null
    }

    // ── The port's roads (the classifier's chair, plainly sat) ───

    // classify(input) → { rune, confidence } — the lens asks this
    // on every keystroke; a registry answer is certain or absent.
    function classify(input) {
        var r = match(input || "")
        return { rune: r, confidence: r ? 1.0 : 0 }
    }

    // ghostText(input) → the completion tail for the word being
    // typed, when exactly one rune answers to it.
    function ghostText(input) {
        var q = (input || "").trim().toLowerCase()
        if (q.length < 2 || q.indexOf(" ") >= 0) return ""
        var hit = null
        for (var i = 0; i < catalog.length; i++) {
            var r = catalog[i]
            if (r.label.startsWith(q) && r.label !== q) {
                if (hit) return ""
                hit = r
            }
        }
        return hit ? hit.label.slice(q.length) : ""
    }

    // suggestions(query, lockedTokens) → the portal's entries:
    // runes answering to the word being typed. The neural
    // classifier's per-tool preset tables did not cross.
    function suggestions(query, lockedTokens) {
        var q = (query || "").trim().toLowerCase()
        var word = q.split(/\s+/).pop() || ""
        var out = []
        if (word.length === 0) return out
        // Dynamic (his word, 2026-10-25): kin of a house already
        // locked in lead the portal, and segments he actually
        // drives outrank the dictionary — her usage memory is
        // the ranking, not a static list.
        var house = null
        if (lockedTokens && lockedTokens.length > 0)
            house = lockedTokens[0].house || null
        var hits = []
        for (var i = 0; i < catalog.length; i++) {
            var r = catalog[i]
            if (r.id.startsWith(word) || r.label.startsWith(word)) {
                hits.push({ r: r,
                            u: TW.SiMOrchestrator.itemUseCounts["intent:" + r.id] || 0,
                            kin: (house && r.house === house) ? 1 : 0 })
            }
        }
        hits.sort(function(a, b) { return (b.kin - a.kin) || (b.u - a.u) })
        for (var j = 0; j < hits.length && out.length < 8; j++) {
            var h = hits[j].r
            out.push({ id: h.id, label: h.label, preview: h.desc || h.cmd,
                       icon: h.icon, color: h.color, isPreset: false })
        }
        return out
    }
}
