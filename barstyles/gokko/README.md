# Gokko (ごっこ)

macOS-inspired Liquid Glass subshell for Ryoku with top menu bar, Dock,
Spotlight, Control Center, settings, and desktop widgets.

## Source and attribution

Based on [0-ss/MacShell](https://github.com/0-ss/MacShell) (MIT licence),
with Ryoku integration and compositor-neutral adaptations. This product includes
upstream files under `upstream/`; `maclock/` is included for source completeness
but is not automatically installed as a separate lockscreen or activated.
See `LICENSE`, `NOTICE.md` and `PROVENANCE.txt`.

## Compatibility and integration status

Developed on Ryoku's Niri backend; Hyprland is also a target. The local prototype
modifies Ryoku shell-wide components, notably desktop widget hosting, the
barstyle registry, and default Dock ownership. Those *core* modifications are
included for review in `docs/ryoku-core.patch` but are **not automatically
applied by RyoStore**. Installing the barstyle folder alone does not prove that
all features work on an unmodified Ryoku release. The required core integration
must land in the Ryoku shell (or be refactored to public Store APIs) before this
entry should be merged/released.

This product does not bundle Int Clay (its licence disallows redistribution of
modified versions). Do not enable MacLock merely by installing this barstyle.

## Maintenance

Integration maintained by aethctl. The maintainer is responsible for updating
upstream dependencies, testing on supported WMs, and handling security reports.
