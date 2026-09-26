#!/bin/sh
# Bake a poster into frame 0 of a video, so every platform's idle thumbnail shows it.
# X, Slack and Discord build the thumbnail from frame 0 and ignore cover-art metadata
# (method from latent-spaces/brag, MIT). Only frame 0's pixels change: the script checks
# that size, frame count and duration match the input, and that frame 0 now is the poster.
#
# Usage:
#   bake-poster.sh <video.mp4> <seconds>      # pull the frame at <seconds> into <video>.jpg, bake it
#   bake-poster.sh <video.mp4> <poster.jpg>   # bake an existing image, scaled to the video's size
#
# Pick <seconds> at a settled beat: every line fully in, nothing mid-transition.
# For a GIF, bake the MP4 first and derive the GIF from it, so frame 0 carries over.
set -eu

[ $# -eq 2 ] || { echo "usage: $0 <video.mp4> <seconds|poster.jpg>" >&2; exit 1; }
VIDEO=$1; SRC=$2
[ -f "$VIDEO" ] || { echo "no such video: $VIDEO" >&2; exit 1; }
command -v ffmpeg >/dev/null && command -v ffprobe >/dev/null \
  || { echo "ffmpeg and ffprobe must be on PATH" >&2; exit 1; }

shape() {  # width,height,frames of the first video stream
  ffprobe -v error -select_streams v:0 -count_frames \
    -show_entries stream=width,height,nb_read_frames -of csv=p=0 "$1"
}
duration() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"; }

BEFORE=$(shape "$VIDEO"); DUR=$(duration "$VIDEO")
W=${BEFORE%%,*}; REST=${BEFORE#*,}; H=${REST%%,*}

case "$SRC" in
  *.jpg|*.jpeg|*.png) POSTER=$SRC ;;
  *) POSTER="${VIDEO%.*}.jpg"
     ffmpeg -v error -y -ss "$SRC" -i "$VIDEO" -frames:v 1 -q:v 2 "$POSTER" ;;
esac
[ -s "$POSTER" ] || { echo "no poster image at $POSTER" >&2; exit 1; }

OUT="${VIDEO%.*}.baking.mp4"; trap 'rm -f "$OUT"' EXIT
ffmpeg -v error -y -i "$VIDEO" -i "$POSTER" \
  -filter_complex "[1:v]scale=$W:$H,setsar=1[p];[0:v][p]overlay=0:0:enable='eq(n,0)'[v]" \
  -map "[v]" -map '0:a?' -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p \
  -c:a copy -movflags +faststart "$OUT"

AFTER=$(shape "$OUT"); DUR2=$(duration "$OUT")
[ "$AFTER" = "$BEFORE" ] || { echo "size or frame count changed: $BEFORE -> $AFTER" >&2; exit 1; }
awk -v a="$DUR" -v b="$DUR2" 'BEGIN { d = a - b; if (d < 0) d = -d; exit !(d <= 0.05) }' \
  || { echo "duration changed: ${DUR}s -> ${DUR2}s" >&2; exit 1; }

SSIM=$(ffmpeg -hide_banner -i "$OUT" -i "$POSTER" -filter_complex \
  "[0:v]trim=end_frame=1,setpts=PTS-STARTPTS[a];[1:v]scale=$W:$H,setsar=1,format=yuv420p[b];[a][b]ssim" \
  -f null - 2>&1 | sed -n 's/.*All:\([0-9.]*\).*/\1/p' | tail -1)
awk -v s="${SSIM:-0}" 'BEGIN { exit !(s >= 0.95) }' \
  || { echo "frame 0 does not match the poster (SSIM ${SSIM:-none}, need >= 0.95)" >&2; exit 1; }

mv "$OUT" "$VIDEO"; trap - EXIT
echo "baked $POSTER into frame 0 of $VIDEO: ${W}x${H}, ${BEFORE##*,} frames, ${DUR}s, SSIM $SSIM"
