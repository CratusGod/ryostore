#!/usr/bin/env python3
"""dragshift_engine - the bridge between the Ryoku bar panel and the DragShift engine.

Runs inside the engine's own venv (bin/dragshift execs it with `python -I`), imports
the pinned DragShift checkout from $DRAGSHIFT_ENGINE, and answers every call with
exactly one JSON object on stdout: {"ok": true, ...} and exit 0, or
{"ok": false, "error": "...", ["fix": "..."]} and exit 1. The QML never parses
anything else and never builds a shell string to call us (R9).

Commands (paths must be absolute):
    [--output next|folder] doctor
    [--output next|folder] actions FILE...
    [--output next|folder] convert --to TARGET FILE...
    [--output next|folder] tool TOOL FILE...
    [--output next|folder] editor [--dry] EDITOR FILE...
    trash PATH...
    reveal PATH

It writes only new files beside the originals (or in a "DragShift" subfolder
beside them, with --output folder). Originals are never modified.
"""
from __future__ import annotations

import importlib
import importlib.util
import json
import os
import signal
import subprocess
import sys
import traceback
from pathlib import Path

PLUGIN_DIR = Path(__file__).resolve().parent.parent
PIN_FILE = PLUGIN_DIR / "engine" / "PIN"
DEFAULT_ENGINE = "~/.local/share/dragshift/engine"
MAX_FILES = 500

# Filled by load_engine(): the DragShift modules this bridge drives.
convert = imaging = util = report = None
_loaded_from: Path | None = None


class Refusal(Exception):
    """A request we turn down with a message that is fine to show as-is."""


# ---------------------------------------------------------------- engine loading
def engine_dir() -> Path:
    return Path(os.environ.get("DRAGSHIFT_ENGINE") or DEFAULT_ENGINE).expanduser().resolve()


def load_engine(path: Path) -> None:
    """Import the headless DragShift modules from the checkout at `path`."""
    global convert, imaging, util, report, _loaded_from
    if _loaded_from == path:
        return
    if not (path / "dragshift" / "__init__.py").is_file():
        raise Refusal(f"No DragShift checkout at {path}")
    sys.path.insert(0, str(path))
    convert = importlib.import_module("dragshift.convert")
    imaging = importlib.import_module("dragshift.imaging")
    util = importlib.import_module("dragshift.util")
    report = importlib.import_module("dragshift.report")
    _loaded_from = path


def read_pin() -> str:
    try:
        return PIN_FILE.read_text().strip()
    except OSError:
        return ""


