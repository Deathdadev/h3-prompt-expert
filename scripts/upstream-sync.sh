#!/usr/bin/env bash
# Pull the current h3-prompt-expert payload from the MiniMax Design market
# endpoint and stage it into this repo. Prints one status line:
#   version=<X-Skill-Version> hash=<X-Skill-Hash> files=<count>
#
# The endpoint is a public unauthenticated GET, but it requires a query string,
# and the skills CLI refuses to record query-string URLs in skills-lock.json.
# This repo exists to give the same payload a clean, lockable address.
set -uo pipefail

ENDPOINT="${UPSTREAM_ENDPOINT:-https://design.minimax.io/api/v1/skills/market/download?name=h3-prompt-expert&source=sync}"
SKILL_DIR="skills/h3-prompt-expert"
STATE_FILE="upstream.sha256"
TMP=".sync-tmp"
OUT_DIR="$TMP/skill"

rm -rf "$TMP"
mkdir -p "$OUT_DIR"
zip="$TMP/skill.zip"
headers="$TMP/headers.txt"

if ! curl -fsSL -D "$headers" -o "$zip" --max-time 90 "$ENDPOINT"; then
  echo "sync failed: endpoint unreachable" >&2
  exit 1
fi

remote_hash="$(grep -i '^x-skill-hash:' "$headers" | tr -d '\r\n' | cut -d' ' -f2- | sed 's/^sha256://')"
remote_version="$(grep -i '^x-skill-version:' "$headers" | tr -d '\r\n' | cut -d' ' -f2)"

# Extract into the temp dir first: a failed archive must never wipe the tree.
if command -v unzip >/dev/null 2>&1; then
  unzip -q -o "$zip" -d "$OUT_DIR"
elif command -v 7z >/dev/null 2>&1; then
  7z x -y -o"$OUT_DIR" "$zip" >/dev/null
elif command -v python3 >/dev/null 2>&1; then
  python3 -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip" "$OUT_DIR"
elif command -v python >/dev/null 2>&1; then
  python -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip" "$OUT_DIR"
else
  echo "sync failed: no archive extractor available" >&2
  rm -rf "$TMP"
  exit 1
fi

if [ ! -f "$OUT_DIR/SKILL.md" ]; then
  echo "sync failed: SKILL.md missing from archive" >&2
  rm -rf "$TMP"
  exit 1
fi

rm -rf "$SKILL_DIR"
mkdir -p "$SKILL_DIR"
cp -r "$OUT_DIR/." "$SKILL_DIR/"

# The market endpoint repacks the archive on every request (X-Skill-Hash and zip
# bytes differ between identical GETs), so a raw copy would churn the repo each
# run. Rebuild the zip from the extracted content: sorted paths, fixed mtime.
mkdir -p upstream
py="$(command -v python3 || command -v python)"
if [ -n "$py" ] && "$py" - "$SKILL_DIR" upstream/h3-prompt-expert.zip <<'PY'
import os, sys, zipfile
root, out = sys.argv[1], sys.argv[2]
names = sorted(
    os.path.relpath(os.path.join(d, f), root).replace(os.sep, "/")
    for d, _, fs in os.walk(root) for f in fs
)
deflate = getattr(zipfile, "DEFLATE", None) or zipfile.ZIP_DEFLATED
with zipfile.ZipFile(out, "w", deflate) as z:
    for name in names:
        info = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
        info.compress_type = deflate
        info.external_attr = 0o644 << 16
        with open(os.path.join(root, name.replace("/", os.sep)), "rb") as src:
            z.writestr(info, src.read())
PY
then
  printf '%s\n' "$(sha256sum upstream/h3-prompt-expert.zip | cut -d' ' -f1)" > "$STATE_FILE"
elif mv "$zip" upstream/h3-prompt-expert.zip 2>/dev/null; then
  echo "no python for deterministic zip; using raw archive (expect churn)" >&2
  printf '%s\n' "$remote_hash" > "$STATE_FILE"
else
  echo "sync failed: could not stage archive" >&2
  rm -rf "$TMP"
  exit 1
fi

rm -rf "$TMP"
content_hash="$(cut -d' ' -f1 < "$STATE_FILE")"
files="$(find "$SKILL_DIR" -type f | wc -l)"
echo "version=${remote_version:-unknown} hash=$content_hash files=$files"
