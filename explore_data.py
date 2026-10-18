# libs
import torch.nn.functional as F;
from torchvision import datasets, transforms;
#  //!
train_set = datasets.MNIST(root="data", train=True, download=True, transform=transforms.ToTensor());
print(len(train_set));
image, label = train_set[0];
print("label:", label);
print("shape:", image.shape);
print("min:", image.min().item(), "max:", image.max().item());
def  draw(pixels):
    for row in pixels:
        line = ""
        for value in row:
                chars = " .:-=+*#%@"
                line += chars[int(value * 9)] * 2
        print(line)
small = F.avg_pool2d(image, kernel_size=2)
print("small shape:", small.shape)
draw(image[0])
draw(small[0])