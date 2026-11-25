---
name: rex-graphics
description: Draw a supporting graphic (architecture or topology chart, flow, sequence, comparison, quick diagram) and show it as an image in a Rex pane through the kitty graphics protocol. Use when the user asks to "draw", "sketch", "chart" or "diagram" something "in rex", "in a pane", "with kitty protocol", or wants a picture of a design beside the conversation.
---

# Graphics in a Rex pane

The pipeline is HTML with inline SVG → PNG at 2× from headless Chrome → a pane to the right that
shows the PNG with the kitty graphics protocol. Files beside this skill:

- `render.sh <file.html> <out.png> [width] [height]`: renders the page at 2× (default 1600×1000 CSS px).
- `show.py <file.png>`: fits the image to the pane, falls back to 8×16 px cells when the terminal
  reports no pixel size, redraws on resize and stays open until Ctrl-C.
- `example-topology.html`: a finished chart. Copy its `<style>`, `<defs>` and legend rather than
  starting from nothing.

## What this machine has

Chrome is the renderer. There is no `dot`, `d2`, `mmdc`, `rsvg-convert`, `kitten` or `chafa`, and
ImageMagick's built-in SVG renderer draws poor text. Do not install anything for a quick chart.

## Steps

1. **Write the page** in the session's scratchpad, e.g. `<scratchpad>/graphics/<name>.html`.
   Lay it out with absolute SVG coordinates on a fixed canvas. Keep the example's palette so charts
   look alike from one time to the next:

   | Class | Means |
   |---|---|
   | `.box` | existing |
   | `.new` (blue border) | new or proposed |
   | `.gone` (red, dashed) | removed |
   | `.later` (grey, dashed) | later or optional |
   | `.ext` | outside the system |
   | `.grp` (dotted) | a boundary: repo, domain, account |
   | `.e` / `.ed` | a call / a later call, with marker `#a` / `#ad` |

   Put a small uppercase tag at the top of each box (EXISTING, NEW, EXTERNAL), a title, then short
   bullet lines. Route edges orthogonally, and put a background rect (`.elbg`) behind an edge label
   that crosses a line. Always include a legend.

2. **Render it:** `~/.claude/skills/rex-graphics/render.sh <name>.html <name>.png`.

3. **Look at the PNG with the Read tool before showing it.** A capture of the pane is text only, so
   this is the only way to catch overlapping labels, clipped text or an edge through a box. Fix and
   re-render until it reads cleanly.

4. **Show it beside the agent's own pane**, without taking focus:

   ```sh
   rex split -s "$REX_SESSION" -b "$REX_BLOCK" --split=right --ratio 55 --label <Name> \
     --focus=false --json -- python3 ~/.claude/skills/rex-graphics/show.py "<abs path>.png"
   ```

   Save `.block_ids[0]`. Check it is running with
   `rex block call -s "$REX_SESSION" -b <block> process`.

5. **To update the chart**, re-render to the same PNG and send `ctrl+c` to the pane, then split
   again, or close it with `rex block close`. Do not stack a second pane beside the first.

## Report

Name the pane, say what the chart shows in two or three lines, and give the full absolute path of
the HTML and PNG. Say that the image itself was checked with Read, and that the pane was not
seen, since capture cannot show images.
