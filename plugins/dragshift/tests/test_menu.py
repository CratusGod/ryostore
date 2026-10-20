"""service/menu.js (run in node) must offer exactly what the engine can do."""
from __future__ import annotations

import json
import shutil
import subprocess

import pytest

from conftest import PLUGIN, eng

pytestmark = pytest.mark.skipif(shutil.which("node") is None, reason="node not installed")


def js(expr: str):
    src = (PLUGIN / "service" / "menu.js").read_text().replace(".pragma library", "")
    p = subprocess.run(["node", "-e", f"{src}\nconsole.log(JSON.stringify({expr}))"],
                       capture_output=True, text=True, timeout=30)
    assert p.returncode == 0, p.stderr
    return json.loads(p.stdout)


EXTS = sorted(eng.util.IMAGE_EXTS | eng.util.PDF_EXTS | eng.util.DOCX_EXTS | eng.util.TEXT_EXTS)


@pytest.mark.parametrize("ext", EXTS)
def test_category_and_targets_match_the_engine(ext):
    name = f"/x/file{ext}"
    cat = eng.util.category(name)
    assert js(f"category({json.dumps(name)})") == cat
    want = eng.convert.targets_for(cat, ext)
    assert js(f"targetsFor({json.dumps(cat)}, {json.dumps(ext.lstrip('.'))}, true)") == want


def test_unsupported_and_extensionless():
    assert js('category("/a/song.mp3")') == "" and js('category("/a/Makefile")') == ""
    assert js('category("/a/.png")') == ""  # a dotfile, not a PNG
    assert js('build(["/a/song.mp3"], true).rings') == []


def test_heic_hidden_without_heif():
    assert "HEIC" not in js('targetsFor("image", "png", false)')


def test_every_ring_item_is_something_the_engine_accepts():
    for paths in (["/a/p.png"], ["/a/p.png", "/a/q.jpg"], ["/a/d.pdf"], ["/a/d.pdf", "/a/e.pdf"],
                  ["/a/w.docx"], ["/a/t.md"]):
        b = js(f"build({json.dumps(paths)}, true)")
        cat = b["category"]
        for ring in b["rings"]:
            for it in ring["items"]:
                if it["kind"] == "convert":
                    assert it["id"] in eng.convert.targets_for(cat, "." + paths[0].rsplit(".", 1)[1])
                elif it["kind"] == "tool":
                    assert it["id"] == "merge" or it["id"] in eng.tools_for(cat), it
                else:
                    assert it["id"] in eng.editors_for(cat), it


def test_rings_follow_dragshift_order():
    img = js('build(["/a/p.png"], true)')
    assert [r["name"] for r in img["rings"]] == ["Convert", "Tools"]
    assert [i["label"] for i in img["rings"][1]["items"]] == \
        ["Compress", "Resize", "Crop", "Edit", "Annotate", "Redact", "Add BG", "Metadata"]
    pdfs = js('build(["/a/d.pdf", "/a/e.pdf"], true)')
    assert [i["label"] for i in pdfs["rings"][1]["items"]] == \
        ["Compress", "Split", "Rotate", "Merge", "Protect", "Extract", "Metadata"]
    assert [r["name"] for r in js('build(["/a/w.docx"], true)')["rings"]] == ["Convert"]


def test_mixed_drop_keeps_the_first_supported_kind():
    b = js('build(["/a/x.mp3", "/a/p.png", "/a/d.pdf", "/a/q.jpg"], true)')
    assert b["category"] == "image" and b["files"] == ["/a/p.png", "/a/q.jpg"]
    pdf_hint = next(i for i in b["rings"][0]["items"] if i["id"] == "PDF")["hint"]
    assert pdf_hint == "2 images → 1 PDF"


@pytest.mark.parametrize("n", [0, 5, 1023, 1024, 1536, 10 * 1024 ** 2, 3 * 1024 ** 3])
def test_human_size_matches_upstream(n):
    assert js(f"humanSize({n})") == eng.util.human_size(n)
