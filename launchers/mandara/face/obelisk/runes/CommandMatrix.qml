/* CommandMatrix.qml — System-wide Command & Skill Catalog
 * ========================================================
 * Central repository for all SiM commands, macros, and skills.
 * Pulls from the legacy Sibyls data structure to provide a 
 * unified help matrix for the Launcher and SiMComm.
 */
pragma Singleton
import QtQuick
import "../../tw" as TW

QtObject {
    id: matrix

    // ── Command Categories ──
    readonly property var modes: ({
        "sun":       { id: "sun",       icon: "☀", color: "#f59e0b", prefix: "", desc: "Doing — the bench of making and work" },
        "moon":      { id: "moon",      icon: "☽", color: "#818cf8", prefix: "", desc: "Living — the daily round, the house's levers, the compass" },
        "celestial": { id: "celestial", icon: "✧", color: "#ffffff", prefix: "", desc: "Playing — media, capture, delight" }
    })

    // ── Command Data — the daily segments, by house ──
    readonly property var commandSets: ({
        "sun": [
            { cmd: "open <app>",   desc: "Launch an application by name" },
            { cmd: "edit <file>",  desc: "Open a file or folder" },
            { cmd: "term",         desc: "A fresh terminal" },
            { cmd: "find <name>",  desc: "Search the filesystem" },
            { cmd: "sun",          desc: "Drive Sun — this house", badge: { text: "BREATH", color: "#f59e0b" } }
        ],
        "moon": [
            { cmd: "ask <question>", desc: "Ask Rashin — the compass answers" },
            { cmd: "note <words>",   desc: "Keep a note in ~/Notes/inbox.md" },
            { cmd: "timer <25m>",    desc: "A timer — she calls when it ends" },
            { cmd: "clip <words>",   desc: "Copy the line to the clipboard" },
            { cmd: "vol <0-100>",    desc: "Set the volume" },
            { cmd: "mute",           desc: "Mute / unmute" },
            { cmd: "bright <0-100>", desc: "Set the brightness" },
            { cmd: "wifi",           desc: "The network console" },
            { cmd: "lock",           desc: "Lock the session" },
            { cmd: "sleep",          desc: "Suspend the machine" },
            { cmd: "moon",           desc: "Drive Moon — this house", badge: { text: "BREATH", color: "#818cf8" } }
        ],
        "celestial": [
            { cmd: "play",  desc: "Play the media" },
            { cmd: "pause", desc: "Pause the media" },
            { cmd: "next",  desc: "The next track" },
            { cmd: "prev",  desc: "The previous track" },
            { cmd: "shot",  desc: "Keep a screenshot in Pictures" },
            { cmd: "celestial", desc: "Drive Celestial — this house", badge: { text: "BREATH", color: "#ffffff" } }
        ]
    })

    function getCommands(mode) {
        return commandSets[mode] || []
    }

    function search(query) {
        if (!query) return []
        var q = query.toLowerCase()
        var results = []
        for (var mode in commandSets) {
            var set = commandSets[mode]
            for (var i = 0; i < set.length; i++) {
                if (set[i].cmd.toLowerCase().includes(q) || set[i].desc.toLowerCase().includes(q)) {
                    results.push(set[i])
                }
            }
        }
        return results
    }
}
