# MacShell local port

Source: https://github.com/0-ss/MacShell
Pinned source: d4f8500c41577ab7d056470a7931392786ed0300
Original project by Rickky (0-ss) and contributors.

MacShell is MIT licensed. The upstream LICENSE file accompanies the vendored source.
Its QML, shaders, fonts and visual design remain attributable to the original authors.
MacLock is bundled as source for future integration but is not activated by this port.

Ryoku adaptations:
- Hosted by the existing full-desktop barstyle loader, not another Quickshell process
- IPC handlers namespaced as `macshell-*` to avoid conflicts
- Ryoku retains ownership of the notification server and clipboard watcher
- MacShell notifications consume the existing Ryoku notification model
- Ryoku docks and desktop widgets yield when MacShell is selected
- Automatic display mode restoration is disabled
- Expensive live capture options are off at first launch
- Upstream installer, autostart, update timer and Hyprland bindings are not run

This is a local integration candidate, not a tested or published RyoStore package.
