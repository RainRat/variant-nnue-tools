#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: script/check_evalfile.sh STOCKFISH VARIANT EVALFILE [--variant-path PATH]

Run a minimal UCI smoke to verify that a network file loads for a variant.
EOF
}

if [[ $# -lt 3 ]]; then
  usage >&2
  exit 1
fi

stockfish=$1
variant=$2
evalfile=$3
shift 3

variant_path=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --variant-path)
      variant_path=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -x "$stockfish" ]]; then
  echo "Stockfish binary is not executable: $stockfish" >&2
  exit 1
fi

if [[ ! -f "$evalfile" ]]; then
  echo "EvalFile does not exist: $evalfile" >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

{
  if [[ -n "$variant_path" ]]; then
    printf 'setoption name VariantPath value %s\n' "$variant_path"
  fi
  printf 'setoption name UCI_Variant value %s\n' "$variant"
  printf 'position startpos\n'
  printf 'd\n'
  printf 'setoption name Use NNUE value true\n'
  printf 'setoption name EvalFile value %s\n' "$evalfile"
  printf 'isready\n'
  printf 'eval\n'
  printf 'quit\n'
} | "$stockfish" >"$tmp" 2>&1 || true

cat "$tmp"

if ! grep -q "^info string variant $variant " "$tmp"; then
  exit 2
fi

if grep -q 'was not loaded successfully' "$tmp"; then
  exit 1
fi
