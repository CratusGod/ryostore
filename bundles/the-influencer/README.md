# The Influencer

A complete **stream, record, edit, reformat, and publish** kit: a
curated set of recording, editing, audio, and thumbnail tools, plus a
**right-click video toolkit** in the file manager that ships with the bundle and
needs no setup. Install it from **Settings, Extras, The Influencer, Install all**
(core items); optional items install one at a time from the card. Removing the
bundle removes everything it added.

## The right-click video toolkit (shipped from ryostore, no setup)

**Video Reformat** is a Nautilus script pack: it adds a **Scripts, Ryoku Creator**
menu to the file manager. Select one or more clips, right-click, and pick an
action. It runs on `ffmpeg`, installed by the bundle:

- **Reformat** to 9:16, 1:1, or 16:9 (crop or pad) for Reels, TikTok, and Shorts.
- **Transcode** to H.264 or H.265, or **Transcode for DaVinci (DNxHR)** so the
  free Resolve build can import your footage.
- **Compress to 8 MiB** (Discord-safe), **Make GIF**, **Extract audio (MP3)**.
- **Generate captions (SRT)** with local, offline speech-to-text through
  whisper.cpp's `whisper-cli`. On Arch and CachyOS the optional `whisper-cpp`
  item installs it; Fedora's `whisper-cpp` ships only the library and Void has
  no package, so there you build whisper.cpp yourself.
- **Strip metadata**, **Grab thumbnail**.

See `nautilus/video-reformat/README.md`.

## Core tools

| Tool | What it is | Arch / CachyOS |
| --- | --- | --- |
| obs-studio | Streaming and recording studio (PipeWire capture). | pacman |
| obs-vkcapture | Vulkan/OpenGL game capture on Wayland. | AUR |
| obs-backgroundremoval | AI webcam background removal. | AUR |
| obs-pipewire-audio-capture | Per-application audio capture. | AUR |
| v4l2loopback-dkms + linux-headers | Virtual camera module (see kernel note). | pacman |
| gpu-screen-recorder | GPU-encoded recorder + replay buffer. | pacman |
| wf-recorder | Lightweight wlroots recorder. | pacman |
| kdenlive | Multitrack video editor. | pacman |
| losslesscut-bin | Fast lossless trim/cut/merge. | AUR |
| easyeffects + noise-suppression-for-voice | Mic FX chain + RNNoise. | pacman |
| audacity | Multitrack audio editor. | pacman |
| gimp / inkscape / krita | Thumbnails, vectors, channel art. | pacman |
| yt-dlp | Download reference footage / audio. | pacman |
| handbrake | Batch transcoder with presets. | pacman |
| capture-website-cli | Render a URL to a thumbnail image. | npm |
| youtubeuploader | Scripted YouTube uploads. | Go |

## Optional tools (opt-in per item)

DaVinci Resolve (interactive fetch, see below), REAPER (paid DAW), wl-screenrec,
DistroAV (NDI), Owncast, Shotcut, Blender, Darktable, Upscayl, QPrompt,
Subtitle Edit, and whisper.cpp for the captions action.

## DaVinci Resolve

Resolve is proprietary; its licence forbids redistribution, so it cannot be
bundled. On Arch and CachyOS, selecting it opens the Blackmagic download page,
waits for you to save the installer `.zip`, then builds the AUR package. Fedora
and Void have no AUR, so the store lists it greyed out there; Blackmagic's own
Linux installer is the way in. The **free** Linux build cannot import
H.264/H.265 + AAC, so run the **Transcode for DaVinci (DNxHR)** right-click
action on your clips first.

## On Fedora and Void

The last column is where a tool comes from on Arch and CachyOS. On Fedora and
Void, Ryoku installs each tool from that edition's own repositories, under its
own package name; npm and Go come along so the two command-line tools can be
built. A tool an edition does not package stays listed in the store, greyed out
with the reason and where to get it instead (usually Flathub), and **Install
all** skips it. Noise suppression is the one gap with a stand-in already in the
bundle: EasyEffects has RNNoise built in.

The right-click toolkit uses the system's own `ffmpeg`. Fedora's `ffmpeg-free`
has no libx264 or libx265, so there the H.264 actions encode through OpenH264
and Transcode to H.265 uses the graphics card's encoder; see
`nautilus/video-reformat/README.md`.

## Notes

- **Kernel headers:** `v4l2loopback-dkms` builds against the running kernel's
  headers. If the DKMS build fails, install the headers matching your kernel
  (`linux-cachyos-headers` on the CachyOS kernel) and re-run.
- **NVIDIA on Wayland:** OBS NVENC and PipeWire capture want driver 555+.
- Quick clip and instant-replay recording are covered by the shipped
  gpu-screen-recorder and Ryoku's record controls; OBS here is for streaming and
  multi-source recording.
