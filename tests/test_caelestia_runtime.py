"""Exercise Caelestia ripple layout and dashboard lifecycle in real Quickshell."""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs") and os.environ.get("WAYLAND_DISPLAY"),
                     "requires Quickshell and a Wayland session")
class CaelestiaRuntimeTests(unittest.TestCase):
    def test_dashboard_can_open_switch_tabs_and_reopen_without_binding_loop(self):
        with tempfile.TemporaryDirectory(prefix=".dashboard-", dir=ROOT / "tests") as temp:
            config = Path(temp) / "shell.qml"
            source = str(ROOT / "barstyles/caelestia")
            config.write_text('''import QtQuick
import Quickshell
import "file:SOURCE/components" as C
import "file:SOURCE/modules/dashboard" as D
Scope {
    id: test
    property var originalPane: null
    function check(condition, message) {
        if (!condition) { console.error("TEST_FAILURE", message); Qt.quit(); }
    }
    function firstPane() {
        const pending = [dashboard];
        while (pending.length) {
            const item = pending.pop();
            if (item.sourceComponent !== undefined
                && item.sourceComponent === dashboard.dashboardTabs[0].component)
                return item;
            for (const child of item.children ?? []) pending.push(child);
        }
        return null;
    }
    C.DrawerVisibilities { id: vis; dashboard: true }
    C.ScreenState { id: state; modelData: Quickshell.screens[0] }
    D.Content { id: dashboard; visibilities: vis; screenState: state; facePicker: null }
    Timer {
        running: true; interval: 200
        onTriggered: {
            check(firstPane()?.item != null, "initial tab did not load");
            originalPane = firstPane().item;
            state.dashboardTab = dashboard.dashboardTabs.length - 1;
        }
    }
    Timer {
        running: true; interval: 400
        onTriggered: {
            check(originalPane != null && firstPane().item === originalPane,
                  "switching tabs discarded the loaded tab");
            vis.dashboard = false;
        }
    }
    Timer {
        running: true; interval: 600
        onTriggered: {
            check(firstPane().item === null, "closing did not unload the tab");
            vis.dashboard = true;
            state.dashboardTab = 0;
        }
    }
    Timer {
        running: true; interval: 1000
        onTriggered: {
            check(firstPane().item != null && firstPane().item !== originalPane,
                  "reopening did not create a new tab");
            console.log("DASHBOARD_TEST complete"); Qt.quit();
        }
    }
}
'''.replace("SOURCE", source))
            env = os.environ.copy()
            env["QML_IMPORT_PATH"] = str(Path.home() / ".config/quickshell")
            env["QT_QPA_PLATFORM"] = "wayland"
            result = subprocess.run(
                ["qs", "-p", str(config), "--no-color"], check=False, env=env,
                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20,
            )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("DASHBOARD_TEST complete", result.stdout)
        self.assertNotIn("TEST_FAILURE", result.stdout)
        self.assertNotIn("ERROR:", result.stdout)
        self.assertNotIn('Binding loop detected for property "active"', result.stdout)

    def test_zero_size_and_resize_never_produce_invalid_color_alpha(self):
        with tempfile.TemporaryDirectory(prefix=".ripple-", dir=ROOT / "tests") as temp:
            config = Path(temp) / "shell.qml"
            config.write_text('''import QtQuick
import Quickshell
import "file:SOURCE_COMPONENTS" as C
Scope {
    Item {
        id: container
        width: 0
        height: 0
        C.StateLayer { id: ripple }
    }
    Timer {
        running: true; interval: 100
        onTriggered: {
            console.log("RIPPLE_TEST zero-size", ripple.endRadius);
            ripple.press(0, 0);
            container.width = 100;
            container.height = 40;
        }
    }
    Timer {
        running: true; interval: 300
        onTriggered: {
            console.log("RIPPLE_TEST resized", ripple.endRadius);
            ripple.press(50, 20);
            container.width = 0;
            container.height = 0;
        }
    }
    Timer {
        running: true; interval: 600
        onTriggered: { console.log("RIPPLE_TEST complete"); Qt.quit(); }
    }
}
'''.replace('SOURCE_COMPONENTS', str(ROOT / 'barstyles/caelestia/components')))
            env = os.environ.copy()
            imports = str(Path.home() / ".config/quickshell")
            env["QML_IMPORT_PATH"] = imports + os.pathsep + env.get("QML_IMPORT_PATH", "")
            env["QT_QPA_PLATFORM"] = "wayland"
            result = subprocess.run(
                ["qs", "-p", str(config), "--no-color"], check=False, env=env,
                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20,
            )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("RIPPLE_TEST complete", result.stdout)
        self.assertIn("RIPPLE_TEST zero-size 0", result.stdout)
        self.assertNotIn("ERROR:", result.stdout)
        self.assertNotIn("invalid value nan", result.stdout)


if __name__ == "__main__":
    unittest.main()
