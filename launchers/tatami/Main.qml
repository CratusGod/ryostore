import QtQuick
import Quickshell
import shell.services
import Ryoku.Ui.Singletons
import "lib/shelf.js" as Shelf

// Tatami spreads the whole app shelf at once: a full-screen grid of mats under a
// section index, the way a printed catalogue lays out its plates. It is a Ryoku
// launcher: the shell's launcher host drives it through show(), hide() and
// shown, and it starts apps through the shell's own AppLaunch, so terminal apps
// and the desktop's environment behave as they do everywhere else.
Scope {
    id: root

    property bool openRequested: false
    // stays true through the close, so the sheet can sink away before it unmaps
    readonly property bool shown: root.openRequested || closing.running
    property string monitor: ""
    property string query: ""
    property string section: "all"
    property int selected: 0

    readonly property var shelf: Shelf.collect(DesktopEntries.applications.values)
    readonly property var sections: Shelf.sections(root.shelf)
    readonly property var results: Shelf.filter(root.shelf, root.section, root.query)

    // The output the host named, else the focused one, else the first.
    readonly property var output: {
        const screens = Quickshell.screens;
        const wanted = root.monitor.length > 0 ? root.monitor : Wm.focusedOutput;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === wanted)
                return screens[i];
        return screens.length > 0 ? screens[0] : null;
    }

    function show(mon) {
        closing.stop();
        root.monitor = mon || "";
        root.query = "";
        root.section = "all";
        root.selected = 0;
        root.openRequested = true;
    }
    function hide() {
        if (!root.openRequested)
            return;
        root.openRequested = false;
        closing.restart();
    }
    function toggle(mon) {
        root.openRequested ? root.hide() : root.show(mon);
    }
    function stateDump() {
        return {
            open: root.openRequested,
            query: root.query,
            section: root.section,
            selectedIndex: root.selected,
            resultCount: root.results.length
        };
    }

    function setQuery(text) {
        root.query = text;
        root.selected = 0;
    }
    function pickSection(id) {
        root.section = id;
        root.selected = 0;
    }
    function cycleSection(by) {
        const ids = root.sections.map(entry => entry.id);
        const at = Math.max(0, ids.indexOf(root.section));
        root.pickSection(ids[(at + by + ids.length) % ids.length]);
    }
    function move(by) {
        if (root.results.length > 0)
            root.selected = Math.max(0, Math.min(root.results.length - 1, root.selected + by));
    }
    function launch(item) {
        if (!item)
            return;
        root.hide();
        AppLaunch.run(item.entry, null);
    }

    Timer {
        id: closing
        interval: Tokens.dur(200)
    }

    LazyLoader {
        active: root.shown && root.output !== null
        Sheet {
            tatami: root
            screen: root.output
        }
    }
}
