# On-screen display template

The smallest working Ryoku OSD design: a tinted shell icon, the supplied label
and a progress bar for volume, microphone and brightness. It enters from the
bottom and follows the user's theme. Copy this folder to start your own.

1. Copy `osds/template/` to `osds/<your-id>/` (lowercase letters, digits and
   dashes; `ryoku` is reserved).
2. Build your design in `Osd.qml` and add `assets/preview.webp`: a real
   screenshot of the pop-up.
3. Add a `LICENSE` you can honour and replace this README with one about your
   design.
4. Add your entry to `osds/registry.json`, then run
   `python3 tools/pack-product.py osds/<your-id>`.

The whole contract, allowed imports, live test steps and checklist are in
[`../AUTHORING.md`](../AUTHORING.md).
