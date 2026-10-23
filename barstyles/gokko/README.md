# Gokko (ごっこ)

A macOS-inspired Liquid Glass **barstyle/subshell** for Ryoku, with an app
menu, Spotlight search, Control Center, Dock and desktop widgets.

## Origin and licensing

Adapted from [0-ss/MacShell](https://github.com/0-ss/MacShell), pinned at
`d4f8500c41577ab7d056470a7931392786ed0300` (MIT). The port retains
upstream credits and licences. See `LICENSE`, `NOTICE.md`, and `PROVENANCE.txt`.

## Installation and compatibility

The Store item is `barstyles/gokko`, with `Scene.qml` as its entrypoint.
**It requires the matching Ryoku shell core integration** for hosted widgets,
bar-family lifecycle, and universal dock ownership. Until that core work is
merged and deployed, installing this package alone does not guarantee the
complete subshell. The core integration is maintained as a **separate Ryoku
PR**, never as an executable patch installed by RyoStore.

The original standalone `Installer.qml`, MacLock shell, and duplicate standalone
`upstream/shell.qml` are not part of the barstyle. Gokko's existing lockscreen
settings may refer to MacLock, which requires a separately installed upstream
component. Those controls are not part of Gokko's guaranteed feature set.

The widget bridge uses the Ryoku shell's own resident wallpaper surface.
Hyprland and Niri both need final on-machine validation. No Gokko installer
is permitted to edit compositor config or invoke a distribution package manager.

## Maintenance

Integration: aethctl. Users should report failures or security findings to the
maintainer. The maintainer is responsible for keeping the Store release and
companion core integration compatible.
