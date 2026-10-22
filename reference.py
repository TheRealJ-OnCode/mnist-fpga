import numpy as np
import torch
from data import get_loaders
from model import make_model


def quantize(w):
    """Symmetric int8 quantization: largest |w| maps to 127."""
    multiplier = 127 / np.abs(w).max()
    q = np.round(w * multiplier).astype(np.int8)
    return q, multiplier


# ---------------------------------------------------------------
# Part 1: preparation (calibration + constants for the FPGA)
# ---------------------------------------------------------------

# Load the trained float weights and biases
model = make_model()
model.load_state_dict(torch.load("model_float.pt"))

w1 = model[1].weight.detach().numpy()   # [16, 196]
b1 = model[1].bias.detach().numpy()     # [16]
w2 = model[3].weight.detach().numpy()   # [10, 16]
b2 = model[3].bias.detach().numpy()     # [10]

# Calibration: largest layer-1 output (after ReLU) over all training images
train_loader, test_loader = get_loaders(batch_size=1000)
max_h = 0.0
with torch.no_grad():
    for images, _ in train_loader:
        h = model[2](model[1](model[0](images)))   # Flatten -> Linear -> ReLU
        max_h = max(max_h, h.max().item())
print("calibration max_h:", max_h)

# Integer constants
q1, m1 = quantize(w1)                   # int8 weights, layer 1
q2, m2 = quantize(w2)                   # int8 weights, layer 2
mh = 255 / max_h                        # unit of the hidden layer (0-255)

b1_q = np.round(b1 * 255 * m1).astype(np.int32)   # bias in accumulator units (pixel x weight)
b2_q = np.round(b2 * mh * m2).astype(np.int32)    # bias in accumulator units (hidden x weight)

SHIFT = 16
M0 = int(round(mh / (255 * m1) * 2**SHIFT))       # requantization: multiply by M0, shift right

print("m1:", m1, "| m2:", m2, "| mh:", mh)
print("M0:", M0, "| SHIFT:", SHIFT)
print("b1_q:", b1_q.tolist())
print("b2_q:", b2_q.tolist())


# ---------------------------------------------------------------
# Part 2: integer-only inference (what the FPGA will compute)
# ---------------------------------------------------------------

# Raw MNIST bytes, not the 0-1 floats
raw = test_loader.dataset.data.numpy().astype(np.int32)   # [10000, 28, 28], 0-255
labels = test_loader.dataset.targets.numpy()              # [10000]


def downscale_int(img):
    """28x28 -> 14x14 with integer 2x2 average (rounded), returns 196 values."""
    out = np.zeros((14, 14), dtype=np.int32)
    for y in range(14):
        for x in range(14):
            s = img[2*y, 2*x] + img[2*y, 2*x+1] + img[2*y+1, 2*x] + img[2*y+1, 2*x+1]
            out[y, x] = (s + 2) >> 2
    return out.flatten()


def infer(x):
    """Integer-only forward pass. x: 196 pixels (0-255). Returns 10 int32 scores."""
    acc1 = q1.astype(np.int32) @ x + b1_q            # layer 1: 16 int32 sums
    acc1 = np.maximum(acc1, 0)                        # ReLU
    h = (acc1 * M0 + (1 << (SHIFT - 1))) >> SHIFT     # requantization
    h = np.minimum(h, 255)                            # saturation
    acc2 = q2.astype(np.int32) @ h + b2_q             # layer 2: 10 int32 scores
    return acc2


print("first test image scores:", infer(downscale_int(raw[0])).tolist(), "| label:", labels[0])

correct = 0
for i in range(len(labels)):
    scores = infer(downscale_int(raw[i]))
    if scores.argmax() == labels[i]:
        correct += 1

print("integer accuracy:", correct / len(labels))