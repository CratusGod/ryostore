pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Prayer-times service: owns the daily fetch and the next-prayer math.
// The network runs once per day (bin/prayers caches to disk); the countdown
// recomputes locally every 20s, so the widget costs no idle traffic.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    readonly property string city: {
        var s = svc.settings;
        var v = s && s.city ? String(s.city).trim() : "";
        return v !== "" ? v : "Cairo";
    }
    readonly property string country: {
        var s = svc.settings;
        var v = s && s.country ? String(s.country).trim() : "";
        return v !== "" ? v : "Egypt";
    }
    readonly property string method: {
        var s = svc.settings;
        return s && s.method ? String(s.method) : "5";
    }
    readonly property string school: {
        var s = svc.settings;
        return s && s.school ? String(s.school) : "0";
    }
    readonly property bool use12h: {
        var s = svc.settings;
        return s ? s.use12h !== false : true;
    }
    readonly property bool remind: {
        var s = svc.settings;
        return s ? s.remind !== false : true;
    }
    readonly property int remindMin: {
        var s = svc.settings;
        var v = s && s.remindMin !== undefined ? Number(s.remindMin) : 5;
        if (isNaN(v) || v < 1) return 1;
        if (v > 30) return 30;
        return Math.floor(v);
    }
    readonly property bool remindSound: {
        var s = svc.settings;
        return s ? s.remindSound !== false : true;
    }

    readonly property var order: ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]

    property var timings: ({})
    property string gregDate: ""
    property string hijriDate: ""
    property string fetchDate: ""
    property bool stale: false
    property string error: ""
    property string nextName: ""
    property int nextInSec: -1
    // "yyyy-M-D|Name" already alerted, so the reminder fires once per prayer.
    property string alertedFor: ""

    function todayKey() {
        var d = new Date();
        return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
    }

    function fetchBin() {
        if (!svc.pluginApi || !svc.pluginApi.pluginDir) return "";
        return String(svc.pluginApi.pluginDir) + "/bin/prayers";
    }

    function refresh() {
        var bin = svc.fetchBin();
        if (bin === "" || fetchProc.running) return;
        fetchProc.command = [bin, svc.city, svc.country, svc.method, svc.school,
                             String(svc.pluginApi.stateDir || "")];
        fetchProc.running = true;
    }

    onCityChanged: svc.refresh()
    onCountryChanged: svc.refresh()
    onMethodChanged: svc.refresh()
    onSchoolChanged: svc.refresh()
    // The host sets pluginApi after the service exists, so the first fetch
    // has to wait for it rather than run from Component.onCompleted alone.
    onPluginApiChanged: svc.refresh()

    function fmtTime(hhmm) {
        var p = String(hhmm).split(":");
        if (p.length < 2) return String(hhmm);
        if (!svc.use12h) return p[0] + ":" + p[1];
        var h = Number(p[0]);
        var ap = h >= 12 ? "PM" : "AM";
        var h12 = h % 12;
        if (h12 === 0) h12 = 12;
        return h12 + ":" + p[1] + " " + ap;
    }

    function recompute() {
        // A new day means new times: refetch instead of counting stale ones.
        if (svc.fetchDate !== "" && svc.fetchDate !== svc.todayKey()) {
            svc.refresh();
            return;
        }
        var now = new Date();
        var best = "", bestSec = -1;
        for (var i = 0; i < svc.order.length; i++) {
            var t = svc.timings[svc.order[i]];
            if (!t) continue;
            var p = String(t).split(":");
            if (p.length < 2) continue;
            var dt = new Date(now.getFullYear(), now.getMonth(), now.getDate(),
                              Number(p[0]), Number(p[1]), 0);
            var sec = Math.floor((dt.getTime() - now.getTime()) / 1000);
            if (sec >= 0 && (bestSec < 0 || sec < bestSec)) {
                bestSec = sec;
                best = svc.order[i];
            }
        }
        if (bestSec < 0 && svc.timings["Fajr"]) {
            // Past Isha: next is tomorrow's Fajr (same wall time + 24h until
            // the midnight refetch corrects it).
            var f = String(svc.timings["Fajr"]).split(":");
            var fd = new Date(now.getFullYear(), now.getMonth(), now.getDate(),
                              Number(f[0]), Number(f[1]), 0);
            bestSec = Math.floor((fd.getTime() - now.getTime()) / 1000) + 86400;
            best = "Fajr";
        }
        svc.nextName = best;
        svc.nextInSec = bestSec;
        svc.maybeAlert();
    }

    function maybeAlert() {
        if (!svc.remind || svc.nextName === "" || svc.nextInSec <= 0) return;
        if (svc.nextInSec > svc.remindMin * 60) return;
        var key = svc.todayKey() + "|" + svc.nextName;
        if (svc.alertedFor === key) return;
        svc.alertedFor = key;
        var title = svc.nextName + " prayer in " + svc.countdown();
        var body = "at " + svc.fmtTime(svc.timings[svc.nextName])
            + " · " + svc.city + ", " + svc.country;
        Quickshell.execDetached(["notify-send", "-a", "Prayer Times", title, body]);
        if (svc.remindSound)
            Quickshell.execDetached(["paplay",
                "/usr/share/sounds/freedesktop/stereo/bell.oga"]);
    }

    function countdown() {
        var s = svc.nextInSec;
        if (s < 0) return "—";
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
        if (h > 0) return h + "h " + m + "m";
        if (m > 0) return m + "m";
        return s + "s";
    }

    Process {
        id: fetchProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    var payload = JSON.parse(text);
                    if (payload && payload.times && typeof payload.times === "object") {
                        svc.timings = payload.times;
                        svc.gregDate = String(payload.date || "");
                        svc.hijriDate = String(payload.hijri || "");
                        svc.stale = payload.stale === true;
                        svc.error = "";
                        svc.fetchDate = svc.todayKey();
                        svc.recompute();
                    } else if (payload && payload.error) {
                        if (Object.keys(svc.timings).length === 0)
                            svc.error = String(payload.error);
                    }
                } catch (e) {
                    // Keep last good timings on a garbled response.
                }
            }
        }
        onExited: function(exitCode) {
            if (exitCode !== 0 && Object.keys(svc.timings).length === 0)
                svc.error = "could not load prayer times";
        }
    }

    Timer {
        interval: 20000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: svc.recompute()
    }

    Component.onCompleted: svc.refresh()
}
