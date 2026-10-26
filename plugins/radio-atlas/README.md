# Radio Atlas (Ryoku port)

Live radio on a rotatable globe from the QS Bar. Click a station signal to play
it, or click a country to browse its stations. Playback runs in `mpv`, with an
MPRIS bridge so the desktop media controls work.

Ported from `akshar.radio-atlas` 0.1.9 (Omarchy bar widget, by Akshar Patel) to
the Ryoku plugin contract. The player, the directory client, the sandbox and the
MPRIS bridge are the upstream code; the only changes are the runtime paths and
the plugin/host API surface.

## What it does

- **Widget** (`content/Widget.qml`): a globe glyph with the playing station or
  the volume. Left click opens the globe, middle click tunes a random station,
  right click stops or resumes, the wheel changes volume.
- **Panel** (`content/Panel.qml`): the globe — drag to spin, wheel to zoom,
  click a signal to play, click a country to browse. Below it: search, the
  station list, favourites and recent, the player (play/pause/stop/next/previous,
  volume, mute), and an audio-output picker.
- **Service** (`service/Main.qml`): the saved state (favourites, history,
  volume, audio output) and the station directory.

## What it runs, reads, writes

- Runs: `bin/radio-fetch` (the Radio Browser directory), `bin/radio-player`
  (mpv plus its MPRIS bridge), `bin/radio-state` (saved state),
  `bin/radio-session` + `bin/radio-sandbox` + `bin/radio-mpris` + `bin/radio-proxy`
  (the player's network sandbox and media bridge), `bin/radio-status.lua` (mpv's
  own status script), and `bin/radio-favicon` (station logos). Every command is
  declared in `dependencies.commands`.
- Reads: the Radio Browser station directory and public station stream and
  artwork URLs. Stream playlists are data, not executable code.
- Writes: transient playback files under `$XDG_RUNTIME_DIR/ryoku-radio-atlas`
  and saved state and caches under `pluginApi.stateDir`
  (`$XDG_STATE_HOME/ryoku/plugins/radio-atlas`).
- No sudo, doas or su. No pkexec. No downloaded code is executed.

## Capabilities

- **Network**: `all.api.radio-browser.info` and its mirrors for the station
  directory, plus public station stream and artwork hosts returned by that
  directory. These hosts vary per station, so the manifest declares `*`.
  The playback proxy refuses non-public destinations, and artwork downloads
  pin validated addresses through redirects.
- **Audio**: playback through the PipeWire sink you choose, including RAOP
  (AirPlay) sinks.

## Removing it

Disabling or unloading the plugin stops its player. To remove it manually:

```
ryoku plugin remove radio-atlas
```

Favourites, history, volume and caches live under
`$XDG_STATE_HOME/ryoku/plugins/radio-atlas/` and can be removed there.
