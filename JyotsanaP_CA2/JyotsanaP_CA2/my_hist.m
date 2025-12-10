function h=my_hist(x,N)

xmin=1;
xmax=N;
L=xmax-xmin+1;
h=zeros(1,L);

for i=xmin:xmax
   h(i-xmin+1)=sum(sum(x==i));
end
