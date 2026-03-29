#!/usr/bin/env bash
set -euo pipefail

BIN=${1:-/home/chris/variant-nnue-tools/src/stockfish}

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

VARIANT_FILE="$TMPDIR/vlb-symbol.ini"
cat > "$VARIANT_FILE" <<'VAR'
[vlb-token-smoke:fairy]
maxRank = 5
maxFile = 5
pieceDrops = true
customPiece1 = a':W
pieceValueMg = a':321
startFen = 4k/5/5/5/A'3K[A'a'] w - - 0 1
VAR

OUT=$(
  printf 'setoption name VariantPath value %s\nsetoption name UCI_Variant value vlb-token-smoke\nposition startpos\nd\nquit\n' "$VARIANT_FILE" \
    | "$BIN" 2>&1
)

printf '%s\n' "$OUT"

[[ "$OUT" == *"variant vlb-token-smoke"* ]]
[[ "$OUT" == *"Fen: 4k/5/5/5/A'3K[A'a'] w - - 0 1"* ]]
[[ "$OUT" == *"A'"* ]]
[[ "$OUT" != *"Invalid syntax"* ]]
[[ "$OUT" != *"Invalid piece character"* ]]
