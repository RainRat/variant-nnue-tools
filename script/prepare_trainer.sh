#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  prepare_trainer.sh ENGINE VARIANT OUTPUT_DIR [--variant-path PATH] [--trainer-dir DIR]

Examples:
  script/prepare_trainer.sh src/stockfish ko-oshi /tmp/kooshi-cfg \
    --variant-path /path/to/variants.ini

  script/prepare_trainer.sh src/stockfish ko-oshi /tmp/kooshi-cfg \
    --variant-path /path/to/variants.ini \
    --trainer-dir /path/to/variant-nnue-pytorch

This script:
  1. runs `trainer_config` for the selected variant
  2. writes `variant.h` and `variant.py` into OUTPUT_DIR
  3. optionally copies those files into a trainer checkout

It does not generate training data or launch training.
EOF
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

ENGINE=$1
VARIANT=$2
OUTPUT_DIR=$3
shift 3

VARIANT_PATH=""
TRAINER_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --variant-path)
      VARIANT_PATH=${2:-}
      shift 2
      ;;
    --trainer-dir)
      TRAINER_DIR=${2:-}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

cmds=()
if [[ -n "$VARIANT_PATH" ]]; then
  cmds+=("setoption name VariantPath value $VARIANT_PATH")
fi
cmds+=("setoption name UCI_Variant value $VARIANT")
cmds+=("trainer_config $VARIANT $OUTPUT_DIR")
cmds+=("quit")

printf '%s\n' "${cmds[@]}" | "$ENGINE"

if [[ ! -f "$OUTPUT_DIR/variant.h" || ! -f "$OUTPUT_DIR/variant.py" ]]; then
  echo "trainer_config did not produce variant.h and variant.py in $OUTPUT_DIR" >&2
  exit 1
fi

if [[ -n "$TRAINER_DIR" ]]; then
  cp "$OUTPUT_DIR/variant.h" "$TRAINER_DIR/variant.h"
  cp "$OUTPUT_DIR/variant.py" "$TRAINER_DIR/variant.py"
fi

echo
echo "Generated trainer config for $VARIANT in $OUTPUT_DIR"
if [[ -n "$TRAINER_DIR" ]]; then
  echo "Copied variant.h and variant.py into $TRAINER_DIR"
  echo
  echo "Next steps:"
  echo "  cd $TRAINER_DIR"
  echo "  python3 -m venv env"
  echo "  . env/bin/activate"
  echo "  python -m pip install -r requirements-CUDA128.txt"
  echo "  python -m pip install 'setuptools<81'"
  echo "  sh compile_data_loader.bat"
fi
