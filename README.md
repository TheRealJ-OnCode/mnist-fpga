# MNIST on FPGA

A tiny neural network that recognizes handwritten digits, trained in Python and quantized to 8-bit integers so it can run on an FPGA without any floating-point hardware.

This repository contains the Python side of the project: training, quantization, an integer-only reference model, and the export of weights and test vectors for the FPGA. The FPGA implementation must match the reference model bit-for-bit.

## Network

```
14x14 image (196 pixels)
   -> Linear(196, 16) -> ReLU
   -> Linear(16, 10)
   -> argmax = predicted digit
```

- Input: MNIST images downscaled from 28x28 to 14x14 with 2x2 average pooling
- Parameters: 3,322 (3,136 + 16 in layer 1, 160 + 10 in layer 2)
- In int8, all weights fit in about 3.3 KB

## Results

| Model | Test accuracy (10,000 images) |
|---|---|
| Float32 | 94.53% |
| int8 weights, float math (simulation) | 94.56% |
| **Integer-only reference model** | **94.54%** |

## Integer-only inference

This is exactly what the FPGA computes. No floats, no division.

```
x     = 196 pixels, unsigned 8-bit (0-255)

acc1  = W1 · x + B1                    # int8 weights, int32 bias, 16 sums
acc1  = max(0, acc1)                   # ReLU
h     = (acc1 * M0 + ROUND) >> SHIFT   # requantization to 0-255
h     = min(h, 255)                    # saturation

acc2  = W2 · h + B2                    # int8 weights, int32 bias, 10 scores
digit = argmax(acc2)                   # ties: lowest index wins
```

Constants: `M0 = 118`, `SHIFT = 16`, `ROUND = 32768`.

Input downscaling (if done on the FPGA): each 14x14 pixel is `(a + b + c + d + 2) >> 2` of its 2x2 block.

### Accumulator widths

| Value | Max observed (10,000 test images) | Bits (signed) | Theoretical worst case |
|---|---|---|---|
| `acc1` | 146,716 | 19 | ~6.35M, 24 bits |
| `acc1 * M0 + ROUND` | 17,254,396 | 26 | ~750M, 31 bits |
| `acc2` | 32,089 | 16 | ~519k, 21 bits |

Sizing registers for the theoretical worst case guarantees no overflow for any input.

## Exported files (`export/`)

All `.mem` files contain one hex value per line and can be loaded with Verilog `$readmemh`. Negative values are two's complement.

| File | Contents | Lines |
|---|---|---|
| `w1.mem` | Layer 1 weights, int8, address = `neuron * 196 + pixel` | 3136 |
| `b1.mem` | Layer 1 biases, int32 | 16 |
| `w2.mem` | Layer 2 weights, int8, address = `neuron * 16 + hidden` | 160 |
| `b2.mem` | Layer 2 biases, int32 | 10 |
| `params.vh` | `M0`, `SHIFT`, `ROUND` and sizes as Verilog `localparam` | - |
| `test_images.mem` | First 100 test images, 196 unsigned 8-bit pixels each | 19600 |
| `test_hidden.mem` | Expected hidden values, 16 per image | 1600 |
| `test_scores.mem` | Expected scores, 10 int32 per image | 1000 |
| `test_pred.mem` | Expected prediction per image | 100 |
| `test_expected.txt` | Human-readable: image index, true label, prediction | 100 |

The reference model gets 96 of these 100 images right. The FPGA must reproduce the same predictions, including the 4 wrong ones.

## Setup

Requires Python 3.11+.

```
python -m venv venv
venv\Scripts\activate
pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
pip install numpy
```

On Linux/macOS, activate with `source venv/bin/activate`.

## Usage

```
python train.py       # trains the float model, saves model_float.pt
python quantize.py    # int8 weight quantization, float vs int8 accuracy
python reference.py   # integer-only reference model, test accuracy
python export.py      # writes weights, parameters and test vectors to export/
```

MNIST is downloaded automatically into `data/` on the first run.

## Project structure

| File | Purpose |
|---|---|
| `data.py` | Loads MNIST, downscales to 14x14, returns batched data loaders |
| `model.py` | Network definition |
| `train.py` | Trains the float model and saves the weights |
| `quantize.py` | Symmetric per-tensor int8 quantization, accuracy check |
| `reference.py` | Calibration, integer constants and the integer-only reference model |
| `export.py` | Exports weights, biases, parameters and test vectors for the FPGA |
| `explore_data.py` | Exploration: draws a sample digit at 28x28 and 14x14 |
| `try_model.py` | Exploration: runs an untrained network on one image |
| `inspect_model.py` | Exploration: prints scores and draws a learned layer-1 detector |

## Roadmap

- [x] Data pipeline and 14x14 downscaling
- [x] Float model training
- [x] int8 weight quantization (both layers)
- [x] Integer-only reference model (int32 bias, requantization between layers)
- [x] Export weights and test vectors for the FPGA
- [ ] FPGA implementation
- [ ] FPGA testbench against the exported test vectors