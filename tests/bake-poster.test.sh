#!/bin/sh
# bake-poster.sh puts the chosen frame at frame 0 and changes nothing else.
set -eu
command -v ffmpeg >/dev/null && ffmpeg -version >/dev/null 2>&1 || { echo "ffmpeg missing or broken"; exit 77; }
bake=$(cd "$(dirname "$0")/.." && pwd)/skills/package-nt/references/bake-poster.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; cd "$tmp"
fail() { echo "FAIL: $*"; exit 1; }
ssim() {  # SSIM of frame $2 of video $1 against image $3
  ffmpeg -hide_banner -i "$1" -i "$3" -filter_complex \
    "[0:v]select=eq(n\,$2),setpts=PTS-STARTPTS[a];[1:v]format=yuv420p[b];[a][b]ssim" \
    -frames:v 1 -f null - 2>&1 | sed -n 's/.*All:\([0-9.]*\).*/\1/p' | tail -1
}
ge() { awk -v a="$1" -v b="$2" 'BEGIN { exit !(a >= b) }'; }

# 3 s of testsrc2 (every frame differs) with a tone, 30 fps
ffmpeg -v error -f lavfi -i testsrc2=size=320x180:rate=30:duration=3 -f lavfi -i sine=frequency=440:duration=3 \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest in.mp4
cp in.mp4 orig.mp4
ffmpeg -v error -ss 1.5 -i orig.mp4 -frames:v 1 want.png
ffmpeg -v error -i orig.mp4 -frames:v 1 old0.png

"$bake" in.mp4 1.5 >/dev/null || fail "bake by timestamp exited non-zero"
[ -s in.jpg ] || fail "no poster written next to the video"
ge "$(ssim in.mp4 0 want.png)" 0.95 || fail "frame 0 is not the frame at 1.5 s"
ge 0.80 "$(ssim in.mp4 0 old0.png)" || fail "frame 0 still looks like the original frame 0"
ffmpeg -v error -i orig.mp4 -vf "select=eq(n\,1)" -frames:v 1 orig1.png
ge "$(ssim in.mp4 1 orig1.png)" 0.95 || fail "frame 1 changed"
[ "$(ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 in.mp4)" = 90 ] \
  || fail "frame count changed"
ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 in.mp4 | grep -q audio || fail "audio lost"

# an existing poster of a different size is scaled to the video
ffmpeg -v error -f lavfi -i color=c=red:size=640x360 -frames:v 1 big.png
cp orig.mp4 two.mp4
"$bake" two.mp4 big.png >/dev/null || fail "bake with a larger poster image exited non-zero"
ffmpeg -v error -f lavfi -i color=c=red:size=320x180 -frames:v 1 red.png
ge "$(ssim two.mp4 0 red.png)" 0.95 || fail "the scaled poster is not frame 0"

"$bake" missing.mp4 1 2>/dev/null && fail "a missing video did not fail"
echo ok
