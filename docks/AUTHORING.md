# Authoring a dock

A dock is the strip of app icons on a screen edge, the same on every bar style.
Ryoku ships its own designs; this catalogue holds the ones the community builds.
A user installs yours from **RyoStore -> Docks**, picks it in **Edit desktop ->
Dock**, and from then on it is the dock on every monitor. Installing never
switches anyone's dock by itself, and removing the one in use puts the user back
on Ryoku's own design.

Start from [`template/`](template/): it is a complete, working dock in one file.

## The folder

```
docks/<id>/
  Dock.qml              the dock (required)
  *.qml, lib/*.js       anything else it needs, all inside this folder
  README.md             what it is and how to use it
  LICENSE               a licence you can honour
  PROVENANCE.txt        where it comes from (optional)
  assets/preview.webp   a real screenshot of it on a desktop (store art, not installed)
  manifest.json         written by tools/pack-product.py, never by hand
```

`<id>` is lowercase letters, digits and dashes. It cannot be the id of a design
Ryoku ships: `ryoku`, `python`, `shima`, `ii`, `none`.

The whole folder installs as one piece and runs from its own copy, so a relative
import may reach files inside the folder and nothing outside it. The security
screen blocks a relative import that leaves the folder.

## The contract

The shell's dock host loads your `Dock.qml` once per monitor, the way it loads
its own designs. The root object holds your dock's windows (the template uses
an `Item` with no size; a `Scope` works too) and declares:

| Member | What the host does with it |
| --- | --- |
| `required property var screen` | the monitor this copy of the dock belongs on; give it to your `PanelWindow` |
| `property bool surfaceVisible` | false while the shell hides docks; hide your windows |
| `property bool stageEditing` | true while the Stage Editor shows this monitor (see below) |

The host only loads a dock while the dock is switched on, so you do not check
that yourself.

## The dock model

Everything a dock shows and does comes from `Dock` in `shell.services`. Use it,
and pins, running windows and the right-click menu stay the same whichever dock
the user wears.

| What | How |
| --- | --- |
| The apps to show | `Dock.resolve(Dock.pinnedOrStarter())`: pinned apps in order, then the ones only running, as app ids |
| Is it pinned | `Dock.pinnedOrStarter().includes(id)` |
| Its icon and name | `Dock.iconFor(id)` (a file URL, "" when unknown); `Dock.entryFor(id)?.name` |
| Open windows | `Dock.countFor(id)`; the app you are in is `Dock.activeClass`; `Dock.anyFocused` is false on a bare desktop |
| Click | `Dock.activate(id)`: opens the app, or focuses it, or cycles its windows |
| Middle-click | `AppLaunch.run(DesktopEntries.heuristicLookup(id), null)`: a new window |
| Right-click | `Dock.openMenu(id, pinned, count, x, y, screen.name, edge, depth)`: Ryoku's dock menu (Open or New window, Pin or Unpin, Close). `x` and `y` are the icon's centre in global coordinates (`mapToGlobal`); `depth` is how far your dock reaches from the edge, so the menu clears it |

The settings every dock shares live in Edit desktop -> Dock, and your dock
follows them:

| Setting | Read it with |
| --- | --- |
| Screen edge | `Dock.resolvedEdge()`: "top", "bottom", "left" or "right" |
| Icon size | `Dock.cfg("size", 44)` |
| Hide automatically | `Dock.cfg("autohide", true)`: hide while a window has focus, come back when the pointer reaches the edge |
| Magnify on hover | `Dock.cfg("magnify", true)` |

## Windows, layers and the Stage Editor

- Use a `PanelWindow` from `Quickshell` anchored to the edge, on the
  `WlrLayer.Top` layer so it shows above windows, with `exclusiveZone` set to
  its depth while it does not hide automatically (0 while it does). Mask its
  input to what you draw, so the rest of the strip stays click-through, and
  stand aside while a window on that monitor is full screen
  (`Wm.outputHasFullscreen(screen.name)`), unless the pointer is on the dock.
