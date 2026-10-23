# Ryoku for Zed

This bundle writes a custom theme to `~/.config/zed/themes/ryoku-dynamic.json` and selects it in Zed. Matugen already renders Ryoku's `matugen.json` for Zed on every palette change; the bundle adds a `post_hook` to that template so the custom theme is rebuilt right after, on every Ryoku edition. The generator source is included in this bundle for review; installation does not fetch or execute remote source code.

## Install

Install the bundle from Ryostore Extras. Node.js 22.18 or newer is required; the bundle installs it. The installer synchronizes the current palette, keeps a backup of Zed's settings file, selects **Ryoku Dynamic Dark**, and adds the hook to the `[templates.zed]` section of `~/.config/ryoku/user_edits/matugen/apps.toml`, Ryoku's overlay for your Matugen changes. The hook reads `~/.config/zed/themes/matugen.json` and writes only `ryoku-dynamic.json`.

In Ryoku, enable **Theme apps** from the wallpaper picker (`Super+W` → **App theming**) so Matugen produces the Zed theme. Select **Ryoku Dynamic Dark** or **Ryoku Dynamic Light** in Zed's theme selector to follow the current appearance. The installed theme is dynamic; the bundled `runtime/themes/ryoku.json` is a static fallback palette.

The top-level `installers/ryoku-zed-theme.sh` is a compatibility copy for
Ryostore clients that resolve a script item through the catalogue root instead
of the bundle-local path, like Spiceflow's. Both copies must stay identical.

If Zed is open while its theme JSON changes, reopen the theme selector and reselect the Ryoku Dynamic theme. If the running session still displays old colors, restart Zed; the hook updates the JSON on disk but cannot force an in-process theme reload. This avoids claiming that file synchronization alone repaints an already-running editor.

## Palette behavior

UI surfaces follow the generated Ryoku palette. Syntax colors are distributed across distinct warm and cool hues so common adjacent categories remain distinguishable. When the source palette is nearly grey, the generator seeds syntax accents from Ryoku violet and applies a chroma floor. It adjusts text lightness to keep at least 4.5:1 contrast against the editor background.

The screenshots show the real Zed editor displaying the bundled theme generator over violet, red, and blue Ryoku palettes. The code shown is the theme generator itself. Source can be reviewed in `runtime/scripts/theme.ts` and `runtime/scripts/install-sync.ts`. From the installed runtime directory, run `node scripts/theme.ts --verify-monochrome` to check synthetic monochrome light and dark palettes.

To stop following the palette, delete the `post_hook` line from `[templates.zed]` in `~/.config/ryoku/user_edits/matugen/apps.toml`, then run:

```sh
ryoku materialize
```
