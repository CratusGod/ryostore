# Authoring a Super+Esc sidebar

A sidebar is the Controls panel Super+Esc opens. Ryoku ships its own design;
this catalogue holds the ones the community builds. A user installs yours from
**RyoStore -> Sidebars**, picks it in **Settings -> Overlays**, and Super+Esc
opens it. Installing never switches anyone's design by itself, and removing the
one in use puts the user back on Ryoku's own design.

Start from [`template/`](template/): it is a complete, working sidebar in one
small file.

## The folder

```
sidebars/<id>/
  Sidebar.qml           the panel (required)
  *.qml, lib/*.js       anything else it needs, all inside this folder
  README.md             what it is and how to use it
  LICENSE               a licence you can honour
  PROVENANCE.txt        where it comes from (optional)
  assets/preview.webp   a real screenshot of the open panel (store art, not installed)
  manifest.json         written by tools/pack-product.py, never by hand
```

`<id>` is lowercase letters, digits and dashes. `ryoku` is reserved for the
design Ryoku ships.

The whole folder installs as one piece and runs from its own copy, so a relative
import may reach files inside the folder and nothing outside it. The security
screen blocks a relative import that leaves the folder.

## The contract

Ryoku's sidebar host loads `Sidebar.qml` once per output. The root is an `Item`,
or a `FocusScope` if it handles keys. The host sets:

| Property | What the host sets |
| --- | --- |
| `required property var screen` | the output this copy belongs on |
| `property real us` | this output's UI scale |
| `property bool active` | true while open and false during the exit animation |
| `property real availableWidth` | room inside the bar's rails on this output, after the gap |
| `property real availableHeight` | room inside the bar's rails on this output, after the gap |

The panel is modal and may cover a dock. These values do not reserve space for
dock rails.

Your design may define these members for the host to read:

| Member | What it means |
| --- | --- |
| `property string placement` | `"top-left"` (the default), `"top-right"`, `"left"`, `"right"` or `"center"` |
| `implicitWidth`, `implicitHeight` | the wanted panel size; the host clamps it to the available room, and `left` or `right` uses the full available height |
| `signal closeRequested()` | emit it when your close control or an action should close the panel |

The shell keeps the rest:

| The host keeps | What that means for a design |
| --- | --- |
| The click-away and panel windows | never create a window or layer surface |
| Focus and Escape | the host takes exclusive focus while open and closes on Escape |
| Open and close motion | the host owns opacity, scale and slide; `active` lets content stop work during the exit |
| Per-output state | use `SidebarState` rather than keeping a second tab or visibility model |
| Super+Esc routing | the surface id stays `sidebar-left` whichever design is worn |
| Failure recovery | a sidebar that does not load is replaced by Ryoku's own panel |

## Tabs, sections and the sidebar kit

Import the stock controls with:

```qml
import shell.modules.sidebar as Kit
```

`SidebarState.activeTab(screen)` is `"controls"`, `"wifi"`, `"bluetooth"` or
`"plugins"`. Change it with `SidebarState.selectTab(screen, tab)`, and close
with your `closeRequested()` signal or `SidebarState.close(screen)`.
`SidebarState.visibleSections` is the Controls order. Its items have one of
these ids: `vitals`, `connections`, `powerProfile`, `media`, `levels` and
`bottomControls`. `SidebarState.elementVisible(id)` holds the smaller choices.
Respect both so the choices in Ryoku Hub -> Controls stay true in your design.

The kit includes `Kit.ControlsHero`, `Kit.ControlsConnections`,
`Kit.PowerProfileControl`, `Kit.ControlsMedia`, `Kit.ControlsLevels`,
`Kit.ControlsBar`, `Kit.ControlsBoard`, `Kit.ExtensionsBoard`,
`Kit.SidebarPlugins`, `Kit.SidebarFrame`, `Kit.CornerButton` and the rest of the
stock sidebar module. The control blocks take `s` (pass your `us`), `screen` and
`active` where the type declares them. `Kit.ControlsBoard` already hosts the
Controls, Wi-Fi and Bluetooth pages; set its `page` from
`SidebarState.activeTab(screen)`. The template shows both direct block
composition and that detail-page route.

