x=double(imread('microarray.png'));
% >help histeq
x_enh1= histeq(x/255);
imshow(x_enh1,[]);
% >help adapthisteq
x_enh2=adapthisteq(x/255);
imshow(x_enh2,[]);


