#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BIN=${1:-${ROOT_DIR}/src/stockfish}

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

VARIANT_FILE="$TMPDIR/vlb-symbol-options.ini"
cat > "$VARIANT_FILE" <<'VAR'
[vlb-token-options:fairy]
maxRank = 5
maxFile = 5
pieceDrops = true
customPiece1 = z':W
customPiece2 = y':F
pieceValueMg = z':321 y':222
pieceValueEg = z':111 y':112
piecePoints = z':3 y':4
promotionLimit = z':1 y':2
promotedPieceType = p:z' z':q
startFen = 4k/5/5/5/Z'1Y'1K[Z'Y'] w - - 0 1
VAR

OUT=$(
  printf 'setoption name VariantPath value %s\nsetoption name UCI_Variant value vlb-token-options\nposition startpos\nd\nquit\n' "$VARIANT_FILE" \
    | "$BIN" 2>&1
)

printf '%s\n' "$OUT"

[[ "$OUT" == *"variant vlb-token-options"* ]]
[[ "$OUT" == *"Fen: 4k/5/5/5/Z'1Y'1K[Y'Z'] w - - 0 1"* ]]
[[ "$OUT" == *"Z'"* ]]
[[ "$OUT" == *"Y'"* ]]
[[ "$OUT" != *"Invalid syntax"* ]]
[[ "$OUT" != *"Invalid piece type"* ]]
