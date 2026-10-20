# Launcher template

The smallest working Ryoku launcher: a search line over the apps that match,
arrow keys to choose, Enter to open, Escape to close. Copy this folder to start
your own.

1. Copy `launchers/template/` to `launchers/<your-id>/` (lowercase letters,
   digits and dashes; not one of the launchers Ryoku ships: `main`, `hero`,
   `okshell`, `kairos`, `spotlight`, `python`).
2. Build your launcher in `Main.qml`, keep `Preview.qml` showing it, and add
   `assets/preview.webp`: a real screenshot of it open.
3. Add a `LICENSE` you can honour and replace this README with one about your
   launcher.
4. Add your entry to `launchers/registry.json`, then run
   `python3 tools/pack-product.py launchers/<your-id>`.

The whole contract, what a launcher may import, how to test it live and the
checklist are in [`../AUTHORING.md`](../AUTHORING.md).
