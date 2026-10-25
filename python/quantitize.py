import torch
from data import load 

# x ->pikseldi 
# z1 -> dedektor xam toplam
# h1 ->Relu sonrasi
# h1_q -> 8 bit versiya quantitzed
# z2 -> rakam puanlari 

sd = torch.load('model_float.pt')
W1,b1 =  sd['0.weight'], sd['0.bias']
W2,b2 =  sd['2.weight'], sd['2.bias']

s_w1 = 127 /W1.abs().max() #carpim
W1_q = torch.round(W1*s_w1).long() #carpim katsayisi
b1_q = torch.round(b1*s_w1*255).long() #Bias hesabi , gorek bias nece defe artmali oalcaq deye 

print('s_w1 :', s_w1.item())
print('W1_q :', W1_q.min().item(), '...', W1_q.max().item())
print('b1_q :', b1_q.tolist())  

x_train , y_train,x_test,y_test  = load()
z1_int =  x_train @ W1_q.T + b1_q
z1_float =  (x_train.float() / 255) @ W1.T + b1

extraction  = (z1_int / (s_w1*255)  - z1_float ).abs().max()
print('En boyu ferq :', extraction.item())
print('Z1 ARALIGI:', z1_int.min().item(), '...', z1_int.max().item())


# max 274371 bu cixdi 
# 274371 / 255 = 1075.96470588 => 2ustu 10 dan boyukdur , 2 ustu 11 yeterlidir 

h1 =  torch.relu(z1_int)  #relu + max(0,z) in eynisi menfileri vurduq  
m = h1.max().item()   #60000*16 iciinden en boyuyu tapir 

k = 0

while (m >> k) > 255:
    k+=1
h1_q = torch.clamp(h1 >> k , max =255)   # 255 den boyukdurse limitleyecek 255 le , deyilse saxlayacaq 
print('k    :', k)
print('h1_q :', h1_q.min().item(), '...', h1_q.max().item())

# b2_q = round(b2 x agirliq x girdi)
s_w2 = 127 / W2.abs().max()
# print(s_w2.item())  
# 50.36942672729492
s_h  = s_w1 * 255 / 2**k#2.katmanin girdisi
W2_q = torch.round(W2 * s_w2).long() 
b2_q = torch.round(b2 * s_w2 * s_h).long()   #agirlik * girdi 
print('W2_q :', W2_q.min().item(), '...', W2_q.max().item())
print('b2_q :', b2_q.tolist())


# 2 modeli qarsilasidrib baxmacam gorum ne qeder ferqimiz var modeller arasinda

def int_model (x):
    z1 = x @W1_q.T + b1_q
    h1   = torch.relu(z1)  
    h1_q = torch.clamp(h1>>k ,max = 255)
    z2  = h1_q @ W2_q.T +b2_q
    return z2.argmax(1)

def float_model (x):
    h = torch.relu((x.float()  / 255) @ W1.T + b1)
    return (h @ W2.T + b2).argmax(1) 
    
p_int   = int_model(x_test)
p_float = float_model(x_test)


print('float :', (p_float == y_test).float().mean().item())
print('int :', (p_int   == y_test).float().mean().item())
print('precentage :', (p_int == p_float).sum().item(), '/ 10000')



#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#???????????????????????????????????????????
#*0.03 luk bir loss var . Okeydi 


def to_bin(v, bits):
    return format(v & ((1 << bits) - 1), f'0{bits}b')

def write(path, values, bits):
    with open(path, 'w') as f:
        for v in values:
            f.write(to_bin(int(v), bits) + '\n')

N = 500   #test sekil sayi

weights = torch.cat([W1_q.flatten(), W2_q.flatten()])   # ROM sirasidi bura
biases  = torch.cat([b1_q, b2_q])

# guvenlik kontrollari , CLAUDE ADVICE 
assert len(weights) == 3296
assert weights.min() >= -128 and weights.max() <= 127
assert biases.abs().max() < 2**23

write('weights.txt',  weights,             8)
write('biases.txt',   biases,             24)
write('images.txt',   x_test[:N].flatten(), 8)
write('expected.txt', p_int[:N],           4)

print('k =', k)
# print(W1_q[0, :3].tolist()) #yoxlayaq eyniliyi
