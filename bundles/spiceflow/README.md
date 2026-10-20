# Ryoku Palette Bridge

Ryoku Palette Bridge keeps Zen, Spotify, and Discord matched to your wallpaper.
Change the wallpaper and all three apps pick up its Ryoku colours automatically.

It works with the themes each app already supports:

- Zen's browser theme changes colour through Firefox's theme API.
- Spotify's Spicetify theme gets the same colours without stopping your music.
- Discord uses the Midnight theme in Vesktop, with its colours updated through
  QuickCSS so the stock Discord theme never flashes on screen.

This bundle is stored under `bundles/spiceflow` because the project started as
Spiceflow, a Spotify-only tool. The current project and its name in Ryostore are
Ryoku Palette Bridge because it now handles all three apps.

Ryoku ships the bridge itself on every edition (Arch, CachyOS, Fedora and Void)
and runs it as a session service. This bundle turns that service back on if it
was switched off and configures the compatible apps already on the machine. Add
another integration later with:

```bash
/usr/share/ryoku/palette-bridge/install-integrations.sh --all
```

Check the service and published palette at any time:

```bash
ryoku-palette-bridge-doctor
```

Spotify may restart during initial setup. Ryostore's Installed badge checks
command presence, not service health; use the doctor above to check a running
installation.

Zen's live extension must be signed by Mozilla; the upstream repository has a
guided setup for that. Zen needs one restart to load its profile preferences
and stylesheet, and its extension must be installed separately before live
updates work; installing this bundle alone does not install the signed
extension.

Maintainer: Sipper1236 (Rayyan), through the upstream GitHub issue tracker.
This community bundle is maintained by its contributor, not the Ryoku team.
Installation downloads nothing: the bridge comes from Ryoku's own packages.
Optional app setup invokes Spicetify and Ryoku materialization, writes the
Matugen user overlay and the detected apps' theme configuration, and records
integration ownership. Runtime palette traffic stays on 127.0.0.1:47616.
Zen signing uses Mozilla's add-on service; Vesktop loads Midnight from
refact0r.github.io and its icon from upload.wikimedia.org.

The top-level `installers/ryoku-palette-bridge.sh` is a compatibility copy for
older Ryostore clients that cannot resolve bundle-local installers. The installer
test checks that both copies remain identical.

Source: <https://github.com/Sipper1236/ryoku-palette-bridge>

License: MIT. The bundled integration templates retain the third-party notices
included upstream.
