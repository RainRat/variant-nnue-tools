# Training Quickstart

This is the shortest reliable path from a variant in `variant-nnue-tools` to a trainer-ready NNUE setup.

## Scope

This repo generates:
- trainer config via `trainer_config`
- training data via `generate_training_data` / `generate_training_data_nonpv`

Actual NNUE training still happens in the separate `variant-nnue-pytorch` repo.

## 1. Build the data generator

```bash
cd src
make -j4 build ARCH=x86-64-modern
```

For larger boards:

```bash
cd src
make -j4 build ARCH=x86-64-modern largeboards=yes
```

For variants whose training format needs a larger PackedSFEN buffer:

```bash
cd src
make -j4 build ARCH=x86-64-modern largedata=yes
```

If needed, combine both:

```bash
cd src
make -j4 build ARCH=x86-64-modern largeboards=yes largedata=yes
```

## 2. Generate trainer config

You can do it manually:

```bash
cd src
printf 'setoption name UCI_Variant value ko-oshi\ntrainer_config ko-oshi /tmp/kooshi-cfg\nquit\n' | ./stockfish
```

Or use the helper script:

```bash
script/prepare_trainer.sh src/stockfish ko-oshi /tmp/kooshi-cfg
```

If the variant lives in another `variants.ini`, pass `--variant-path`.

If you already have a trainer checkout, pass `--trainer-dir` and the script will copy `variant.h` and `variant.py` into it.

## 3. Generate a small train / validation set

```bash
cd src
printf 'setoption name UCI_Variant value ko-oshi\n\
setoption name PruneAtShallowDepth value false\n\
generate_training_data depth 3 count 4096 output_file_name /tmp/kooshi-train.bin seed train-kooshi\n\
generate_training_data depth 3 count 512 output_file_name /tmp/kooshi-val.bin seed val-kooshi\n\
quit\n' | ./stockfish
```

That is a smoke-sized run, not a serious training set.

## 4. Prepare the trainer repo

The trainer repo is `variant-nnue-pytorch`.

On current Python versions, the smoothest setup is:

```bash
python3 -m venv env
. env/bin/activate
python -m pip install -r requirements-CUDA128.txt
python -m pip install 'setuptools<81'
sh compile_data_loader.bat
```

Notes:
- `compile_data_loader.bat` is also the Linux/macOS entry point despite the name.
- If you are on CUDA 11.x, use `requirements.txt` instead of `requirements-CUDA128.txt`.
- The `setuptools<81` pin avoids the `pkg_resources` removal that currently breaks `pytorch-lightning==1.9.5` on very new Python environments.

## 5. Run a small training smoke

```bash
python train.py \
  --gpus 1 \
  --max_epochs 4 \
  --batch-size 128 \
  --threads 2 \
  --num-workers 1 \
  --epoch-size 4096 \
  --validation-size 512 \
  --random-fen-skipping 0 \
  /tmp/kooshi-train.bin \
  /tmp/kooshi-val.bin
```

## 6. Export a network

```bash
python serialize.py last.ckpt kooshi.nnue
```

Then load it in the engine with:

```bash
setoption name EvalFile value /path/to/kooshi.nnue
setoption name Use NNUE value pure
```

## Common failure modes

- `trainer_config` crashes or errors on an unknown variant:
  - make sure the variant is actually loadable by this binary
  - if the variant is external, pass `--variant-path`

- `trainer_config` warns that the required `DATA_SIZE` exceeds the current build:
  - rebuild with `largedata=yes`
  - combine with `largeboards=yes` if the variant also needs a larger board build

- `compile_data_loader` / CMake confusion:
  - use `sh compile_data_loader.bat` on Linux/macOS

- `ModuleNotFoundError: pkg_resources` in the trainer:
  - install `setuptools<81` inside the trainer virtualenv

- `ModuleNotFoundError: cupy` in the trainer:
  - install the matching CuPy package from the trainer requirements file
