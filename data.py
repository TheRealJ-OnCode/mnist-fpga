import torch.nn.functional as F
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
def downscale(image):
    return F.avg_pool2d(image, kernel_size=2)
transform = transforms.Compose([transforms.ToTensor(), downscale])

def get_loaders(batch_size=64):
    train_set = datasets.MNIST(root="data", train=True, download=True, transform=transform)
    test_set = datasets.MNIST(root="data", train=False, download=True, transform=transform)
    train_loader = DataLoader(train_set, batch_size=batch_size, shuffle=True)
    test_loader = DataLoader(test_set, batch_size=1000)
    return train_loader, test_loader


if __name__ == "__main__":
    train_loader, test_loader = get_loaders()
    images, labels = next(iter(train_loader))
    print("images:", images.shape)
    print("labels:", labels.shape, labels[:10])