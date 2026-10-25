import torch
# import torch.nn as nn
import torch.nn.functional as F
from torchvision import datasets,transforms
train_set = datasets.MNIST(root='data',train=True,download=True)
test_set = datasets.MNIST(root='data',train=False,download=True)


def prepare(dataset):
    x = dataset.data.float()
    x = x.unsqueeze(1)
    x = F.avg_pool2d(x, kernel_size=2)
    x_int = torch.round(x).long()
    x_int = x_int.flatten(1)
    y = dataset.targets
    return x_int, y


def load():
    x_train, y_train = prepare(train_set)
    x_test, y_test = prepare(test_set)
    return x_train, y_train, x_test, y_test
