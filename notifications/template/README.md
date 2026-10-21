# Notification template

The smallest working Ryoku notification card: app name, summary, body, optional
image, action buttons and a close button. Actions invoke once and then dismiss
the card. Copy this folder to start your own.

1. Copy `notifications/template/` to `notifications/<your-id>/` (lowercase
   letters, digits and dashes; `ryoku` is reserved).
2. Build your design in `Card.qml` and add `assets/preview.webp`: a real
   screenshot of the card.
3. Add a `LICENSE` you can honour and replace this README with one about your
   design.
4. Add your entry to `notifications/registry.json`, then run
   `python3 tools/pack-product.py notifications/<your-id>`.

The whole contract, allowed imports, live test steps and checklist are in
[`../AUTHORING.md`](../AUTHORING.md).
