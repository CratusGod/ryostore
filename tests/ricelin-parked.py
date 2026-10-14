#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
source = (root / "barstyles/ricelin/MinimizedTray.qml").read_text()
predicate = next(line for line in source.splitlines() if "isParked" in line)
test = '''import QtQuick
import QtTest
TestCase {
    id: root
    name: "RicelinParked"
    PREDICATE
    function test_workspaces() {
        compare(root.isParked("special:minimized"), true)
        compare(root.isParked("special:scratchpad"), true)
        compare(root.isParked("1"), false)
        compare(root.isParked("work"), false)
        compare(root.isParked(""), false)
        compare(root.isParked(null), false)
    }
}
'''.replace("PREDICATE", predicate)

with tempfile.TemporaryDirectory(prefix="ricelin-parked-") as directory:
    Path(directory, "tst_parked.qml").write_text(test)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen")
    raise SystemExit(subprocess.call(["qmltestrunner", "-input", directory], env=env))
