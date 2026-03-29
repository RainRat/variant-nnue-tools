#!/usr/bin/env bash
set -euo pipefail

bin=${1:-./src/stockfish}
net=${2:-/home/chris/Fairy-Stockfish-X/src/nn-3475407dc199.nnue}

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
