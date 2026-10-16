# The spark

An original character, not a copy of any logo: twelve rounded rays of different lengths
around a soft core, in a warm orange, with two tall eyes. The irregular lengths are the
point: the shape reads as hand-drawn and stays recognisable at 48 x 48.

## Geometry

Every frame is rasterised from the same function (`body()` in `bin/gen-sprites.py`):

- 12 rays, 30 degrees apart, offset so none points straight up (accessories sit between
  the two upper rays); lengths 13 to 17.5 px.
- A capsule per ray, 5.2 px wide at the base tapering to 2.8 px with a round tip.
- A core of radius 8.6 px. Light comes from the top left: three tones plus a 1 px outline.
- A cell is 48 x 48 px; the sheet holds 53 frames, 10 per row.

Animations come from three knobs, so they all feel like one creature: `scale` (rays and
core swell), `amp`/`phase` (a wave of extra length travelling around the rays) and `rot`.

| Animation | Frames | Idea |
| --- | --- | --- |
| idle | 9 steps (5 drawings) | slow breathing, a blink, a glance sideways |
| sleeping | 4 | rays pulled in, eyes closed, rising `z` |
| awake | 6, one-shot | rays pop out, overshoot, settle |
| thinking | 6 | the length wave travels round, eyes up-right, thought dots |
| working | 8, 110 ms | fast wave, tiny rotation jitter, sparks at the tips |
| listening | 4 | wide eyes, a `?` |
| success | 8, one-shot | burst, happy eyes, blush, confetti |
| error | 6, one-shot | shake, red flush, `x` eyes, sweat drop |
| alert | 6 | jitter, wide eyes, a flashing `!`, red tips |

Palette (hex): body `#d97757`, shade `#b2583c`, light `#f09a7a`, outline `#3a1d12`, eyes
`#2a140c`.
