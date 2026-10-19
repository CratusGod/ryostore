# Authoring an app launcher

A launcher is what Super+Space opens. Ryoku ships six of its own; this
catalogue holds the ones the community builds. A user installs yours from
**RyoStore -> App launchers**, picks it in **Settings -> App Launcher**, saves,
and from then on Super+Space opens it. Installing never switches anyone's
launcher by itself, and removing the one in use puts the user back on Ryoku's
default.

Start from [`template/`](template/): it is a complete, working launcher in one
small file.

## The folder

```
launchers/<id>/
  Main.qml              the launcher (required)
  Preview.qml           the still Settings shows beside the style list (recommended)
  *.qml, lib/*.js       anything else it needs, all inside this folder
  README.md             what it is and how to use it
  LICENSE               a licence you can honour
  PROVENANCE.txt        where it comes from (optional)
  assets/preview.webp   a real screenshot of it open (store art, not installed)
  manifest.json         written by tools/pack-product.py, never by hand
```

`<id>` is lowercase letters, digits and dashes. It cannot be the id of a launcher
Ryoku ships: `main`, `hero`, `okshell`, `kairos`, `spotlight`, `python`.

The whole folder installs as one piece and runs from its own copy, so a relative
import may reach files inside the folder and nothing outside it. The security
screen blocks a relative import that leaves the folder.

## The contract

Ryoku's launcher host loads your `Main.qml` the same way it loads its own
launchers. The root object (a `Scope` is the usual choice) provides:

| Member | What the host expects |
| --- | --- |
| `readonly property bool shown` | true while anything of yours is on screen, close animation included |
| `function show(monitor)` | open on the output with that name; an empty name means the focused one (`Wm.focusedOutput`) |
| `function hide()` | start closing; `shown` turns false when you are gone |
| `function toggle(monitor)` | optional: `show` or `hide` |
| `function stateDump()` | optional: a small object describing your state, for tests |

The host opens one copy of your launcher per output and passes that output's
name to `show`. It learns that you closed from `shown` turning false, so close
yourself on Escape, on a click outside your surface, and after you launch an app.

Build your windows only while you are shown (`LazyLoader { active: root.shown }`),
on the `Overlay` layer with `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive`
and the namespace `"launcher"`. Then nothing of yours costs memory or frames while
the launcher is closed.

## Starting apps

List apps from `DesktopEntries.applications` (Quickshell) and start them with
`AppLaunch.run(entry, action)` from `shell.services`; pass `null` as the action to
start the app itself. Do not call `entry.execute()` or spawn the command
yourself: `AppLaunch` opens terminal apps in the user's chosen terminal and keeps
the desktop's crash handler out of the app's environment.

## What you may import

- `QtQuick`, `QtQuick.Layouts`, `QtQuick.Controls`, `QtQml`
- `Quickshell`, `Quickshell.Wayland`, `Quickshell.Widgets`, `Quickshell.Io`
- `shell.services`: `AppLaunch`, `Icons` (`Icons.path(name, fallback)` gives an
  app icon as a file URL), `Theme`, `ShellState` and the rest of the shell's
  services
- `Ryoku.Ui` and `Ryoku.Ui.Singletons`: `Tokens` (colour, type, spacing,
  motion), `I18n`, `Wm`, `Spawn`

Use `Tokens` for colour, type, spacing and durations (`Tokens.dur(ms)`), so your
launcher follows the user's colour scheme, interface scale and reduced-motion
setting. No window manager in the code: the same launcher runs on Hyprland and
niri (see [`../CONTRIBUTING.md`](../CONTRIBUTING.md)).

## The Settings preview

`Preview.qml` is a still picture of your launcher that Settings shows above the
style list. It is an `Item` with `implicitWidth: 720` and `implicitHeight: 250`,
a `property var settings` and a `signal editRequested(string key, var value)`.
It runs inside Settings, not the shell, so it may import only `QtQuick` and the
`Ryoku.Ui` modules, and it must not start anything. Without one, Settings shows
your store art instead.

## Traps that blank a launcher

- Never name a property after an `Item` anchor line (`left`, `right`, `top`,
  `bottom`, `horizontalCenter`, `verticalCenter`, `baseline`). QML refuses it
  with "Cannot override FINAL property" and the whole launcher fails to load.
- A singleton of your own needs a `qmldir` beside it naming it.
- When `Main.qml` fails to load, Ryoku falls back to its OkShell launcher for that
  open. The reason is in `~/.local/state/ryoku/surfaces/shell.log`.

## The registry entry

Add one entry to `launchers/registry.json` with the fields every catalogue uses:
`id`, `name`, `version`, `path`, `author`, `upstream`, `summary`, `description`,
`tags`, `accent`, `surface`, `preview`, `screenshots`, `manifest`
(`"manifest.json"`), `manifestSha256`, `lastUpdated`, `official: false`, and
`license`. An optional `discord` invite offers author contact. Then:

```sh
python3 tools/pack-product.py launchers/<id>
```

writes `manifest.json` and its hash in the registry. Run it again after every
change, and bump `version` in the registry first: installed copies are offered
an update only when the version moves.

## Test it live

1. Point the store at your checkout (see [`../DEVELOP.md`](../DEVELOP.md)):
   `echo "file://$HOME/Work/ryostore" > ~/.config/ryoku/ryostore-base`.
2. Install it: RyoStore -> App launchers, or `ryostore install launchers <id>`.
3. Settings -> App Launcher: pick it and save. Press Super+Space.
4. After a change, repack and install again. The shell swaps the new copy in
   without a restart.

## Checklist

- [ ] Super+Space opens it on the output you are on, and again on another output.
- [ ] Typing filters, arrow keys or the pointer choose, Enter or a click opens
      the app, and the launcher closes after launching.
- [ ] Escape and a click outside close it; `shown` turns false.
- [ ] A terminal app (btop, nvim) opens in the terminal.
- [ ] It follows a colour scheme change and reduced motion.
- [ ] `Preview.qml` shows it in Settings -> App Launcher.
- [ ] `tests/validate-catalogue.sh` and `python3 tools/security-screen.py --root .`
      pass.
