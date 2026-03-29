#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: script/compile_data_loader.sh [trainer_dir]

Build the variant-nnue-pytorch data loader using CMake.

Defaults to ../variant-nnue-pytorch relative to this script.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
trainer_dir=${1:-"$script_dir/../../variant-nnue-pytorch"}
trainer_dir=$(cd -- "$trainer_dir" && pwd)

if [[ ! -f "$trainer_dir/compile_data_loader.bat" ]]; then
  echo "compile_data_loader.bat not found in $trainer_dir" >&2
  exit 1
fi

cmake "$trainer_dir" \
  -B"$trainer_dir/build" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX="$trainer_dir"
cmake --build "$trainer_dir/build" --config RelWithDebInfo --target install -j"$(nproc)"
