
from data import load
import torch

sd = torch.load('model_float.pt')
W1 = sd['0.weight']
b1 = sd['0.bias']
s_w1 = 127 / W1.abs().max()
W1_q = torch.round(W1 * s_w1).long()
b1_q = torch.round(b1 * s_w1 * 255).long()
K = 11

_, _, x_test, _ = load()
x = x_test[0]          

j = 0
acc = b1_q[j].item()
print(f"baslangic: acc = bias = {acc}")
for i in range(196):
    p = x[i].item()
    w = W1_q[j, i].item()
    acc += p * w
    if p != 0:
        print(f"adim {i+1:3d}: piksel={p:3d}  agirlik={w:4d}  carpim={p*w:6d}  acc={acc}")
print(f"\nz = {acc}")
print(f"h1_q = {min(max(acc, 0) >> K, 255)}")

acc = b1_q[j].item()
for i in range(196):
    w_prev = W1_q[j, i-1].item() if i > 0 else W1_q[j, 0].item()
    acc += x[i].item() * w_prev
print(f"kaymis hesap (gecikme duzeltilmezse): {acc}")

z1 = x @ W1_q.T + b1_q
h1_q = torch.clamp(torch.relu(z1) >> K, max=255)
print("\n16 z1  :", z1.tolist())
print("16 h1_q:", h1_q.tolist())