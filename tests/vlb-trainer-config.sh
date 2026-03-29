#!/usr/bin/env bash
set -euo pipefail

engine="${1:-./src/stockfish}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/chess" "$tmpdir/twochar"

cat > "$tmpdir/twochar.ini" <<'EOF'
[mini-vlb]
variantTemplate = chess
maxRank = 8
maxFile = h
customPiece1 = a':W
promotionPieceTypes = Q R B N A'
startFen = 4k3/8/8/8/8/8/8/4K3 w - - 0 1
EOF

printf 'setoption name UCI_Variant value chess\ntrainer_config chess %s\nquit\n' "$tmpdir/chess" \
  | "$engine" > "$tmpdir/chess.out" 2>&1

grep -q '^#define MOVE_SQUARE_BITS 6$' "$tmpdir/chess/variant.h"
grep -q '^#define NNUE_KING 0$' "$tmpdir/chess/variant.h"
grep -q '^MOVE_SQUARE_BITS = 6$' "$tmpdir/chess/variant.py"
grep -q '^NNUE_KING = False$' "$tmpdir/chess/variant.py"

printf 'setoption name VariantPath value %s\nsetoption name UCI_Variant value mini-vlb\ntrainer_config mini-vlb %s\nquit\n' \
  "$tmpdir/twochar.ini" "$tmpdir/twochar" | "$engine" > "$tmpdir/twochar.out" 2>&1

grep -q 'Writing config for variant mini-vlb' "$tmpdir/twochar.out"
grep -q '^#define MOVE_SQUARE_BITS 6$' "$tmpdir/twochar/variant.h"
grep -q '^#define DATA_SIZE 512$' "$tmpdir/twochar/variant.h"