`Kit.ControlsConnections.openPage(page)` should select that tab. A
`Kit.ControlsBar` session action should emit `closeRequested()` and then call
`SessionActions.run(action)`. Its extension action selects the `plugins` tab.
Do not spawn session commands yourself.

## What you may import

- `QtQuick`, `QtQuick.Layouts`, `QtQuick.Controls`, `QtQuick.Shapes`,
  `QtQuick.Effects`, `QtQml`
- `Qt5Compat.GraphicalEffects`
- `Quickshell`, `Quickshell.Widgets`, `Quickshell.Bluetooth`
- `Quickshell.Services.Mpris`, `Quickshell.Services.Pipewire`
- `Ryoku.Blobs`
- `shell.services`: `SidebarState`, `SessionActions`, `Theme`, `Icons` and the
  shell's other services
- `shell.modules.sidebar`, normally imported as `Kit`
- `Ryoku.Ui.Singletons`: `Tokens`, `Motion`, `I18n`

Use `Tokens` or `Theme` for colour, type, spacing and durations, and multiply
surface geometry by `us`. The panel follows the user's colour scheme, interface
scale and reduced-motion setting that way. It never creates windows or reads a
compositor directly.

## Traps that blank a sidebar

- Never name a property after an `Item` anchor line (`left`, `right`, `top`,
  `bottom`, `horizontalCenter`, `verticalCenter`, `baseline`). QML refuses it
  with "Cannot override FINAL property" and the whole design fails to load.
- Inside a `Repeater` delegate, `section: section` or `foo: foo` binds the
  delegate's property to itself. Use `modelData` or give the outer id another
  name.
- A singleton of your own needs a `qmldir` beside it naming it.
- When `Sidebar.qml` fails to load, Ryoku draws its own sidebar instead. The
  reason is in `~/.local/state/ryoku/surfaces/shell.log`.

## The registry entry

Add one entry to `sidebars/registry.json` with the fields every catalogue uses:
`id`, `name`, `version`, `path`, `author`, `upstream`, `summary`, `description`,
`tags`, `accent`, `surface`, `preview`, `screenshots`, `manifest`
(`"manifest.json"`), `manifestSha256`, `lastUpdated`, `official: false`, and
`license`. An optional `discord` invite offers author contact. Then:

```sh
python3 tools/pack-product.py sidebars/<id>
```

writes `manifest.json` and its hash in the registry. Run it again after every
change, and bump `version` in the registry first: installed copies are offered
an update only when the version moves.

## Test it live

1. Point the store at your checkout (see [`../DEVELOP.md`](../DEVELOP.md)):
   `echo "file://$HOME/Work/ryostore" > ~/.config/ryoku/ryostore-base`.
2. Install it: RyoStore -> Sidebars, or `ryostore install sidebars <id>`.
3. Settings -> Overlays: pick it. Press Super+Esc, then open Wi-Fi, Bluetooth,
   panel settings and every enabled session action.
4. After a change, bump the version, repack and install the update. The shell
   swaps the new copy in without a restart.

## Checklist

- [ ] Super+Esc opens and closes it on the output you are on; Escape and click-away still work.
- [ ] Every placement fits inside the bar's rails after the gap at each UI scale.
- [ ] Controls order and visibility follow Ryoku Hub -> Controls.
- [ ] Wi-Fi and Bluetooth open, change state and return to Controls.
- [ ] Volume, brightness, session and panel controls work once per click.
- [ ] Disabled or absent hardware leaves an honest, usable control.
- [ ] Two outputs keep independent tabs and open state.
- [ ] It follows a colour scheme change and reduced motion.
- [ ] A deliberately broken copy falls back to Ryoku's sidebar and logs the reason.
- [ ] `tests/validate-catalogue.sh` and `python3 tools/security-screen.py --root .` pass.
