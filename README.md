# MNIST on FPGA

A tiny neural network that recognizes handwritten digits, trained in Python and quantized to 8-bit integers so it can run on an FPGA without any floating-point hardware.

This repository contains the Python side of the project: training, quantization, and an integer-only reference model that the FPGA implementation must match bit-for-bit.

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

## Results so far

| Model | Test accuracy |
|---|---|
| Float32 | 94.53% |
| Layer 1 weights quantized to int8 | 94.50% |

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
python quantize.py    # quantizes weights to int8 and measures accuracy
```

MNIST is downloaded automatically into `data/` on the first run.

## Project structure

| File | Purpose |
|---|---|
| `data.py` | Loads MNIST, downscales to 14x14, returns batched data loaders |
| `model.py` | Network definition |
| `train.py` | Trains the float model and saves the weights |
| `quantize.py` | Symmetric per-tensor int8 quantization of the weights |
| `explore_data.py` | Exploration: draws a sample digit at 28x28 and 14x14 |
| `try_model.py` | Exploration: runs an untrained network on one image |
| `inspect_model.py` | Exploration: prints scores and draws a learned layer-1 detector |

## Roadmap

- [x] Data pipeline and 14x14 downscaling
- [x] Float model training
- [x] Layer 1 int8 quantization
- [x] Layer 2 int8 quantization
- [x] Integer-only reference model (int32 bias, requantization between layers)
- [ ] Export weights and test vectors for the FPGA
- [ ] FPGA implementation
