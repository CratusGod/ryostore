# Sidebar template

The smallest working Ryoku sidebar design: a top-right framed panel with the
stock Connections, Levels and Bottom Controls blocks, plus the stock Wi-Fi,
Bluetooth and Extensions pages. Copy this folder to start your own.

1. Copy `sidebars/template/` to `sidebars/<your-id>/` (lowercase letters, digits
   and dashes; `ryoku` is reserved).
2. Build your design in `Sidebar.qml` and add `assets/preview.webp`: a real
   screenshot of the open panel.
3. Add a `LICENSE` you can honour and replace this README with one about your
   design.
4. Add your entry to `sidebars/registry.json`, then run
   `python3 tools/pack-product.py sidebars/<your-id>`.

The whole contract, sidebar kit, allowed imports, live test steps and checklist
are in [`../AUTHORING.md`](../AUTHORING.md).
