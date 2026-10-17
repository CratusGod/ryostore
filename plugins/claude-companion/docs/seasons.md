# Seasons

Each season is two things: an **outfit** baked into a copy of the sprite sheet
(`assets/season-<id>.png`, the same 53 frames, with the accessory following the body as it
bobs and swells) and **particles** moved in QML by `content/SeasonFx.qml` from the tiny
sprites in `assets/particles.png`.

| id | Outfit | Particles | Auto window (north) |
| --- | --- | --- | --- |
| `christmas` | Santa hat, pompom bobbing | six snowflakes drifting down | 1 Dec to 6 Jan |
| `halloween` | witch hat with buckle | two bats flapping across, one each way | 15 Oct to 2 Nov |
| `summer` | sunglasses | a small breathing sun, three twinkling glints | 21 Jun to 22 Sep |
| `spring` | flower crown (pink and white) | falling petals, a butterfly | 20 Mar to 30 Apr |
| `autumn` | mustard beanie | four tumbling leaves | 23 Sep to 14 Oct, 3 to 30 Nov |

Christmas and Halloween win over the other windows. With *Auto (southern hemisphere)* summer is
7 Jan to 20 Mar, autumn 21 Mar to 20 Jun and spring 23 Sep to 30 Nov (minus Halloween);
Christmas and Halloween keep their dates. Outside every window *Auto* shows the plain spark.

Particles use the sprite's own pixel grid, move on integer pixel steps, and stop when
*Reduced motion* is on or the widget is hidden.

## Adding a season

1. In `bin/gen-sprites.py` add the id to `SEASONS`, its accessory drawing to
   `accessory()`, particle sprites to `PARTICLES` and behaviours to `FX`
   (`fall`, `fly`, `twinkle` or `bob`).
2. `python3 bin/gen-sprites.py --preview /tmp/preview` regenerates the sheets, the two
   `*Defs.qml` files and contact sheets to inspect.
3. Add the id to the `season` choice in `manifest.json`, to `autoSeason()` in
   `service/Main.qml` if it should follow the calendar, and to the `files` list.
