#!/usr/bin/env python3
"""Convert a WebVTT subtitle file to plain text.

Written for YouTube captions as downloaded by yt-dlp. Auto-generated captions
there are "rolling": every cue repeats the previous line and adds one more,
with inline <c> and <00:00:00.000> timing tags. Those repeats and tags are
removed, HTML entities are decoded, and the text is grouped into one paragraph
per minute of video, each prefixed with a [m:ss] marker. Ordinary VTT files
(uploader-provided subtitles) go through the same pipeline.

Usage:
    vtt2text.py [--llm] [--no-timestamps] [--info VIDEO.info.json] FILE.vtt

--llm prepends a preamble (title, channel, date, caption source, caveats) so
the output can be pasted straight into an LLM conversation as context. The
metadata comes from the .info.json that yt-dlp writes with --write-info-json;
without it the preamble is generic.

Used by the fish function `yt-transcript`; see ~/.config/README.md.
"""

import argparse
import datetime
import html
import json
import re
import sys
from pathlib import Path

TIMING_RE = re.compile(r"^(?:(\d+):)?(\d{2}):(\d{2})[.,](\d{3})\s+-->")
VOICE_TAG_RE = re.compile(r"<v(?:\.[^\s>]*)?\s+([^>]+)>")
TAG_RE = re.compile(r"<[^>]*>")
WS_RE = re.compile(r"\s+")


def fmt_time(seconds):
    seconds = int(seconds)
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    if h:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m}:{s:02d}"


def parse_cues(text):
    """Yield (start_seconds, text) for every non-empty caption line.

    Header lines, NOTE blocks and cue identifiers are skipped because they
    appear before a timing line in their block. A block ends at a truly empty
    line; whitespace-only lines (YouTube emits those) stay inside the block.
    """
    start = None
    for raw in text.splitlines():
        if raw == "":
            start = None
            continue
        line = raw.strip()
        match = TIMING_RE.match(line)
        if match:
            hours, minutes, secs, millis = match.groups()
            start = int(hours or 0) * 3600 + int(minutes) * 60 + int(secs) + int(millis) / 1000
            continue
        if start is None or not line:
            continue
        line = VOICE_TAG_RE.sub(r"\1: ", line)
        line = TAG_RE.sub("", line)
        line = WS_RE.sub(" ", html.unescape(line)).strip()
        if line:
            yield start, line


def dedupe(cues):
    """Drop lines identical to the previous one (YouTube's rolling repeats)."""
    last = None
    for start, line in cues:
        if line == last:
            continue
        last = line
        yield start, line


def paragraphs(cues):
    """Group cue lines into one paragraph per minute of video.

    Yields (marker, text) where marker is the start time of the first cue in
    that minute, formatted with fmt_time.
    """
    current_minute = None
    marker = None
    buffer = []
    for start, line in cues:
        minute = int(start // 60)
        if minute != current_minute:
            if buffer:
                yield marker, " ".join(buffer)
                buffer = []
            current_minute = minute
            marker = fmt_time(start)
        buffer.append(line)
    if buffer:
        yield marker, " ".join(buffer)


def load_info(path):
    if path is None:
        return None
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError) as exc:
        print(f"vtt2text: could not read {path}: {exc}", file=sys.stderr)
        return None


def caption_lang(vtt_path):
    """yt-dlp names subtitle files <id>.<lang>.vtt; pull out <lang>."""
    suffixes = vtt_path.suffixes
    if len(suffixes) >= 2:
        return suffixes[-2].lstrip(".")
    return None


def caption_source(info, lang):
    """Describe where the captions came from, and whether they are automatic."""
    if info is None or lang is None:
        return "captions", None
    manual = info.get("subtitles") or {}
    automatic = info.get("automatic_captions") or {}
    if lang in manual:
        entries, auto = manual[lang], False
    elif lang in automatic:
        entries, auto = automatic[lang], True
    else:
        entries, auto = [], None
    name = next((e.get("name") for e in entries if e.get("name")), None) or lang
    if auto is True:
        return f"auto-generated YouTube captions ({name})", True
    if auto is False:
        return f"subtitles provided by the uploader ({name})", False
    return f"captions ({name})", None


