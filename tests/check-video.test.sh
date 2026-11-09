#!/bin/sh
# check-video.py measures a rendered file: size, rate, length, audio, black and still stretches,
# loudness and true peak. One clip that passes, then one fault per block.
set -eu
command -v ffmpeg >/dev/null && ffmpeg -version >/dev/null 2>&1 || { echo "ffmpeg missing or broken"; exit 77; }
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
check=$(cd "$(dirname "$0")/.." && pwd)/skills/package-nt/references/check-video.py
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; cd "$tmp"
fail() { echo "FAIL: $*"; cat out 2>/dev/null; exit 1; }
rcof() { rc=0; python3 "$check" "$@" >out 2>&1 || rc=$?; echo "$rc"; }

# 4 s of moving test picture with a tone raised to about -14 LUFS and capped below -1 dBTP.
ffmpeg -v error -f lavfi -i testsrc2=size=320x180:rate=30:duration=4 -f lavfi -i sine=frequency=440:duration=4 \
  -af loudnorm=I=-14:TP=-2:LRA=7 -ar 48000 -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest good.mp4
[ "$(rcof good.mp4 --size 320x180 --fps 30 --duration 3-5 --audio yes)" -eq 0 ] || fail "good clip failed"
grep -q '^PASS  size: 320x180' out || fail "size line missing"
grep -q '^PASS  loudness: -1[345]\.[0-9]* LUFS' out || fail "loudness not measured near -14"
grep -q '^PASS  true peak: ' out || fail "true peak line missing"

# Wrong size, wrong length and a required-silent check each fail with the measured value.
[ "$(rcof good.mp4 --size 1920x1080 --duration 15-25 --audio no)" -eq 1 ] || fail "wrong spec passed"
grep -q '^FAIL  size: 320x180 (want 1920x1080)' out || fail "size failure not reported"
grep -q '^FAIL  length: 4.0' out || fail "length failure not reported"
grep -q '^FAIL  audio stream: present (want no)' out || fail "audio failure not reported"

# A quiet tone fails loudness.
ffmpeg -v error -f lavfi -i testsrc2=size=320x180:rate=30:duration=4 -f lavfi -i sine=frequency=440:duration=4 \
  -af volume=-30dB -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest quiet.mp4
[ "$(rcof quiet.mp4)" -eq 1 ] || fail "quiet clip passed"
grep -q '^FAIL  loudness: ' out || fail "quiet clip loudness not failed"

# A still picture for 5 s fails, unless a hold covers it; a black second fails.
ffmpeg -v error -f lavfi -i color=c=gray:size=320x180:rate=30:duration=5 -an -c:v libx264 -pix_fmt yuv420p still.mp4
[ "$(rcof still.mp4)" -eq 1 ] || fail "still clip passed"
grep -q '^FAIL  still stretches over 3 s: 0.00-' out || fail "still stretch not reported"
[ "$(rcof still.mp4 --hold 0-5)" -eq 0 ] || fail "hold did not excuse the still stretch"
ffmpeg -v error -f lavfi -i color=c=black:size=320x180:rate=30:duration=1 -an -c:v libx264 -pix_fmt yuv420p black.mp4
[ "$(rcof black.mp4)" -eq 1 ] || fail "black clip passed"
grep -q '^FAIL  black stretches: 0.00-' out || fail "black stretch not reported"

# Not a video: exit 1 with a message, never a traceback.
printf 'not a video' > bad.mp4
rc=$(rcof bad.mp4); [ "$rc" -ne 0 ] || fail "bad file passed"
! grep -q Traceback out || fail "bad file raised a traceback"
