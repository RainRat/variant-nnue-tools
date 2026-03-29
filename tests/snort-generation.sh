#!/usr/bin/env bash
set -euo pipefail

bin=${1:-./src/stockfish}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

chess_out="$tmpdir/chess.out"
ataxx_out="$tmpdir/ataxx.out"
snort_out="$tmpdir/snort.out"
snort_bin="$tmpdir/snort.bin"

printf 'position startpos\nd\nquit\n' | "$bin" >"$chess_out"
grep -q 'Fen: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1' "$chess_out"

printf 'setoption name UCI_Variant value ataxx\nposition startpos\ngo perft 1\nquit\n' | "$bin" >"$ataxx_out"
grep -q 'Nodes searched: 16' "$ataxx_out"

cat >"$tmpdir/snort.in" <<EOF
setoption name Threads value 1
setoption name Hash value 16
setoption name UCI_Variant value snort
isready
generate_training_data depth 2 count 20 random_multi_pv 4 random_multi_pv_diff 300 random_move_count 8 random_move_max_ply 20 write_min_ply 0 eval_limit 10000 set_recommended_uci_options data_format bin output_file_name $snort_bin
quit
EOF

timeout 20s "$bin" <"$tmpdir/snort.in" >"$snort_out" 2>&1
grep -q 'INFO: generate_training_data finished.' "$snort_out"
test -s "$snort_bin"

echo "snort-generation: ok"
