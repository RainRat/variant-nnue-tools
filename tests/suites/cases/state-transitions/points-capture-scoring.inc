#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../../../../tests/lib/uci.sh"
init_test_env "${1:-}" "${2:-}" "capture points scoring"
load_inline_variants </dev/null

for rule in us them owner non-owner none; do
    cat >>"$FSX_TMP_INI" <<INI
[direct-$rule:chess]
pointsCounting = true
pointsRuleCaptures = $rule
piecePoints = p:3
startFen = 7k/8/8/8/8/p7/R7/7K w - - 0 1 {0 0}

[locust-$rule:chess]
pieceToCharTable = PNBRQK....D.....pnbrqk....d.....
customPiece1 = d:c{hurdles: 2,2; pre: 1,*; post: 1,1; capture: locust_all; hurdle_types: enemy}R
pointsCounting = true
pointsRuleCaptures = $rule
piecePoints = p:1 d:0 k:0
startFen = 7k/8/8/3p4/3p4/3D4/8/K7 w - - 0 1 {0 0}
INI
done

for rule in us them owner non-owner none; do
    case "$rule" in
        us|non-owner) direct_score='3 0'; locust_score='2 0' ;;
        them|owner) direct_score='0 3'; locust_score='0 2' ;;
        none) direct_score='0 0'; locust_score='0 0' ;;
    esac
    out=$(run_uci "$ENGINE" "$FSX_TMP_INI" "direct-$rule" <<'UCI'
position startpos moves a2a3
d
UCI
)
    assert_contains "$out" "Fen: 7k/8/8/8/8/R7/8/7K b - - 0 1 {$direct_score}"

    out=$(run_uci "$ENGINE" "$FSX_TMP_INI" "locust-$rule" <<'UCI'
position startpos moves d3d6
d
UCI
)
    assert_contains "$out" "Fen: 7k/8/3D4/8/8/8/8/K7 b - - 0 1 {$locust_score}"
done

echo 'capture points scoring passed (all recipient rules, direct and multi-capture)'
