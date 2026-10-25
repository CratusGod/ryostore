# Ryoku Discord Optimized

A performance-focused adaptation of [Ron’s Ryoku Discord theme](https://github.com/niqqudim/ryoku-discord), maintained by [Sipper1236](https://github.com/Sipper1236/ryoku-discord).

## Enable the theme

Install through Ryostore, then open **Vesktop → Settings → Vencord → Themes** and enable **Ryoku Optimized**. Enable one full theme at a time to avoid competing layout rules. Installation does not enable a theme or change QuickCSS.

This is a separate community variant of the theme Ryoku ships. It uses its own product ID and CSS filename, so it can coexist with the shipped theme and can be removed independently.

## Rendering changes

- Channel, member, DM and settings-list hover motion uses `translate` instead of animating layout margins.
- Friends and message requests fade once per list surface instead of running a staggered animation on every row.
- Completed shop-card entrance animations release their translate and scale effects.
- The chat-history scroller retains a targeted scroll preparation hint, verified by live channel-switch comparisons.
- Global and individual animation settings apply to the list fades; reduced motion disables them.

These changes reduce the number of animation instances and remove layout-affecting hover movement. They are not a guarantee of higher frame rates on every Discord page or system. Live test results and limitations are recorded in the [source repository’s performance notes](https://github.com/Sipper1236/ryoku-discord/blob/main/PERFORMANCE.md).

## Live verification

Tested in Vesktop 1.6.7 with an isolated profile. Sixteen warmed switches between
the same two text channels gave median ready times of 1,062.7 ms upstream and
1,061.8 ms optimized. Median style-calculation time was 475.6 ms and 417.3 ms
respectively. This sample shows less style work, with no meaningful overall
channel-switch speedup. Results depend on the profile and workload.

Four additional channel switches with the theme held fixed produced no changes
to Vencord's theme stylesheet, no observed stock-theme samples, and no horizontal
page overflow. All seven settings variants passed Chromium animation-control
checks, including reduced motion. The preview is a real Vesktop screenshot with
account names and avatars replaced with example data.

The actual Ryostore client also installed and removed this package successfully
with isolated XDG directories. The installed CSS matched the live-tested build
byte for byte.

## Network resources

The installed stylesheet bundles the upstream layout CSS, fork overrides, and most artwork. It retains the original optional web resources:

- `fonts.googleapis.com` serves font CSS, whose font files come from `fonts.gstatic.com`.
- `davart154.github.io` serves the Context Icons stylesheet.
- Some upstream icon resource URLs reference `discord.com/assets` and `refact0r.github.io`; the configured defaults may override those URLs.

These remote styles and resources are fetched by Vesktop when the theme is enabled. The Store manifest hashes the packaged stylesheet; it does not pin the contents of remote resources. The theme does not include installer scripts or start background commands.

## Maintenance and license

Sipper1236 maintains this community adaptation and handles compatibility reports and updates through the [source repository](https://github.com/Sipper1236/ryoku-discord/issues). Ryoku’s maintainers do not maintain this item.

The original theme is by Ron. Its shared theme foundations include system24 and midnight by refact0r. The included MIT license notice is retained in `LICENSE.txt`.
