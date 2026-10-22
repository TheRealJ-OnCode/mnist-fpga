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
    
    
# 70000 MINST i endirir
# Resimler 28x28 pikselden 14x14'e iner. Daha az piksel demek ağ için daha az iş demek.
# Ag resim zad gormur reqem gorur . Her pikseli  0 ve 1 arasinda sayiya donusdurur . 0 qara 1 ag
# Tek sefer de 64 lu grup halinda verir sekilleri . 64 resme baxib texmin edir ve agirliqlari ona gore duzeldir .
# 70000 nin 10000 i test 60000 train ucundur 

# Train ve quantitize n feed i bu file dir .
