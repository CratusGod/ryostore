# Tansu — App Launcher

The **Tansu** launcher, built for **Ryoku Desktop Shell**. It is a
phone-shaped home screen: an app grid and a search box that also answers to a
calculator, the clipboard history, a colour picker, an emoji picker, a web search
and a set of system actions — and the wallpaper board it turns into. Colours
follow Ryoku's Matugen palette, so it wears the same theme as the rest of the
shell.

## Features

- **Apps** — every installed application, from Quickshell's own DesktopEntries
  index, as tiles with a fuzzy search across names and comments.
- **The search cards** — calculator (`Calc.js`), clipboard history, colour picker
  (`hyprpicker`), emoji picker, and a browser-style web search.
- **System actions** — lock, sleep, hibernate, restart, shut down, log out,
  reboot to firmware, night light, Wi-Fi and Bluetooth toggles, mute, screenshot,
  colour pick, clipboard wipe — run through Ryoku's own backends where one exists.
- **Wallpapers** — the board reached from the search ("Wallpapers") or with
  Ctrl+3, backed by `ryogami` (Desktop and Lockscreen sides).
- **Native backends** — session actions from `Ryoku.SessionActions`, Wi-Fi from
  `Ryoku.Network`, Bluetooth from `Quickshell.Bluetooth`, night light from
  `Ryoku.Nightlight`, wallpapers from `ryogami`, and the Matugen palette from the
  shell's theme.

## The launcher contract

`Main.qml` is the entry point the shell hosts as a launcher variant. It exposes
the shell's launcher seam — `show(monitor)`, `hide()`, `toggle(monitor)`,
`shown`, and `stateDump()` — and hands the work to
`modules/tansu/launcher/LauncherSurface.qml`, which owns the phone window and its
geometry.

## Installing

Install it from **RyoStore → App launchers**, or with
`ryostore install launchers tansu`, then pick **Tansu** in
**Settings → App Launcher** and save. Installing never switches the launcher in
use by itself; Super+Space opens whichever one is picked there.

## Dependencies

- **Ryoku Desktop Shell** (Quickshell-based)
- **Hyprland** or **niri** compositor
- **`ryogami`** (for the wallpaper board)

Card extras degrade quietly: a missing tool (`cliphist`, `hyprpicker`,
`grim`/`slurp`) just leaves its card saying so.

## Structure

```
tansu/
├── Main.qml               # Entry point (the shell's launcher variant)
├── manifest.json          # Ryostore product manifest
├── modules/
│   ├── common/            # Shared theme, widgets and helpers
│   └── tansu/
│       ├── launcher/      # The launcher phone, the app grid and the cards
│       ├── phone/         # The phone body and keys
│       └── wallpaperSelector/  # The wallpaper board
├── services/              # Adapters over Ryoku's services
├── scripts/state/         # The emoji "recent" helper
├── assets/icons/          # The Solar icons it draws (outline + bold)
└── assets/preview.webp
```

## Settings

Its own options (the phone's peek, the 24-hour clock, the LCD wallpaper, the
clipboard watcher, the web suggestions) are read from
`~/.config/ryoku/launcher-tansu.json`. Everything Ryoku owns (displays, the
compositor, keybinds, network, the system theme, the wallpaper daemon) is not a
setting here.

## Compositor support

The surface dismisses on click-outside: `HyprlandFocusGrab` on Hyprland, and a
full-screen scrim surface on compositors without that protocol (niri). Escape
closes it everywhere.

## License

GPL-3.0-only — see `PROVENANCE.txt` for attribution.

## Maintenance & support

Tansu is a community contribution. It is maintained and updated by its author
( dodo986 ), not by the Ryoku team. Ryostore runs automated and human screening
on every submission, but that screening is not a guarantee of correctness or
safety: you are responsible for reviewing the code you install and run. Report
issues and request updates through the contributor.
