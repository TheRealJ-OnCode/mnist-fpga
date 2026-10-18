import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import datasets, transforms
train_set = datasets.MNIST(root="data", train=True, download=True, transform=transforms.ToTensor())
model = nn.Sequential(
    nn.Flatten(),
    nn.Linear(196, 16),
    nn.ReLU(),
    nn.Linear(16, 10),
)
print(model)
total = sum(p.numel() for p in model.parameters())
print("parameters:", total)
image, label = train_set[0]
small = F.avg_pool2d(image, kernel_size=2)
x = small.unsqueeze(0)
scores = model(x)
print("scores:", scores)
print("prediction:", scores.argmax().item(), "| real:", label)