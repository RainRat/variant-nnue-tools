#!/usr/bin/env bash
set -euo pipefail

bin=${1:-./src/stockfish}
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FSX_ROOT=${FSX_ROOT:-${ROOT_DIR}/../Fairy-Stockfish-X}
net=${2:-${FSX_ROOT}/src/nn-3475407dc199.nnue}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/pure.in" <<EOF
setoption name UCI_Variant value chess
setoption name Use NNUE value pure
setoption name EvalFile value $net
isready
eval
quit
EOF

cat >"$tmpdir/hybrid.in" <<EOF
setoption name UCI_Variant value chess
setoption name Use NNUE value true
setoption name EvalFile value $net
isready
eval
quit
EOF

"$bin" <"$tmpdir/pure.in" >"$tmpdir/pure.out" 2>&1
"$bin" <"$tmpdir/hybrid.in" >"$tmpdir/hybrid.out" 2>&1

grep -q 'enabled (pure)' "$tmpdir/pure.out"
grep -q 'Final evaluation.*\[pure NNUE\]' "$tmpdir/pure.out"

grep -q 'enabled (hybrid)' "$tmpdir/hybrid.out"
grep -q 'Final evaluation.*\[with scaled NNUE, hybrid, ...\]' "$tmpdir/hybrid.out"

echo "nnue-pure-mode: ok"
