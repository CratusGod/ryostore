# Gokko Spotlight — App Launcher

The former Spotlight search from Gokko, packaged as a first-class **Ryoku app launcher**. It keeps Gokko's Liquid Glass UI, application search, clipboard history and emoji picker while letting Ryoku manage it like any other launcher.

## Launcher contract

`Main.qml` exposes `show(monitor)`, `hide()`, `toggle(monitor)`, `shown` and `stateDump()`, matching the launcher interface used by Ryoku. The actual search surface and glass renderer reuse Gokko's `upstream/MacBar.qml` implementation in standalone mode.

## Install and select

Install from **RyoStore → App launchers**, or run:

```sh
ryostore install launchers gokko-spotlight
```

Then select **Gokko Spotlight** in **Ryoku Settings → App Launcher**. The Gokko menu-bar magnifier runs `ryoku-shell launcher`, so it opens the launcher currently selected in Ryoku (including this one).

## Configuration

This launcher intentionally has no separate settings screen or launcher-specific settings file. It reads the same `~/.config/macbar/settings.json` as Gokko and watches for changes saved through Gokko's existing settings UI. Appearance, accent colour, font, blur, Liquid Glass strength, clipboard history and related options remain managed from Gokko.

The launcher never writes to that shared settings file, avoiding a stale copy overwriting Gokko's configuration. Its compiled shader cache is stored separately at `~/.config/macbar/gokko-spotlight-liquidglass.frag.qsb` so it can run alongside the Gokko bar without racing the bar's shader cache.

## Dependencies

- Ryoku Desktop Shell (Quickshell-based), with the `ryoku-shell` command
- The shell services and Barkit QML modules provided by Ryoku
- Hyprland or niri for the compositor-specific Liquid Glass backdrop path
- Optional tools: `wl-clipboard`/`cliphist` for clipboard history; the other Gokko tools are optional and degrade when unavailable

## License and attribution

MIT. Gokko adapts the MIT-licensed MacShell project by Rickky (0-ss) and contributors. See `LICENSE`, `NOTICE.md` and `PROVENANCE.txt`. Bundled fonts and assets may have their own terms.

## 1.0.1

Carries the capture retry backoff and the app-menu label binding fix from Gokko
0.3.4. See `barstyles/gokko/README.md`.
