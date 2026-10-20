# Gaming

Turns a fresh Ryoku install into a **ready-to-play** machine: the major
launchers, the full Wine and Proton compatibility layer, DirectX-to-Vulkan
translation, the GameMode / Gamescope / MangoHud performance stack, broad
controller support, a Wayland-friendly Discord, and console emulators for every
system with a proven package. Install it from **Settings, Extras, Gaming,
Install all** (core items); optional items (the emulators and extra tools)
install one at a time from the card. Removing the bundle removes everything it
added.

## 32-bit GPU drivers, installed for your hardware (native, no setup)

The base Ryoku install ships **64-bit** graphics drivers. Most games are 32-bit
somewhere (the Steam client, countless titles, and the 32-bit halves of Wine and
Proton prefixes), and without the matching **32-bit (lib32)** GPU userspace they
fall back to slow software rendering or fail to start. This bundle closes that
gap automatically:

- It turns on the repository the 32-bit packages live in: **[multilib]** on Arch
  and CachyOS, Void's **multilib** (and **nonfree**, for Steam). Fedora ships
  them in its main repositories.
- Then Ryoku's hardware layer runs **`ryoku-gpu-lib32`**, which detects every GPU
  in the machine and installs the right 32-bit Vulkan driver on a 32-bit Mesa and
  Vulkan loader baseline, under each edition's own package names: the Radeon
  driver for AMD, the Intel one for Intel, NVIDIA's own libraries where Ryoku
  installs the NVIDIA driver (Arch and CachyOS) and the open nouveau driver
  elsewhere. A hybrid laptop (Intel iGPU + NVIDIA dGPU) gets both.

That is what lets games run at full hardware capacity out of the box. You never
pick a driver; it follows the card Ryoku already detected. The 64-bit drivers
themselves stay managed by Ryoku's hardware layer, not this bundle.

## Core tools (Install all)

| Tool | What it is | Arch / CachyOS |
| --- | --- | --- |
| steam | Valve store and client, with built-in Proton. | pacman |
| lutris | Game manager for Windows, native, and emulated games. | pacman |
| heroic-games-launcher-bin | Epic, GOG, and Amazon Prime launcher. | AUR |
| umu-launcher | Valve's unified Proton runtime for non-Steam games. | pacman |
| wine + winetricks | Windows compatibility layer and prefix helper. | pacman |
| protontricks | winetricks tasks inside Steam Proton prefixes. | pacman |
| protonup-qt | Installs GE-Proton / Wine-GE for Steam, Lutris, Heroic. | AUR |
| vkd3d + lib32-vkd3d | Direct3D 12 to Vulkan translation (Wine/Lutris). | pacman |
| gamemode + lib32-gamemode | Temporary performance tuning while gaming. | pacman |
| gamescope | Upscaling, frame limiting, and per-game isolation. | pacman |
| mangohud + lib32-mangohud | FPS / frametime / system metrics overlay. | pacman |
| goverlay | GUI to configure MangoHud and vkBasalt. | pacman |
| vkbasalt | Vulkan post-processing (sharpen, FXAA, SMAA). | AUR |
| game-devices-udev | udev rules for Xbox, PS, Nintendo, 8BitDo pads. | AUR |
| vesktop-bin | Discord with Vencord and working Wayland screen share. | AUR |

## Optional tools (opt-in per item)

**Emulators**, one per system, install one at a time from the card:

| System | Tool | Arch / CachyOS |
| --- | --- | --- |
| Multi-system frontend | retroarch (+ libretro-core-info) | pacman |
| SNES / NES / Sega / PS1 / N64 | RetroArch cores: snes9x, mesen, genesis-plus-gx, beetle-psx-hw, mupen64plus-next | pacman |
| GameCube / Wii | dolphin-emu | pacman |
| PlayStation 2 | pcsx2 | AUR |
| PlayStation 3 | rpcs3-bin | AUR |
| PlayStation Portable | ppsspp | pacman |
| Game Boy / GBC / GBA | mgba-qt | pacman |
| Nintendo DS | melonds | AUR |
| Arcade | mame | pacman |
| Adventure games | scummvm | pacman |
| MS-DOS | dosbox | pacman |

**Extra tools:** corectrl (GPU/CPU tuning and fan curves), antimicrox
(gamepad-to-keyboard mapping), and sc-controller (gamepad profiles).

RetroArch's own core downloader is turned off in the Arch and Fedora builds, so
install the RetroArch cores you want from the list above; they appear in
RetroArch under **Load Core** immediately. Void's RetroArch keeps the downloader
(**Online Updater**), which is where the cores Void does not package come from.

## On Fedora and Void

The last column is where a tool comes from on Arch and CachyOS. On Fedora and
Void, Ryoku installs each tool from that edition's own repositories, under its
own package name. A tool an edition does not package stays listed in the store,
greyed out with the reason and where to get it instead (usually Flathub), and
**Install all** skips it. Steam, for example, needs RPM Fusion on Fedora, which
Ryoku does not enable, so the store points to its Flathub build there.

## Notes

- **Detected and skipped.** Anything already on the system is detected and left
  alone, so re-running only fills the gaps.
- **Routing.** On Arch and CachyOS, heroic-games-launcher-bin, protonup-qt,
  vkbasalt, game-devices-udev, vesktop-bin, pcsx2, rpcs3-bin, and melonds come
  from the AUR; the rest come from the official repos, with steam,
  umu-launcher, and every `lib32-` package in [multilib], which the bundle
  enables first.
- **A faster kernel.** On Arch and CachyOS, the **CachyOS Layer** bundle swaps
  in the performance-tuned kernel for lower latency and higher throughput under
  load, and keeps the stock one as a fallback.
- **Emulator coverage.** Only emulators with a proven package are listed. The
  Wii U (cemu), original Xbox (xemu), and Dreamcast (flycast) builds were
  dropped: cemu is flagged out of date upstream, and the other two have too
  little use to trust the build. Install them by hand if you need them.
- **corectrl** needs the `amdgpu.ppfeaturemask=0xffffffff` kernel parameter for
  full AMD overclock control; without it, monitoring and fan curves still work.