def git_head(path: Path) -> str:
    try:
        r = subprocess.run(["git", "-C", str(path), "rev-parse", "HEAD"],
                           capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return ""
    return r.stdout.strip() if r.returncode == 0 else ""


def git_dirty(path: Path) -> bool:
    try:
        r = subprocess.run(["git", "-C", str(path), "status", "--porcelain", "--untracked-files=no"],
                           capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return False
    return r.returncode == 0 and bool(r.stdout.strip())


def doctor(path: Path, pin: str | None = None) -> dict:
    """Is the engine present, importable and at the commit this plugin was tested with?"""
    pin = read_pin() if pin is None else pin
    r = {"ok": False, "engine": str(path), "pin": pin, "python": sys.executable,
         "sha": "", "pinned": False, "heif": False, "editors": False}
    try:
        load_engine(path)
    except Exception as e:  # noqa: BLE001 - any import failure is a doctor finding
        r["error"] = f"DragShift engine not usable: {e}"
        r["fix"] = f"{PLUGIN_DIR / 'engine' / 'setup.sh'} {path}"
        return r
    r["sha"] = git_head(path)
    r["dirty"] = git_dirty(path)
    r["pinned"] = bool(pin) and r["sha"] == pin
    r["heif"] = bool(getattr(convert, "HEIF_OK", False))
    r["editors"] = importlib.util.find_spec("PySide6") is not None
    if not r["pinned"]:
        r["error"] = f"Engine is at {r['sha'][:12] or 'an unknown commit'}, plugin is tested with {pin[:12]}"
        r["fix"] = f"git -C {path} checkout --detach {pin}"
        return r
    if r["dirty"]:
        r["error"] = "The engine checkout has local edits to tracked files"
        r["fix"] = f"git -C {path} status   (then restore or stash the edits)"
        return r
    r["ok"] = True
    return r


# ---------------------------------------------------------------- menus
FORMAT_HINTS = {"JPG": "Small, universal", "PNG": "Lossless · transparency", "WEBP": "Smallest for web",
                "HEIC": "iPhone format", "TIFF": "Print · archival", "AVIF": "Next-gen, tiny",
                "BMP": "Uncompressed", "PDF": "Document", "ICO": "Windows icon", "GIF": "Legacy web",
                "DOCX": "Editable Word", "TXT": "Plain text"}

# id -> (label, action name upstream's report understands, function(path) -> list[Path])
IMAGE_TOOLS = {
    "compress": ("Compress", "Compress", lambda p: [imaging.compress_image(p)]),
    "compress-500kb": ("Under 500 KB", "Compress", lambda p: [_compress_under(p, 500 * 1024)]),
    "half": ("Half size", "Resize", lambda p: [_resize(p, "pct", 50)]),
    "long-1920": ("1920 px", "Resize", lambda p: [_resize(p, "long", 1920)]),
    "long-1280": ("1280 px", "Resize", lambda p: [_resize(p, "long", 1280)]),
    "strip-location": ("Remove location", "Metadata", lambda p: [imaging.strip_location(p)]),
    "strip-all": ("Remove all metadata", "Metadata", lambda p: [imaging.strip_image_metadata(p)]),
}
PDF_TOOLS = {
    "compress": ("Compress", "Compress", lambda p: [imaging.compress_pdf(p)]),
    "split": ("Split pages", "Split", lambda p: imaging.split_pdf(p)),
    "rotate": ("Rotate 90°", "Rotate", lambda p: [imaging.rotate_pdf(p)]),
    "extract": ("Extract images", "Extract", lambda p: imaging.extract_pdf_images(p)),
    "strip-all": ("Remove metadata", "Metadata", lambda p: [imaging.strip_pdf_metadata(p)]),
}
# id -> (label, tools.py class, takes a list of paths, extra kwargs) - mirrors app.run_item
IMAGE_EDITORS = {
    "crop": ("Crop", "CropWindow", False), "edit": ("Edit", "EditWindow", False),
    "annotate": ("Annotate", "AnnotateWindow", False), "redact": ("Redact", "RedactWindow", False),
    "add-bg": ("Add BG", "AddBgWindow", False), "compress-custom": ("Compress…", "CompressWindow", True),
    "resize-custom": ("Resize…", "ResizeWindow", True), "metadata": ("Metadata", "MetadataWindow", False),
}
PDF_EDITORS = {
    "protect": ("Protect", "ProtectWindow", False),
    "metadata": ("Metadata", "MetadataWindow", False, {"is_pdf": True}),
}


def _compress_under(p, max_bytes: int) -> Path:
    im = convert.open_image(p)
    target = imaging.lossy_target(p)
    quality, side = imaging.plan_target_size(im, target, max_bytes)
    return imaging.compress_to(p, quality, side, target)


def _resize(p, mode: str, value: int) -> Path:
    with convert.open_image(p) as im:
        dims = imaging.resize_dims(im.size, mode, value)
    return imaging.resize_image(p, dims)


def tools_for(cat: str) -> dict:
    return {"image": IMAGE_TOOLS, "pdf": PDF_TOOLS}.get(cat, {})


def editors_for(cat: str) -> dict:
    return {"image": IMAGE_EDITORS, "pdf": PDF_EDITORS}.get(cat, {})


# ---------------------------------------------------------------- input checks
def check_files(args: list[str]) -> tuple[list[Path], list[Path]]:
    """(regular files, dropped items that aren't one: folders, vanished files)."""
    if not args:
        raise Refusal("No files given")
    if len(args) > MAX_FILES:
        raise Refusal(f"Too many files ({len(args)}); the limit is {MAX_FILES}")
    files, skipped = [], []
    for a in args:
        p = Path(a)
        if not p.is_absolute():
            raise Refusal(f"Not an absolute path: {a}")
        (files if p.is_file() else skipped).append(p)
    if not files:
        raise Refusal("No usable files: " + ", ".join(p.name or str(p) for p in skipped[:3]))
    return files, skipped


def same_kind(checked: tuple[list[Path], list[Path]]) -> tuple[str, list[Path], list[Path]]:
    """The first supported file decides the kind; everything else is skipped, never fatal."""
    files, skipped = checked
    cat = next((c for c in map(util.category, files) if c), None)
    if cat is None:
        raise Refusal(f"{files[0].suffix or 'This file type'} isn't supported")
    keep = [f for f in files if util.category(f) == cat]
    return cat, keep, skipped + [f for f in files if f not in keep]


def summary(action: str, srcs: list[Path], outs: list[Path]) -> dict:
    res = report.summarize(action, srcs, outs)
    return {"ok": True, "outs": [str(o) for o in res.outs], "title": res.title,
            "detail": res.detail, "good": res.good}


# ---------------------------------------------------------------- commands
def cmd_actions(args: list[str]) -> dict:
    cat, files, skipped = same_kind(check_files(args))
    conv = []
    for t in convert.targets_for(cat, files[0].suffix):
        hint = FORMAT_HINTS.get(t, "")
        if cat == "image" and t == "PDF" and len(files) > 1:
            hint = f"{len(files)} images → 1 PDF"
        conv.append({"id": t, "label": t, "hint": hint})
    tools = [{"id": k, "label": v[0]} for k, v in tools_for(cat).items()]
    if cat == "pdf" and len(files) > 1:
        tools.insert(0, {"id": "merge", "label": f"Merge {len(files)}"})
    many = len(files) > 1
    editors = [{"id": k, "label": v[0] + (" (first file)" if many and not v[2] else "")}
               for k, v in editors_for(cat).items()]
    return {"ok": True, "category": cat, "files": [str(f) for f in files],
            "skipped": [str(f) for f in skipped], "convert": conv, "tools": tools, "editors": editors}


def cmd_convert(args: list[str]) -> dict:
    if len(args) < 2 or args[0] != "--to":
        raise Refusal("usage: convert --to TARGET FILE...")
    target = args[1].upper()
    cat, files, _ = same_kind(check_files(args[2:]))
    if target not in convert.targets_for(cat, files[0].suffix):
        raise Refusal(f"Can't convert {cat} to {target}")
    if cat == "image" and target == "PDF" and len(files) > 1:
        outs = convert.images_to_single_pdf(files)
    else:
        outs = [o for f in files for o in convert.convert(f, cat, target)]
    return summary(f"convert:{target}", files, outs)


def cmd_tool(args: list[str]) -> dict:
    if not args:
        raise Refusal("usage: tool TOOL FILE...")
    name, rest = args[0], args[1:]
    cat, files, _ = same_kind(check_files(rest))
    if cat == "pdf" and name == "merge":
        if len(files) < 2:
            raise Refusal("Merge needs at least two PDFs")
        return summary("tool:Merge", files, [imaging.merge_pdfs(files)])
    spec = tools_for(cat).get(name)
    if spec is None:
        raise Refusal(f"'{name}' isn't a {cat} tool")
    _, action, fn = spec
    outs = [o for f in files for o in fn(f)]
    return summary(f"tool:{action}", files, outs)


def _gio_trash(path: str) -> bool:
    try:
        return subprocess.run(["gio", "trash", "--", path], capture_output=True, timeout=15).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def cmd_trash(args: list[str]) -> dict:
    """Undo: move these outputs to the Trash. Partial success is reported as failure."""
    if not args:
        raise Refusal("usage: trash PATH...")
    paths = [Path(a) for a in args]
    if not all(p.is_absolute() for p in paths):
        raise Refusal("trash takes absolute paths only")
    n = sum(1 for p in paths if p.is_file() and _gio_trash(str(p)))
    # extract_pdf_images always makes a fresh "<name> images" folder (unique_path),
    # so an emptied one is ours. A "DragShift" output folder may predate us: kept.
    for d in {p.parent for p in paths}:
        if d.name.endswith(" images") and d.is_dir() and not any(d.iterdir()):
            _gio_trash(str(d))
    if n < len(paths):
        raise Refusal(f"Couldn't move {len(paths) - n} of {len(paths)} to the Trash "
                      "(already gone, or gio trash failed)")
    return {"ok": True, "trashed": n}


def _spawn(cmd: list[str]) -> bool:
    try:
        return subprocess.run(cmd, capture_output=True, timeout=10).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def cmd_reveal(args: list[str]) -> dict:
    """Select the file in the file manager (FileManager1, which Dolphin implements),
    else open its folder. as_uri() percent-encodes commas and quotes, so the
    dbus-send array argument cannot be split or broken by the file name."""
    if len(args) != 1 or not Path(args[0]).is_absolute() or not Path(args[0]).exists():
        raise Refusal("usage: reveal ABSOLUTE_PATH")
    p = Path(args[0])
    if _spawn(["dbus-send", "--session", "--print-reply", "--dest=org.freedesktop.FileManager1",
               "/org/freedesktop/FileManager1", "org.freedesktop.FileManager1.ShowItems",
               f"array:string:{p.as_uri()}", "string:"]):
        return {"ok": True, "how": "filemanager"}
    if _spawn(["xdg-open", str(p.parent)]):
        return {"ok": True, "how": "folder"}
    raise Refusal("No file manager answered")


def cmd_editor(args: list[str]) -> dict:
    dry = bool(args) and args[0] == "--dry"
    args = args[1:] if dry else args
    if not args:
        raise Refusal("usage: editor [--dry] EDITOR FILE...")
    name = args[0]
    cat, files, _ = same_kind(check_files(args[1:]))
    spec = editors_for(cat).get(name)
    if spec is None:
        raise Refusal(f"'{name}' isn't a {cat} editor")
    sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves our own dir off sys.path
    import dragshift_editor  # Qt is imported only on this path
    return dragshift_editor.open_editor(sys.modules[__name__], spec, files, dry=dry)


COMMANDS = {"actions": cmd_actions, "convert": cmd_convert, "tool": cmd_tool,
            "trash": cmd_trash, "reveal": cmd_reveal, "editor": cmd_editor}


def run(argv: list[str], env: dict | None = None) -> dict:
    """Run one command and return its JSON-able answer. Never raises."""
    saved = {k: os.environ.get(k) for k in (env or {})}
    try:
        os.environ.update(env or {})
        args = list(argv)
        output = "next"
        if args[:1] == ["--output"]:
            if len(args) < 2 or args[1] not in ("next", "folder"):
                raise Refusal("--output must be 'next' or 'folder'")
            output, args = args[1], args[2:]
        if not args:
            raise Refusal("No command given")
        cmd, rest = args[0], args[1:]
        if cmd == "doctor":
            return doctor(engine_dir())
        if cmd not in COMMANDS:
            raise Refusal(f"Unknown command '{cmd}'")
        load_engine(engine_dir())
        util.CONFIG["output"] = output
        return COMMANDS[cmd](rest)
    except Refusal as e:
        return {"ok": False, "error": str(e)}
    except Exception as e:  # noqa: BLE001 - every failure must still answer in JSON
        if util is not None and isinstance(e, util.UserError):
            return {"ok": False, "error": str(e)}
        traceback.print_exc(file=sys.stderr)
        return {"ok": False, "error": f"{type(e).__name__}: {e}"}
    finally:
        for k, v in saved.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v


def _terminate(signum, frame):
    """Cancel from the panel sends SIGTERM: unwind, so upstream's atomic_save
    `finally` blocks delete their hidden .part files instead of leaving them."""
    raise SystemExit(143)


def main(argv: list[str] | None = None) -> int:
    signal.signal(signal.SIGTERM, _terminate)
    r = run(sys.argv[1:] if argv is None else argv)
    print(json.dumps(r, ensure_ascii=False), flush=True)
    return 0 if r.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
