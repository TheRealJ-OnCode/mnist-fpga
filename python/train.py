import torch
import torch.nn as nn
import torch.nn.functional as F

from data import load

x_train, y_train, x_test, y_test = load()
print(x_train.shape, x_train.min(), x_train.max())
print(x_test.shape)


x_train_f = x_train.float() / 255
x_test_f = x_test.float() / 255

torch.manual_seed(0) #her seferinde eyni randomluqla calisdirsin deyedir 
model = nn.Sequential(nn.Linear(196, 16), nn.ReLU(), nn.Linear(16, 10))
loss_fn = nn.CrossEntropyLoss()
optimizer = torch.optim.SGD(model.parameters(), lr=0.1)

for epoch in range(10):  # 10 defe ustunden kec
    perm = torch.randperm(60000)  # random duzur , her epochta resimler ferqli sirayla
    for i in range(0, 60000, 64):  # 64luk parcalara bol
        idx = perm[i : i + 64]
        xb, yb = x_train_f[idx], y_train[idx]  # etiketlerini destruct ele

        scores = model(xb)  # texminine bax
        loss = loss_fn(scores, yb)  # Xeta payi , E= (Y-T)^2 (cross-entropy) ,mentiq eynidir , eyni formula deyil 
        optimizer.zero_grad()  # Evvelki adimin toremelrini silmek mecburiyetindeyem !!!!
        loss.backward()
        optimizer.step()
    with torch.no_grad():
        acc = (model(x_test_f).argmax(1) == y_test).float().mean()
    print(f"epoch {epoch}  loss {loss.item():.3f}  test acc {acc.item():.4f}")
torch.save(model.state_dict(), "model_float.pt")
