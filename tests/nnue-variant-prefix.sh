#!/usr/bin/env bash
set -euo pipefail

bin=${1:-./src/stockfish}
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FSX_ROOT=${FSX_ROOT:-${ROOT_DIR}/../Fairy-Stockfish-X}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ln -sf /home/chris/.local/kooshi-nnue-exp/nets/kooshi-last.nnue "$tmpdir/kooshi-last.nnue"

cat >"$tmpdir/in.txt" <<EOF
setoption name VariantPath value ${FSX_ROOT}/src/variants.ini
setoption name UCI_Variant value ko-oshi
setoption name Use NNUE value true
setoption name EvalFile value $tmpdir/kooshi-last.nnue
isready
quit
EOF

"$bin" <"$tmpdir/in.txt" >"$tmpdir/out.txt" 2>&1

grep -q 'info string NNUE disabled for variant ko-oshi: EvalFile basename must start with the variant name or alias' "$tmpdir/out.txt"

echo "nnue-variant-prefix: ok"