- **The Stage Editor** shrinks the desktop into a card and draws the dock in it,
  live and clickable. While `stageEditing` is true: stay revealed, move to
  `WlrLayer.Overlay`, and draw inside the card by putting your content in a
  `StageFramedLayer` (`import shell.modules.stage.frame`): bind the window's size
  across the edge to the layer's `extent` and map every input-mask rect through
  its `maskRect`. Tell the editor which edge you hold, so its desktop icons keep
  clear of you, with `GlobalStates.setDockInset(screen.name, stageEditing ? edge
  : "", depth)` (`import stage`), and clear it with `setDockInset(screen.name,
  "", 0)` when your dock goes away. The template does all of this.

## What you may import

- `QtQuick`, `QtQuick.Layouts`, `QtQuick.Controls`, `QtQuick.Shapes`, `QtQml`
- `Quickshell`, `Quickshell.Wayland`, `Quickshell.Widgets`
- `shell.services`: `Dock`, `AppLaunch`, `Icons`, `Theme` and the shell's other
  services
- `shell.modules.stage.frame` (`StageFramedLayer`) and `stage` (`GlobalStates`)
- `Ryoku.Ui.Singletons`: `Tokens` (colour, type, spacing, motion), `Wm`, `I18n`

Use `Tokens` for colour, type and durations (`Tokens.snap`, `Tokens.move`,
`Tokens.dur(ms)`), so your dock follows the user's colour scheme and goes still
with reduced motion. No window manager in the code: the same dock runs on
Hyprland and niri (see [`../CONTRIBUTING.md`](../CONTRIBUTING.md)).

## Traps that blank a dock

- Never name a property after an `Item` anchor line (`left`, `right`, `top`,
  `bottom`, `horizontalCenter`, `verticalCenter`, `baseline`). QML refuses it
  with "Cannot override FINAL property" and the whole dock fails to load.
- Inside a `Repeater` delegate, a property with the same name as an id outside
  it hides that id (`plank: plank` binds the property to itself). Give the
  outer id another name.
- When `Dock.qml` fails to load, Ryoku draws its own dock instead and logs
  `dock: the store dock <id> did not load` in
  `~/.local/state/ryoku/surfaces/shell.log`, after the error that caused it.

## The registry entry

Add one entry to `docks/registry.json` with the fields every catalogue uses:
`id`, `name`, `version`, `path`, `author`, `upstream`, `summary`,
`description`, `tags`, `accent`, `surface`, `preview`, `screenshots`,
`manifest` (`"manifest.json"`), `manifestSha256`, `lastUpdated`,
`official: false`, and `license`. An optional `discord` invite offers author
contact. Then:

```sh
python3 tools/pack-product.py docks/<id>
```

writes `manifest.json` and its hash in the registry. Run it again after every
change, and bump `version` in the registry first: installed copies are offered
an update only when the version moves.

## Test it live

1. Point the store at your checkout (see [`../DEVELOP.md`](../DEVELOP.md)):
   `echo "file://$HOME/Work/ryostore" > ~/.config/ryoku/ryostore-base`.
2. Install it: RyoStore -> Docks, or `ryostore install docks <id>`.
3. Right-click the desktop, Edit desktop -> Dock -> Dock design & settings, and
   pick it. It swaps in at once, inside the editor's card.
4. After a change, bump the version, repack and press Update on its card. The
   shell swaps the new copy in without a restart.

## Checklist

- [ ] Pinned apps, then running ones; the counts follow windows opening and
      closing; the app you are in stands out.
- [ ] Click opens or switches, middle-click opens a new window, right-click
      opens the dock menu and its Pin, Unpin and Close work.
- [ ] All four screen edges, every icon size from 28 to 72, and with
      automatic hiding on: it hides while a window has focus and comes back
      at the edge.
- [ ] It stands aside for a full-screen window.
- [ ] In Edit desktop -> Dock it sits inside the card and stays clickable;
      after Done it returns to its edge and windows do not jump.
- [ ] Two monitors: a dock on each.
- [ ] It follows a colour scheme change and reduced motion.
- [ ] `tests/validate-catalogue.sh` and `python3 tools/security-screen.py --root .`
      pass.
