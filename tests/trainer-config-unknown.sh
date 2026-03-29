#!/usr/bin/env bash
set -euo pipefail

BIN=${1:-/home/chris/variant-nnue-tools/src/stockfish}

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

VARIANT_FILE="$TMPDIR/too-large.ini"
cat > "$VARIANT_FILE" <<'VAR'
[too-large:fairy]
maxRank = 10
maxFile = 9
startFen = 9/9/9/9/9/9/9/9/9/9 w - - 0 1
VAR

OUT=$(
  printf 'setoption name VariantPath value %s\ntrainer_config too-large %s\nquit\n' "$VARIANT_FILE" "$TMPDIR" \
    | "$BIN" 2>&1
)

printf '%s\n' "$OUT"

[[ "$OUT" == *"Unknown variant: too-large"* ]]
[[ "$OUT" != *"Segmentation fault"* ]]

