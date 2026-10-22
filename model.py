import torch.nn as nn


def make_model():
    return nn.Sequential(
        nn.Flatten(),
        nn.Linear(196, 16),
        nn.ReLU(),
        nn.Linear(16, 10),
    )
#  Flatten ile 14x14 matrisi , tek list edib 196 itemli eder 
# Linear birinci qatman 196  giris 16 neyron var . Her neyronun 196 agirligi ve 1 biasi var. Yeni 16*1 = 16 bias 
#  Relu 16 dan - olanlari 0 a cekir .
# Linear ikinci layer 16 giris 10 neyron . 160 agirlig + 10 bias  = 170 

#196*16 + 16*10 +10 +16 = 3322 .

# 16 noron  = 16 tane hesaplama kriteeri 