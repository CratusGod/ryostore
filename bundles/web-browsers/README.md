# Web Browsers

A browser shelf for Ryoku: daily browsing, web development, privacy testing,
and Chromium/Firefox compatibility checks. Install it from **Settings, Extras,
Web Browsers, Install all**, or pick individual browsers from the card.

## Included browsers

| Browser | What it is | Arch / CachyOS |
| --- | --- | --- |
| firefox | Mozilla's stable Firefox browser. | pacman |
| firefox-developer-edition | Firefox preview build with developer-focused tooling. | pacman |
| chromium | Open-source Chromium browser and web runtime. | pacman |
| brave-bin | Brave browser with built-in privacy protections and ad blocking. | AUR |
| librewolf | Privacy-hardened Firefox fork with telemetry removed. | pacman |
| zen-browser-bin | Zen Browser, a Firefox-based browser with a calmer, customizable UI. | AUR |

## On Fedora and Void

The last column is where a browser comes from on Arch and CachyOS. Firefox and
Chromium install from Fedora's and Void's own repositories. Firefox Developer
Edition, Brave, LibreWolf and Zen are not packaged there; the store lists them
greyed out with where to get them instead (mozilla.org or Flathub).

## Notes

- All browsers are listed as separate bundle items, so users can install just
  the ones they want.
- On Arch and CachyOS, `brave-bin` and `zen-browser-bin` come from the AUR.
- The bundle intentionally includes both Firefox and Chromium-family browsers
  so web developers can test both engines quickly.
