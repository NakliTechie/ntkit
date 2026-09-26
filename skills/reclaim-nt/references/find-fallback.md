# Fallback sweep — no disktree-cli

Use only when `disktree-cli` is missing and cannot be installed (no cargo).
It finds files, not directories, sizes them by length rather than blocks,
skips nothing on other volumes, and knows no tiers: every hit is `judge`.
Say so in the report's coverage note.

```bash
find "$TARGET" -xdev -type f -size +50M 2>/dev/null | while read -r f; do
  git -C "$TARGET" ls-files --error-unmatch "$f" >/dev/null 2>&1 || echo "$f"
done | sort -u
```

Name the common shapes explicitly: model weights (`.safetensors` `.gguf`
`.bin` `.pt` `.ckpt` `.onnx`), archives (`.zip` `.tar.gz` `.dmg` `.pkg`),
datasets, rendered output, disk images. Apply with `trash <path>` (macOS
14+ ships `/usr/bin/trash`), never `rm`.
