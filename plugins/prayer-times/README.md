# Prayer Times (prayer-times)

A Ryoku bar widget (`topbarGlyph`): a crescent mark with the next prayer and
a live countdown. Click opens a panel with today's six times
(Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha), the Hijri date, and a manual
refresh. Not official, not reviewed by Ryoku.

## What runs

- `bin/prayers <city> <country> <method> <school> <state-dir>` (python3, no
  third-party modules): one scheduled HTTPS GET per day to
  `https://api.aladhan.com/v1/timingsByCity`, plus explicit refreshes and
  setting changes. No key, no account. The user agent is
  `ryoku-prayer-times/1.0`.
- `notify-send -a "Prayer Times" ...`: one desktop notification per prayer,
  fired when the countdown reaches the configured minutes-before (default 5).
  Fires once per prayer per day.
- `paplay /usr/share/sounds/freedesktop/stereo/bell.oga`: the alert bell,
  only together with the notification and only when the sound toggle is on.
- External commands used: `python3`, `notify-send`, `paplay` (all declared
  in `dependencies.commands`).

## What it reads

- Its own settings (`city`, `country`, `method`, `school`, `use12h`) via
  `pluginApi.pluginSettings` — city/country/method/school also travel as
  argv to `bin/prayers`, never through a shell string (argv array, no `sh -c`).
- Nothing else on the system. No privileged commands, no pkexec, no sudo.

## What it writes

- Day cache: `$XDG_STATE_HOME/ryoku/plugins/prayer-times/timings.json`
  (one small JSON file, replaced atomically). On network failure the widget
  serves this cache and marks itself stale instead of going blank.
- Settings only through `pluginApi.saveSetting` (the bar's Community page).
  Never touches `shell.json`, `plugins.json`, or anything outside its own
  state dir.

## Network capability

- `api.aladhan.com` (declared in `capabilities.network`). That is the only
  host contacted.

## Cost

One scheduled request a day, plus explicit refreshes or setting changes, and a
local 20-second countdown tick. There is no background network polling.
