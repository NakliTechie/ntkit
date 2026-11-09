#!/usr/bin/env python3
"""Measure a rendered video file and print one line per check with the measured value.

Usage: check-video.py VIDEO [--size WxH] [--fps N] [--duration MIN-MAX] [--audio yes|no|any]
                            [--lufs TARGET] [--still SECONDS] [--hold START-END ...]

  --size      expected frame size, e.g. 1920x1080 (default: report only)
  --fps       expected frame rate (default: report only)
  --duration  allowed length in seconds, e.g. 15-25 (default: report only)
  --audio     yes: an audio stream must exist; no: none may exist; any (default)
  --lufs      integrated loudness target, checked to within 1 LU (default -14);
              true peak must be at or below -1 dBTP
  --still     longest allowed stretch with no visible change, in seconds (default 3)
  --hold      a stretch the storyboard marks as a hold, excused from --still (repeatable)

Also fails on any black stretch of 0.5 s or more. Each line is PASS, FAIL or INFO with the
measured value. Exit 0 when nothing failed, 1 when a check failed, 2 on bad input.
Needs ffmpeg and ffprobe on PATH. One decode pass for the picture and sound checks.
"""
import argparse
import json
import re
import shutil
import subprocess
import sys


def span(text):
    m = re.fullmatch(r"\s*([0-9.]+)\s*-\s*([0-9.]+)\s*", text)
    if not m:
        raise argparse.ArgumentTypeError(f"expected START-END in seconds, got {text!r}")
    return float(m.group(1)), float(m.group(2))


def args():
    p = argparse.ArgumentParser(description="Measure a rendered video file.")
    p.add_argument("video")
    p.add_argument("--size")
    p.add_argument("--fps", type=float)
    p.add_argument("--duration", type=span)
    p.add_argument("--audio", choices=("yes", "no", "any"), default="any")
    p.add_argument("--lufs", type=float, default=-14.0)
    p.add_argument("--still", type=float, default=3.0)
    p.add_argument("--hold", type=span, action="append", default=[])
    return p.parse_args()


def probe(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json",
                          path], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"check-video: ffprobe could not read {path}: {out.stderr.strip()}")
    return json.loads(out.stdout)


def rate(text):
    num, _, den = text.partition("/")
    return float(num) / float(den or 1) if float(den or 1) else 0.0


def decode(path, has_audio):
    """One ffmpeg pass: black and frozen stretches from the picture, loudness from the sound."""
    cmd = ["ffmpeg", "-hide_banner", "-nostats", "-i", path,
           "-vf", "blackdetect=d=0.5:pix_th=0.10,freezedetect=n=0.003:d=0.5"]
    cmd += ["-af", "ebur128=peak=true"] if has_audio else ["-an"]
    log = subprocess.run(cmd + ["-f", "null", "-"], capture_output=True, text=True).stderr
    black = [(float(a), float(b)) for a, b in
             re.findall(r"black_start:([0-9.]+) black_end:([0-9.]+)", log)]
    starts = [float(x) for x in re.findall(r"freeze_start: ([0-9.]+)", log)]
    ends = [float(x) for x in re.findall(r"freeze_end: ([0-9.]+)", log)]
    loud = re.findall(r"I:\s+(-?[0-9.]+|-inf) LUFS", log)
    peak = re.findall(r"Peak:\s+(-?[0-9.]+|-inf) dBFS", log)
    return black, starts, ends, (loud[-1] if loud else None), (peak[-1] if peak else None)


def main():
    a = args()
    for tool in ("ffmpeg", "ffprobe"):
        if not shutil.which(tool):
            print(f"check-video: {tool} must be on PATH", file=sys.stderr)
            return 2
    info = probe(a.video)
    video = next((s for s in info["streams"] if s.get("codec_type") == "video"), None)
    audio = [s for s in info["streams"] if s.get("codec_type") == "audio"]
    if video is None:
        print(f"FAIL  video stream: none in {a.video}")
        return 1
    failed = False

    def line(ok, name, value):
        nonlocal failed
        tag = "INFO" if ok is None else ("PASS" if ok else "FAIL")
        failed |= ok is False
        print(f"{tag}  {name}: {value}")

    size = f"{video['width']}x{video['height']}"
    line(None if a.size is None else size == a.size, "size",
         size + ("" if a.size is None else f" (want {a.size})"))
    fps = rate(video.get("avg_frame_rate") or video.get("r_frame_rate", "0/1"))
    line(None if a.fps is None else abs(fps - a.fps) < 0.01, "frame rate",
         f"{fps:.3f} fps" + ("" if a.fps is None else f" (want {a.fps:g})"))
    dur = float(info["format"].get("duration") or video.get("duration") or 0)
    want = "" if a.duration is None else f" (want {a.duration[0]:g}-{a.duration[1]:g} s)"
    line(None if a.duration is None else a.duration[0] <= dur <= a.duration[1], "length",
         f"{dur:.2f} s{want}")
    frames = video.get("nb_frames")
    line(None, "frames", frames if frames else f"about {round(dur * fps)} (container gives no count)")
    has_audio = bool(audio)
    line({"yes": has_audio, "no": not has_audio, "any": None}[a.audio], "audio stream",
         ("present" if has_audio else "none") + ("" if a.audio == "any" else f" (want {a.audio})"))

    black, starts, ends, loud, peak = decode(a.video, has_audio)
    line(not black, "black stretches",
         "none of 0.5 s or more" if not black else
         ", ".join(f"{s:.2f}-{e:.2f} s" for s, e in black))
    ends += [dur] * (len(starts) - len(ends))  # a freeze that runs to the end has no end line
    still = [(s, e) for s, e in zip(starts, ends)
             if e - s > a.still and not any(h0 <= s and e <= h1 for h0, h1 in a.hold)]
    line(not still, f"still stretches over {a.still:g} s",
         "none" if not still else ", ".join(f"{s:.2f}-{e:.2f} s" for s, e in still))
    if has_audio:
        ok = loud not in (None, "-inf") and abs(float(loud) - a.lufs) <= 1.0
        line(ok, "loudness", f"{loud} LUFS integrated (want {a.lufs:g} ± 1)")
        ok = peak not in (None,) and (peak == "-inf" or float(peak) <= -1.0)
        line(ok, "true peak", f"{peak} dBTP (want ≤ -1)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
