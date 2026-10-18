import torch
from data import get_loaders
from model import make_model

model = make_model()
model.load_state_dict(torch.load("model_float.pt"))
_, test_loader = get_loaders()
images, labels = next(iter(test_loader))
image, label = images[0], labels[0]
with torch.no_grad():
    scores = model(image.unsqueeze(0))

print("real:", label.item())
print("scores:", [round(s, 1) for s in scores[0].tolist()])
print("prediction:", scores.argmax().item())
weights = model[1].weight
print("layer 1 weights:", weights.shape)
detector = weights[0].reshape(14, 14)
limit = detector.abs().max() * 0.3

for row in detector:
    line = ""
    for w in row:
        if w > limit:
            line += "++"
        elif w < -limit:
            line += "--"
        else:
            line += "  "
    print(line);
    