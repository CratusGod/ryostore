#!/usr/bin/env python3
"""Build a product manifest and refresh its registry hash.

Usage:
    tools/pack-product.py <category>/<id> [--touch]
    e.g. tools/pack-product.py plugins/vpn --touch

Plugins and Ryotunes skins ship a per-file manifest (schema 1, with
``destination`` and a ``files`` array) that this tool reproduces. Plugins use
``product-manifest.json``; skins use ``manifest.json``. Bar styles, launchers,
docks, OSDs, notifications and sidebars ship ``manifest.json`` the same way
(destination ``ryoku/<category>/<id>``). Bar styles and the shell-loaded QML
folder products install README/LICENSE beside their QML, while plugins and skins
hold documentation back. Every other category installs differently and has no
such manifest to reproduce, so generalising further would be guesswork.

The manifest is derived to match the convention already in the tree, verified by
repacking the existing plugins, skins and bar styles byte for byte:

- ``destination``: ``ryoku/<category>/<id>``.
- ``files``: every regular file under the product folder except the manifest
  itself (and any ``.git`` metadata), one row per file, sorted by source path
  (POSIX, codepoint order). Each row's ``destination`` mirrors its ``source``.
- ``mode``: ``0755`` for files that are executable on disk and start with a
  shebang, otherwise ``0644`` (exactly what the validator accepts).
- top level: ``license`` is copied from the registry entry when it names one.
- ``install``: ``false`` for the registry entry's ``preview`` and
  ``screenshots``, and for documentation (README/LICENSE/COPYING/NOTICE/AUTHORS
  and ``docs/`` trees, per the validator's ``is_documentation``) except in a
  category listed in ``DOCS_SHIPPED_CATEGORIES``; ``true`` otherwise.

It then rewrites the registry entry's ``manifestSha256`` to the new manifest's
hash and, with ``--touch``, sets ``lastUpdated`` to today. Registry key order and
the 2-space, UTF-8, newline-terminated JSON layout are preserved byte for byte
where nothing changed. Classification reuses the validator in tests/ so the tool
and the validator can never drift apart.
"""
from __future__ import annotations

import argparse
import datetime
import importlib.util
import json
from pathlib import Path, PurePosixPath
import sys


REPO_ROOT = Path(__file__).resolve().parent.parent
SUPPORTED_CATEGORIES = (
    "plugins", "barstyles", "launchers", "docks", "osds", "notifications",
    "sidebars", "ryotunes-skins",
)

# Categories whose products install their documentation alongside their payload.
# These products are folders of QML that install whole, so their README and
# LICENSE land next to them; plugins and skins hold documentation back.
DOCS_SHIPPED_CATEGORIES = {
    "barstyles", "launchers", "docks", "osds", "notifications", "sidebars",
}

# The file-row field order each category already ships. It is per category
# because a regenerated row must be byte-identical to the row it replaces.
# Tool-authored products put digest before mode; the hand-authored bar styles
# put mode and size first. Emitting the other order would rewrite every row of
# a manifest whose content did not change.
ROW_ORDER = {
    "plugins": ("source", "destination", "sha256", "mode", "size", "install"),
    "ryotunes-skins": ("source", "destination", "sha256", "mode", "size", "install"),
    "launchers": ("source", "destination", "sha256", "mode", "size", "install"),
    "docks": ("source", "destination", "sha256", "mode", "size", "install"),
    "osds": ("source", "destination", "sha256", "mode", "size", "install"),
    "notifications": ("source", "destination", "sha256", "mode", "size", "install"),
    "sidebars": ("source", "destination", "sha256", "mode", "size", "install"),
    "barstyles": ("source", "destination", "mode", "size", "sha256", "install"),
}


def _load_validator():
    path = REPO_ROOT / "tests" / "validate-store.py"
    spec = importlib.util.spec_from_file_location("validate_store", path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validate_store = _load_validator()


def _read_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, value: object) -> None:
    text = json.dumps(value, indent=2, ensure_ascii=False) + "\n"
    path.write_text(text, encoding="utf-8")


