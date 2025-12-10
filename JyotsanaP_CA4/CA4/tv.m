% tv.m - Total-Variation denoising

function ZN = tv(ZN,iterate);

[m,n] = size(ZN);
lambda = 0.250;

for i = 1:iterate, 
   ZN=ZN+lambda*div_grad_vese(ZN, 1, 0.0001); 
end