def llm_preamble(info, lang, timestamps):
    today = datetime.date.today().isoformat()
    source, auto = caption_source(info, lang)
    lines = ["The following is a transcript of a YouTube video, included as context for this conversation.", ""]

    if info:
        title = info.get("title")
        channel = info.get("channel") or info.get("uploader")
        upload_date = info.get("upload_date")
        if upload_date and re.fullmatch(r"\d{8}", upload_date):
            upload_date = f"{upload_date[:4]}-{upload_date[4:6]}-{upload_date[6:]}"
        duration = info.get("duration")
        if isinstance(duration, (int, float)):
            duration = fmt_time(duration)
        else:
            duration = info.get("duration_string")
        url = info.get("webpage_url") or info.get("original_url")
        for label, value in (
            ("Title", title),
            ("Channel", channel),
            ("Published", upload_date),
            ("Duration", duration),
            ("URL", url),
        ):
            if value:
                lines.append(f"{label}: {value}")

    lines.append(f"Transcript source: {source}, downloaded on {today}.")
    lines.append("")
    lines.append("Notes on the transcript:")
    if auto:
        # yt-dlp names the spoken-language track LANG-orig and translations
        # either by plain code or <target>-<source>, e.g. en-no. Only the
        # latter is certainly machine translated.
        translated = "-" in (lang or "") and not lang.endswith("-orig")
        how = "automatic speech recognition and machine translation" if translated else "automatic speech recognition"
        lines.append(
            f"- The captions were produced by {how}, so expect misheard words "
            "(especially names and jargon), missing punctuation, and no speaker labels."
        )
    elif auto is False:
        lines.append("- The subtitles were written by the uploader; caption line breaks have been merged into paragraphs.")
    else:
        lines.append("- Captions may contain recognition errors and lack punctuation or speaker labels.")
    if timestamps:
        lines.append("- Each paragraph starts with a [m:ss] marker giving the time in the video where it begins.")

    chapters = (info or {}).get("chapters") or []
    if chapters:
        lines.append("")
        lines.append("Chapters:")
        for chapter in chapters:
            title = chapter.get("title")
            start = chapter.get("start_time")
            if title is not None and start is not None:
                lines.append(f"- [{fmt_time(start)}] {title}")

    lines.extend(["", ""])
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="vtt2text",
        description="Convert a WebVTT subtitle file (e.g. YouTube captions from yt-dlp) to plain text.",
    )
    parser.add_argument("vtt", type=Path, help="subtitle file to convert")
    parser.add_argument("--info", type=Path, help="yt-dlp .info.json for the video, used by --llm")
    parser.add_argument("--llm", action="store_true", help="prepend a preamble describing the transcript")
    parser.add_argument("--no-timestamps", action="store_true", help="omit the per-minute [m:ss] markers")
    args = parser.parse_args(argv)

    try:
        text = args.vtt.read_text(encoding="utf-8-sig")
    except OSError as exc:
        print(f"vtt2text: {exc}", file=sys.stderr)
        return 1

    timestamps = not args.no_timestamps
    body = []
    for marker, paragraph in paragraphs(dedupe(parse_cues(text))):
        body.append(f"[{marker}] {paragraph}" if timestamps else paragraph)

    if not body:
        print(f"vtt2text: no caption text found in {args.vtt}", file=sys.stderr)
        return 1

    out = sys.stdout
    if args.llm:
        info = load_info(args.info)
        out.write(llm_preamble(info, caption_lang(args.vtt), timestamps))
        out.write("--- BEGIN TRANSCRIPT ---\n")
        out.write("\n\n".join(body))
        out.write("\n--- END TRANSCRIPT ---\n")
    else:
        out.write("\n\n".join(body))
        out.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
