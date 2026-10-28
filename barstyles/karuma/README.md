# Karuma — Ryoku bar style

Karuma is a configurable paper-and-ink bar style for Ryoku. It includes a horizontal bar and adaptive side rail, movable built-in and Ryoku plugin modules, live media/tray/status surfaces, quick settings, profiles, and a configuration hub.

## Runtime behavior

- Runs as a native Ryoku bar style through `Scene.qml`; it uses Ryoku's own UI/singletons and plugin host rather than targeting a specific window manager.
- Reads the Ryoku shell configuration, the current desktop/theme tokens, connected display/workspace/window/media/system state, and installed Ryoku plugin metadata.
- Writes its bar-style settings and user-selected profiles to the Karuma/Ryoku configuration and state locations.
- Can invoke system utilities for supported controls such as networking, Bluetooth, brightness, screen recording, and keep-awake. Those actions depend on the corresponding system utility/device being available.
- Opens the project's linked GitHub pages from its settings UI. It contains no updater or separate network client.

## RyoStore packaging

`manifest.json` lists the complete product payload and hashes. The matching catalogue row is in `../../registry-entry.json`; merge it into `barstyles/registry.json` after finalizing the author, licence and real screenshot.

**Publication TODO:** the source archive did not include a screenshot of Karuma running or a licence declaration for the bar code. Do not publish the draft until both have been supplied. The bundled fonts retain their own OFL licence texts in `assets/fonts/`.

## Credits

Karuma's source comments describe its paper-and-ink layout as inspired by the original Ma layout. See the source and bundled font licence files for the relevant component context.
