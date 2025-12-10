function y=linear_diffusion(x,n)

f=[0 -1 0;-1 4 -1;0 -1 0];
a=0.125;y=x;
for i=1:n
   y=y-a*filter2(f,y);
end

%y(L-11:L)=y(L-22:L-11);


