import torch.nn as nn


def make_model():
    return nn.Sequential(
        nn.Flatten(),
        nn.Linear(196, 16),
        nn.ReLU(),
        nn.Linear(16, 10),
    )