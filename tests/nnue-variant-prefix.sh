#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
bin=${1:-${ROOT_DIR}/src/stockfish}
tmpdir=$(mktemp -d)
cleanup() {
    local test_status=$?
    if [[ $test_status != 0 && -f "$tmpdir/out.txt" ]]; then
        cat "$tmpdir/out.txt" >&2
    fi
    rm -rf "$tmpdir"
    exit "$test_status"
}
trap cleanup EXIT

# Test the filename guard independently of external variant files and real nets.
cat >"$tmpdir/variants.ini" <<'VARIANTS'
[nnue-prefix-test:chess]
VARIANTS
printf 'not a neural network\n' >"$tmpdir/wrong-prefix.nnue"

cat >"$tmpdir/in.txt" <<EOF_INPUT
setoption name VariantPath value $tmpdir/variants.ini
setoption name UCI_Variant value nnue-prefix-test
setoption name Use NNUE value true
setoption name EvalFile value $tmpdir/wrong-prefix.nnue
isready
position startpos
eval
quit
EOF_INPUT

"$bin" <"$tmpdir/in.txt" >"$tmpdir/out.txt" 2>&1

grep -Fq "info string NNUE disabled for variant nnue-prefix-test: EvalFile basename must start with the variant name or alias (requested $tmpdir/wrong-prefix.nnue)" "$tmpdir/out.txt"
grep -Fq 'readyok' "$tmpdir/out.txt"
grep -Fq 'Final evaluation' "$tmpdir/out.txt"
if grep -Eq '^NNUE evaluation[[:space:]]' "$tmpdir/out.txt"; then
    echo 'A mismatched network must not be evaluated' >&2
    exit 1
fi

echo "nnue-variant-prefix: ok"
