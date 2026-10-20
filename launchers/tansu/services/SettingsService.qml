pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tansu launcher settings, read by the launcher's surface (the peek, the
// 24-hour clock, the LCD wallpaper, the clipboard watcher and the web
// suggestions). Only what the launcher owns lives here; everything Ryoku owns
// (displays, the compositor, keybinds, network, the system theme, the wallpaper
// daemon) is not a setting here.
//
// The values are written to a small JSON file so they survive a shell reload or
// a store update. It is the launcher's own file, never Ryoku's shell.json.
Singleton {
    id: root

    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME")
        || (Quickshell.env("HOME") + "/.config")) + "/ryoku/launcher-tansu.json"

    // Click-outside is the bar's Quick Panel setting, and the launcher follows
    // it rather than keeping a second switch of its own.
    readonly property string barConfigPath: (Quickshell.env("XDG_CONFIG_HOME")
        || (Quickshell.env("HOME") + "/.config")) + "/ryoku/barstyle-tansu.json"

    property bool clickOutside: true

    property bool loaded: false

    readonly property var defaults: ({
        "appearance.iconStyle": "outline",
        "time.use24h": true,
        "panel.peek": 72,
        "quick.flat": false,
        "quick.phoneShadow": true,
        "wallpaper.themedTransition": false,
        "launcher.lcdWallpaper": true,
        "launcher.clipboard": false,
        "launcher.webSuggestions": false
    })

    property var values: root.defaults

    function get(path, fallback) {
        const value = root.values[path]
        return value === undefined ? fallback : value
    }

    function flag(path) {
        return root.get(path, false) === true
    }

    function set(path, value) {
        if (root.defaults[path] === undefined)
            return
        const next = Object.assign({}, root.values)
        next[path] = value
        root.values = next
        root.persist()
    }

    function toggle(path) {
        root.set(path, !root.flag(path))
    }

    function reset() {
        root.values = root.defaults
        root.persist()
    }

    // Only the known keys, and only when the saved value is the same shape as
    // its default, so a hand-edited or older file cannot inject a setting.
    function adopt(raw) {
        let saved = null
        try {
            saved = JSON.parse(raw || "{}")
        } catch (e) {
            saved = null
        }
        if (saved && typeof saved === "object") {
            const next = Object.assign({}, root.defaults)
            for (const key of Object.keys(root.defaults)) {
                const value = saved[key]
                if (value !== undefined && typeof value === typeof root.defaults[key])
                    next[key] = value
            }
            root.values = next
        }
        root.loaded = true
    }

    function persist() {
        if (root.loaded)
            writeTimer.restart()
    }

    Timer {
        id: writeTimer
        interval: 250
        onTriggered: store.setText(JSON.stringify(root.values, null, 2))
    }

    FileView {
        id: store
        path: root.configPath
        blockLoading: true
        printErrors: false
        onLoaded: root.adopt(text())
        onLoadFailed: root.loaded = true
    }

    function adoptBar(raw) {
        let saved = null
        try {
            saved = JSON.parse(raw || "{}")
        } catch (e) {
            saved = null
        }
        const value = saved && typeof saved === "object" ? saved["panel.clickOutside"] : undefined
        root.clickOutside = typeof value === "boolean" ? value : true
    }

    FileView {
        id: barStore

        path: root.barConfigPath
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.adoptBar(text())
        onLoadFailed: root.clickOutside = true
    }
}
