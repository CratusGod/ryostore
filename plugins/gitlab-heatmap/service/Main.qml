pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// The heatmap's headless settings and parsed calendar, refreshed through
// bin/gl-contrib (GitLab's public calendar.json, no token). The widget binds
// this through pluginApi.mainInstance.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    // ── settings ─────────────────────────────────────────────────────────────
    // A value set from the widget lands here at once and is persisted through
    // the host: saveSetting on the bar, ryoku-plugins-place (the same tool the
    // desktop's own menu writes with) on the wallpaper, which has no
    // saveSetting. A saved value read back from the host then agrees with it.
    property var _over: ({})
    function cfg(k, d) {
        if (_over[k] !== undefined) return _over[k];
        if (settings && settings[k] !== undefined && settings[k] !== null && settings[k] !== "") return settings[k];
        return d;
    }
    function setSetting(k, v) {
        var o = JSON.parse(JSON.stringify(_over));
        o[k] = v;
        _over = o;
        if (pluginApi && typeof pluginApi.saveSetting === "function") {
            pluginApi.saveSetting(k, v);
        } else {
            var patch = ({});
            patch[k] = v;
            Quickshell.execDetached(["ryoku-plugins-place", "gitlab-heatmap", "settings", JSON.stringify(patch)]);
        }
    }

    readonly property string username: String(cfg("username", "")).trim()
    readonly property int refreshMin: Math.max(10, Math.min(240, Number(cfg("refreshMin", 30))))

    function setUsername(name) { setSetting("username", String(name).trim()); }

    // ── data ─────────────────────────────────────────────────────────────────

    // { "YYYY-MM-DD": { count, level } }
    property var days: ({})
    property int streak: 0
    property bool loading: false
    property string error: ""
    property string _buf: ""
    // a refresh asked for while one runs is queued, not raced: stopping and
    // restarting the process in one go can drop the new run
    property bool _again: false

    function refresh() {
        if (!pluginApi || username.length === 0) return;
        if (fetch.running) { _again = true; return; }
        error = "";
        loading = true;
        _buf = "";
        fetch.command = [pluginApi.pluginDir + "/bin/gl-contrib", username];
        fetch.running = true;
    }

    function _iso(d) {
        var m = d.getMonth() + 1, dd = d.getDate();
        return d.getFullYear() + "-" + (m < 10 ? "0" : "") + m + "-" + (dd < 10 ? "0" : "") + dd;
    }

    function _apply(text) {
        var j;
        try { j = JSON.parse(text); } catch (e) { error = "bad response"; return; }
        if (j.error) { error = j.error; return; }
        if (j.user !== username) return; // stale answer
        var map = {};
        for (var i = 0; i < j.days.length; i++) {
            var d = j.days[i];
            map[d.date] = { count: d.count, level: d.level };
        }
        // Current streak: back from today (or yesterday, if today is still 0).
        var cur = 0;
        var t = new Date();
        if (!(map[_iso(t)] && map[_iso(t)].count > 0)) t.setDate(t.getDate() - 1);
        while (map[_iso(t)] && map[_iso(t)].count > 0) { cur += 1; t.setDate(t.getDate() - 1); }
        days = map;
        streak = cur;
    }

    Process {
        id: fetch
        stdout: StdioCollector { onStreamFinished: svc._buf = text }
        onExited: (code) => {
            svc.loading = false;
            svc._apply(svc._buf);
            svc._buf = "";
            if (svc._again) { svc._again = false; svc.refresh(); }
        }
    }

    onUsernameChanged: { days = ({}); streak = 0; refresh(); }
    onPluginApiChanged: refresh()

    Timer {
        interval: svc.refreshMin * 60 * 1000
        running: true
        repeat: true
        onTriggered: svc.refresh()
    }
}
