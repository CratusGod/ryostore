# Video Reformat

Right-click video tools for creators, installed into the Nautilus file manager as
a **Scripts -> Ryoku Creator** submenu. Select one or more videos, right-click,
and pick an action. Everything runs on `ffmpeg`, plus whisper.cpp's `whisper-cli`
for the captions action; output lands next to the source with a
suffix, and progress shows as a notification.

Shipped by the **Influencer** bundle; installs with the bundle and removes
cleanly with it (or on its own from the Extras tab).

## Actions

| Action | Output | What it does |
| --- | --- | --- |
| Reformat 9x16 (crop) | `_9x16.mp4` | 1080x1920, center-cropped to fill. Reels / Shorts / TikTok. |
| Reformat 9x16 (pad) | `_9x16.mp4` | 1080x1920, letterboxed (nothing cropped). |
| Reformat 1x1 (crop) | `_1x1.mp4` | 1080x1080, cropped. Feed posts. |
| Reformat 16x9 (pad) | `_16x9.mp4` | 1920x1080, letterboxed. Rescue vertical clips for landscape. |
| Transcode to H.264 | `_h264.mp4` | Universal H.264/AAC (plays everywhere, Discord inline). |
| Transcode to H.265 | `_h265.mp4` | HEVC, ~40% smaller, `hvc1`-tagged. |
| Extract audio (MP3) | `.mp3` | ~190 kbps VBR audio pull. |
| Generate captions (SRT) | `.srt` | Local, offline speech-to-text; needs whisper.cpp's `whisper-cli` (see below), then fetches a small model once. |
| Make GIF | `.gif` | Clean looping GIF (palette, 480px, 15fps). Keep clips short. |
| Compress to 8 MiB | `_8MiB.mp4` | Two-pass H.264 that fits under 8 MiB (Discord-safe). |
| Strip metadata | `_clean.*` | Drop GPS/device/EXIF from videos and images, no re-encode for video. |
| Transcode for DaVinci (DNxHR) | `_davinci.mov` | Editable DNxHR MOV (Resolve free on Linux cannot import H.264/AAC). |
| Grab thumbnail | `_thumb.jpg` | 1280x720 frame (3s in) as a thumbnail base. |

## Notes

- Actions self-filter by extension, so selecting a mixed folder is safe.
- `Compress to 8 MiB` computes bitrate from duration and bails if a clip is too
  long to fit at usable quality.
- Remote selections (`smb://`, `mtp://`) are skipped (no local path).

## On every edition

The actions call the system's own `ffmpeg`. On Arch, CachyOS and Void it carries
libx264 and libx265, and every action works as described above. Fedora's
`ffmpeg-free` leaves both encoders out, so there:

- the H.264 actions (the four reformats, Transcode to H.264 and Compress to
  8 MiB) encode through OpenH264 at 8 Mb/s, and Compress to 8 MiB makes one
  bitrate-held pass instead of two;
- Transcode to H.265 uses the graphics card's encoder (NVENC, then VA-API) and
  says so in its notification when neither can take the clip. An `ffmpeg` built
  with libx265, such as RPM Fusion's, brings the software encoder back.

Captions need whisper.cpp's `whisper-cli`. Arch and CachyOS ship it in their
`whisper-cpp` package. Fedora's `whisper-cpp` carries only the library and Void
has no package, so build whisper.cpp yourself there; the action finds
`whisper-cli` on your `PATH`.