def _iter_sources(product: Path, manifest_name: str):
    for path in product.rglob("*"):
        relative = path.relative_to(product).as_posix()
        parts = PurePosixPath(relative).parts
        if relative == manifest_name or ".git" in parts:
            continue
        if path.is_symlink():
            raise ValueError(f"symlink forbidden: {relative}")
        if path.is_file():
            if "__pycache__" in parts or path.suffix in {".pyc", ".pyo"}:
                raise ValueError(f"remove generated Python bytecode before packing: {relative}")
            yield relative, path


def _file_mode(path: Path) -> str:
    executable = bool(path.stat().st_mode & 0o111)
    if executable and validate_store.starts_with_shebang(path):
        return "0755"
    return "0644"


def build_manifest(product: Path, entry: dict, category: str) -> dict:
    manifest_name = str(entry.get("manifest", "product-manifest.json"))
    uninstalled = {entry.get("preview")}
    screenshots = entry.get("screenshots")
    if isinstance(screenshots, list):
        uninstalled.update(screenshots)

    ships_docs = category in DOCS_SHIPPED_CATEGORIES
    order = ROW_ORDER[category]
    rows = []
    for relative, path in _iter_sources(product, manifest_name):
        install = not (
            relative in uninstalled
            or (validate_store.is_documentation(relative) and not ships_docs)
        )
        fields = {
            "source": relative,
            "destination": relative,
            "sha256": validate_store.sha256(path),
            "mode": _file_mode(path),
            "size": path.stat().st_size,
            "install": install,
        }
        rows.append({name: fields[name] for name in order})
    rows.sort(key=lambda row: row["source"])
    manifest = {
        "schema": 1,
        "id": entry.get("id"),
        "category": category,
        "version": entry.get("version"),
        "destination": f"ryoku/{category}/{entry.get('id')}",
        "files": rows,
    }
    # A registry entry may name a licence; the manifest mirrors it after the rows.
    if entry.get("license"):
        manifest["license"] = entry["license"]
    return manifest


def pack_product(root: Path, category: str, product_id: str, touch: bool = False) -> dict:
    if category not in SUPPORTED_CATEGORIES:
        raise ValueError(
            f"unsupported category {category!r}: only "
            f"{', '.join(map(repr, SUPPORTED_CATEGORIES))} carry a product manifest"
        )
    registry_path = root / category / "registry.json"
    registry = _read_json(registry_path)
    entries = registry.get(category) if isinstance(registry, dict) else None
    if not isinstance(entries, list):
        raise ValueError(f"{category}/registry.json: {category} array missing")
    entry = next((e for e in entries if isinstance(e, dict) and e.get("id") == product_id), None)
    if entry is None:
        raise ValueError(f"{category}/{product_id}: no registry entry")

    product = root / category / product_id
    if not product.is_dir():
        raise ValueError(f"{category}/{product_id}: product folder missing")

    manifest_name = str(entry.get("manifest", "product-manifest.json"))
    manifest = build_manifest(product, entry, category)
    manifest_path = product / manifest_name
    _write_json(manifest_path, manifest)

    entry["manifestSha256"] = validate_store.sha256(manifest_path)
    if touch:
        entry["lastUpdated"] = datetime.date.today().isoformat()
    _write_json(registry_path, registry)
    return manifest


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Build a product manifest and refresh its registry hash",
    )
    parser.add_argument("product", help="<category>/<id>, e.g. plugins/vpn or ryotunes-skins/nord-light")
    parser.add_argument(
        "--touch",
        action="store_true",
        help="also set the registry entry's lastUpdated to today",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=REPO_ROOT,
        help="catalogue root (default: repository root)",
    )
    args = parser.parse_args(argv)

    slug = args.product.strip("/")
    if slug.count("/") != 1:
        parser.error("product must be <category>/<id>")
    category, product_id = slug.split("/", 1)

    try:
        manifest = pack_product(args.root.resolve(), category, product_id, args.touch)
    except (ValueError, OSError) as error:
        print(f"pack-product: {error}", file=sys.stderr)
        return 1

    print(f"{category}/{product_id}: wrote manifest ({len(manifest['files'])} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
