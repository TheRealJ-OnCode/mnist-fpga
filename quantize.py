import torch
from data import get_loaders
from model import make_model

model = make_model()
model.load_state_dict(torch.load("model_float.pt"));
w1 = model[1].weight.detach()
print("layer 1 weights:", w1.shape);
max_w = w1.abs().max().item()
multiplier = 127 / max_w
print("largest weight:", max_w)
print("multiplier:", multiplier);
q1 = torch.round(w1 * multiplier).to(torch.int8)
print("first 5 float:", [round(v, 3) for v in w1[0, :5].tolist()])
print("first 5 int8: ", q1[0, :5].tolist())
print("int8 range:", q1.min().item(), "to", q1.max().item());
def evaluate(model, test_loader):
    correct = 0
    with torch.no_grad():
        for images, labels in test_loader:
            predictions = model(images).argmax(dim=1)
            correct += (predictions == labels).sum().item()
    return correct / len(test_loader.dataset)
_, test_loader = get_loaders()
print("float accuracy:", evaluate(model, test_loader))
with torch.no_grad():
    model[1].weight.copy_(q1.float() / multiplier)

print("int8 layer 1 accuracy:", evaluate(model, test_loader))