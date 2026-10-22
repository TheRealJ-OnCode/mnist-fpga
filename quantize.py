import torch
from data import get_loaders
from model import make_model


def quantize(w):
    """Symmetric int8 quantization: largest |w| maps to 127."""
    multiplier = 127 / w.abs().max().item()
    q = torch.round(w * multiplier).to(torch.int8)
    return q, multiplier


def evaluate(model, test_loader):
    correct = 0
    with torch.no_grad():
        for images, labels in test_loader:
            predictions = model(images).argmax(dim=1)
            correct += (predictions == labels).sum().item()
    return correct / len(test_loader.dataset)


model = make_model()
model.load_state_dict(torch.load("model_float.pt"))
_, test_loader = get_loaders()

print("float accuracy:", evaluate(model, test_loader))

w1 = model[1].weight.detach().clone()
w2 = model[3].weight.detach().clone()

q1, m1 = quantize(w1)
q2, m2 = quantize(w2)
print("layer 1 multiplier:", m1, "| int8 range:", q1.min().item(), "to", q1.max().item())
print("layer 2 multiplier:", m2, "| int8 range:", q2.min().item(), "to", q2.max().item())

with torch.no_grad():
    model[1].weight.copy_(q1.float() / m1)
    model[3].weight.copy_(q2.float() / m2)

print("int8 accuracy:", evaluate(model, test_loader))

# Bu dosya, train.py’nin ürettiği 3322 ondalıklı sayıyı int8 tam sayıya çevirip “ağ bundan çok bozuluyor mu?” diye bakıyor.
# Tablodaki en büyük ağırlığı bul (eksi olsa bile mutlak değerine bakar).
# Çarpan hesapla: 127 / en_büyük. Böylece en büyük ağırlık 127 olur.
# Hepsini çarpanla çarp, yuvarla, int8 yap.
# int8 mümkün mü? Bu fayl bunun cavabaidir basqa hecne deyil !!!!!!!!