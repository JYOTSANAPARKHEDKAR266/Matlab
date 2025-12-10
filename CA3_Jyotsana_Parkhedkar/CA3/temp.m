% 1. salt-and-pepper noise (2 points)
x=double(imread('eight.tif'));
% learn how to use imnoise function to add salt-and-pepper noise to an
% image
density = 0.05; % desired density of the noise
y=imnoise(x/255, 'salt & pepper', density)*255;
% verify you have got the noisy image right
% the answer should be around 0.8
mean2(x==y)
% apply median filtering to the noisy image
x1=medfilt2(y);
%[you are asked to write a new MATLAB function called medfilt2_nd.m which
%implements the median filtering with noise detection (refer to PPT slide #24)]
x2=medfilt2_nd(y);
%<compare denoised images x1 and x2 side-by-side>
figure;
subplot(1, 3, 1); imshow(uint8(x)); title('OG Image');
subplot(1, 3, 2); imshow(uint8(x1)); title('MATLAB Med Filter');
subplot(1, 3, 3); imshow(uint8(x2)); title('My Med Filter');
% Define my medfilt2 function (medfilt2_nd)
function output = medfilt2_nd(input)
% Check if the pixel is affected by salt-and-pepper noise
[rows, cols] = size(input);
output = input;
for i = 2:rows-1
for j = 2:cols-1
if input(i,j) == 0 || input(i,j) == 255
% Apply median filtering if the pixel is noisy
window = input(i-1:i+1, j-1:j+1);
output(i,j) = median(window(:));
end
end
end
end
