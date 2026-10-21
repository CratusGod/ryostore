# Authoring an on-screen display

An on-screen display is the small volume, microphone, brightness or keyboard
pop-up Ryoku draws over the desktop. Ryoku ships its own design; this catalogue
holds the ones the community builds. A user installs yours from **RyoStore ->
On-screen displays**, picks it in **Settings -> Overlays**, and sees it on the
next change. Installing never switches anyone's design by itself, and removing
the one in use puts the user back on Ryoku's own design.

Start from [`template/`](template/): it is a complete, working design in one
small file.

## The folder

```
osds/<id>/
  Osd.qml               the design (required)
  *.qml, lib/*.js       anything else it needs, all inside this folder
  README.md             what it is and how to use it
  LICENSE               a licence you can honour
  PROVENANCE.txt        where it comes from (optional)
  assets/preview.webp   a real screenshot of the pop-up (store art, not installed)
  manifest.json         written by tools/pack-product.py, never by hand
```

`<id>` is lowercase letters, digits and dashes. `ryoku` is reserved for the
design Ryoku ships.

The whole folder installs as one piece and runs from its own copy, so a relative
import may reach files inside the folder and nothing outside it. The security
screen blocks a relative import that leaves the folder.

## The contract

Ryoku's OSD host loads `Osd.qml` once per output and kind. The root is an `Item`.
The host keeps the instance warm and updates these properties live:

| Property | What the host sets |
| --- | --- |
| `required property string kind` | `"volume"`, `"mic"`, `"brightness"` or `"keyboard"` |
| `required property var screen` | the output this copy belongs on |
| `property real us` | this output's UI scale; 1 is the base logical size |
| `property bool shown` | true during the change flash and its hold |
| `property real value` | 0 through `maxValue` for volume, mic and brightness; 0 for keyboard |
| `property real maxValue` | 1, or 1.5 when volume boost is on |
| `property bool muted` | whether the volume or microphone is muted |
| `property string icon` | the symbolic glyph name |
| `property url iconSource` | the file URL of that glyph's SVG; tint this image rather than replacing it with text |
| `property string label` | the keyboard layout name, or the percentage for the other kinds |

Your design may define these members for the host to read:

| Member | What it means |
| --- | --- |
| `property string placement` | `"bottom"` (the default), `"top"`, `"left"`, `"right"` or `"center"`; it may depend on `kind` |
| `property real reveal` | your own 0 through 1 entrance progress; the host stays mapped while `shown || reveal > 0.01`, which lets an exit finish |
| `implicitWidth`, `implicitHeight` | the wanted window size, in logical pixels multiplied by `us` |

The shell keeps the rest:

| The host keeps | What that means for a design |
| --- | --- |
| The window | never create a window or layer surface |
| Placement and edge gap | the host uses `placement` and keeps a 24 px times `us` gap from that edge |
| Input and focus | the window is click-through and never takes keyboard focus |
| Timing and live data | draw the values you receive; do not read audio, brightness, keyboard or output state yourself |
| Ownership gates | a bar style that owns feedback can hide every OSD design |
| Failure recovery | a design that does not load is replaced by Ryoku's own design |

The supplied glyph SVGs are black. Tint `iconSource` with `ColorOverlay` from
`Qt5Compat.GraphicalEffects`, or use `MultiEffect` from `QtQuick.Effects` with
`brightness: 1` as well as colorization. Colorization alone leaves black pixels
black. For keyboard, use `label` as the layout name and do not invent a progress
value.

## What you may import

- `QtQuick`, `QtQuick.Layouts`, `QtQuick.Shapes`, `QtQuick.Effects`, `QtQml`
- `Qt5Compat.GraphicalEffects`
- `Quickshell`, `Quickshell.Widgets`
- `shell.services`: `Theme`, `Icons` and the shell's other services
- `Ryoku.Ui.Singletons`: `Tokens`, `Motion`, `I18n`

Use `Tokens` or `Theme` for colour, type, spacing and durations, and multiply
surface geometry by `us`. The design follows the user's colour scheme, interface
scale and reduced-motion setting that way. It never creates windows, reads
devices or starts processes.

## Traps that blank an OSD

- Never name a property after an `Item` anchor line (`left`, `right`, `top`,
  `bottom`, `horizontalCenter`, `verticalCenter`, `baseline`). QML refuses it
  with "Cannot override FINAL property" and the whole design fails to load.
- Inside a `Repeater` delegate, `foo: foo` binds the delegate's property to
  itself. Give the outer id another name.
- A singleton of your own needs a `qmldir` beside it naming it.
- When `Osd.qml` fails to load, Ryoku draws its own OSD instead. The reason is in
  `~/.local/state/ryoku/surfaces/shell.log`.

## The registry entry

Add one entry to `osds/registry.json` with the fields every catalogue uses:
`id`, `name`, `version`, `path`, `author`, `upstream`, `summary`, `description`,
`tags`, `accent`, `surface`, `preview`, `screenshots`, `manifest`
(`"manifest.json"`), `manifestSha256`, `lastUpdated`, `official: false`, and
`license`. An optional `discord` invite offers author contact. Then:

```sh
python3 tools/pack-product.py osds/<id>
```

writes `manifest.json` and its hash in the registry. Run it again after every
change, and bump `version` in the registry first: installed copies are offered
an update only when the version moves.

## Test it live

1. Point the store at your checkout (see [`../DEVELOP.md`](../DEVELOP.md)):
   `echo "file://$HOME/Work/ryostore" > ~/.config/ryoku/ryostore-base`.
2. Install it: RyoStore -> On-screen displays, or `ryostore install osds <id>`.
3. Settings -> Overlays: pick it. Use the Try button or run
   `qs -c shell ipc call osd preview`.
4. After a change, bump the version, repack and install the update. The shell
   swaps the new copy in without a restart.

## Checklist

- [ ] Volume, microphone and brightness show the right icon, value, label and muted state.
- [ ] Keyboard shows the layout name without a false progress value.
- [ ] Every placement stays on screen on two differently scaled outputs.
- [ ] The entrance and exit finish, including with reduced motion enabled.
- [ ] It follows a colour scheme change.
- [ ] A deliberately broken copy falls back to Ryoku's design and logs the reason.
- [ ] `tests/validate-catalogue.sh` and `python3 tools/security-screen.py --root .` pass.
