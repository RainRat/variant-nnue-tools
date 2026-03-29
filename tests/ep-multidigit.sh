#!/usr/bin/env bash
set -euo pipefail

BIN=${1:-/home/chris/variant-nnue-tools/src/stockfish}

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

VARIANT_FILE="$TMPDIR/ep10.ini"
cat > "$VARIANT_FILE" <<'VAR'
[ep10:fairy]
maxRank = 10
maxFile = 8
startFen = 8/pa6/8/8/8/8/8/8/8/4K2k w - a10 0 1
VAR

OUT=$(
  printf 'setoption name VariantPath value %s\nsetoption name UCI_Variant value ep10\nposition startpos\nd\nquit\n' "$VARIANT_FILE" \
    | "$BIN" 2>&1
)

printf '%s\n' "$OUT"

if [[ "$OUT" != *"variant ep10"* ]]; then
  echo "skip: ep10 requires LARGEBOARDS"
  exit 0
fi

[[ "$OUT" == *"Fen: 8/pa6/8/8/8/8/8/8/8/4K2k w - a10 0 1"* ]]
[[ "$OUT" != *"Invalid syntax"* ]]
