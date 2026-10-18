import torch
from data import get_loaders
from model import make_model
torch.manual_seed(0)
train_loader, test_loader = get_loaders()
model = make_model()
def evaluate():
    correct = 0
    with torch.no_grad():
        for images, labels in test_loader:
            predictions = model(images).argmax(dim=1)
            correct += (predictions == labels).sum().item()
    return correct / len(test_loader.dataset)
print("accuracy before training:", evaluate())
loss_fn = torch.nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
for epoch in range(5):
    for images, labels in train_loader:
        scores = model(images)
        loss = loss_fn(scores, labels)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
    print(f"epoch {epoch + 1}: loss {loss.item():.3f}, accuracy {evaluate():.4f}")
torch.save(model.state_dict(), "model_float.pt")