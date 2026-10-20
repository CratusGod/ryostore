# Dock template

The smallest working Ryoku dock: your pinned apps, then the running ones, on the
screen edge chosen in Edit desktop -> Dock. Click to open or switch, middle-click
for a new window, right-click for the dock menu. It hides with automatic hiding
on and draws itself inside the Stage Editor. Copy this folder to start your own.

1. Copy `docks/template/` to `docks/<your-id>/` (lowercase letters, digits and
   dashes; not one of the docks Ryoku ships: `ryoku`, `python`, `shima`, `ii`,
   `none`).
2. Build your dock in `Dock.qml` and add `assets/preview.webp`: a real
   screenshot of it on a desktop.
3. Add a `LICENSE` you can honour and replace this README with one about your
   dock.
4. Add your entry to `docks/registry.json`, then run
   `python3 tools/pack-product.py docks/<your-id>`.

The whole contract, what a dock may import, how to test it live and the
checklist are in [`../AUTHORING.md`](../AUTHORING.md).
