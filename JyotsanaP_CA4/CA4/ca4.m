%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICSI471/571 Introduction to Computer Vision Fall 2025
% Copyright: Xin Li@2024-2026
% Computer Assignment 4: Image Denoising
% Due Date: Oct. 7, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% General instructions: 
% 1. Wherever you see a pair of <...>, you need to replace <>
% by the MATLAB code you come up with
% 2. Wherever you see a pair of [...], you need to write a new MATLAB
% function with the specified syntax
% 3. Wherever you see a pair of {...}, you need to write your answers as
% MATLAB annotations, i.e., starting with %

% The objective of this assignment is to learn the application of 
% FT/PDE into image deblurring/segmentation especially the restoration of astronomical
% images and photographic images
% MATLAB functions: fitsread, deconvwnr/deconvlucy, psf2otf/otf2psf  

% Part I: Image denoising experiments (3 points)

% 1. salt-and-pepper noise (1 point)
x=double(imread('eight.tif'));
% learn how to use imnoise function to add salt-and-pepper noise to an
% image
y=<contaminate image x by salt-pepper noise with p=0.2>;
% verify you have got the noisy image right
% the answer should be around 0.8
mean2(x==y)
% apply median filtering to the noisy image
x1=<apply median filtering to noisy image y>;
[you are asked to write a new MATLAB function called medfilt2_nd.m which
implements the median filtering with noise detection (refer to PPT slide #24)]
x2=medfilt2_nd(y);
<compare denoised images x1 and x2 side-by-side>

% 2. additive white Gaussian noise (1 point)
x=double(imread('rays.png'));
% learn how to use imnoise or randn function to add additive white Gaussian noise to an image 
% hint: you might find imnoise is more clumsy to use than randn for this
% part (i.e., to reach the noise power specified by its variance)
y=<contaminate image x by additive white Gaussian noise with sigma=20>;
% verify you have got the noisy image right
% the answer should be around 400
var(x(:)-y(:))
% apply Gaussian filtering to the noisy image
% use >help fpsecial to learn how to create a Gaussian kernel
% use >help imfilter to learn how to apply image filtering with a spcificed
% kernel
f=<a 2D 9-by-9 Gaussian kernel with sigma: sigma is at your own choice>;
x1=<apply Gaussian filtering to noisy image y>;
% you are given a nonlinear image filtering function called tv.m (TV stands for total-variation)
% learn how to use this function (no more programming is needed)
x2=<apply Total-Variation filtering to the noisy image y for n times: n is at your own choice>;
% Note: You might choose to manually optimize the choice of sigma or n in
% this assignment; but more generally it is an optimization problem - i.e.,
% how do we automatically choose the parameter of an image processing
% algorithm. If you want to dig deeper, you might come up with an algorithm
% to automatically stop the TV iteration without user interference.
% Warning: you will need to work with double format to have correct
% answers for MSE - uint8 tends to produce smaller but wrong MSE results.
<compare the MSE of images x1 and x2: i.e., ||x-x1|| and ||x-x2||>


% 3 simulated periodic noise (1 point)
load periodic_noise.mat
[you are asked to write a new MATLAB function called notch_filter.m which
implements the notch filtering (refer to PPT slide #57)]
R=<you need to decide the radius of notch filter circular support>;
x3=notch_filter(y,R);
<compare the damaged and denoised images y and x3 side-by-side>


% Part 2: Image filtering/transform experiments (3 points)

% 1. 2D convolution (1 point)
x1=double(imread('monroe.bmp'));
[M,N]=size(x1);
% you can directly do 2D convolution in spatial domain
% by call function conv2
% specify a linear motion blurring kernel
h = fspecial('motion',20,45);
y1=<convolution of x and h>;
% verify you have got a motion-blurred image
% along the diagonal direction (45-degree)
imshow(y1,[]);
% now let us see how to implement 2D convolution
% by FFT method (for images, we use fft2)
% for image, we do not need to specify dimension
X1=<apply fft2 to image x>;
% for kernel, you can specify the size of FT by
% using FFT2(X,MROWS,NCOLS)
H=<apply fft2 with size M-by-N to kernel h>;
{Why do we need to specify the size of Fourier Transform
    here?}
% spatial-domain convolution is equivalent to frequency-domain product
Z1=X1.*H;
z1=ifft2(Z1);
% verify it does look like y (the result of direct-convolution)
imshow(abs(z1),[]);


% 2. 2D FFT vs. DCT (1 point)
x2=double(imread('einstein.bmp'));
% learn how to display the 2D FFT of an image
% with proper arrangement of frequency band
% >help fftshift
X2=fftshift(fft2(x2));
imshow(abs(X2),[]);
{where is the low-frequency region in X2?}
% learn how to apply 2D discrete cosine transform to an image
% > help dct2
Y2=dct2(x2);
imshow(Y2,[]);
{where is the low-frequency region in Y2?}
% the following calculation verifies so-called Parseval's identify
% which says the energy is preserved after FT or DCT
sum(sum(x2.*x2))
sum(sum(abs(X2).^2))/(M*N)
sum(sum(Y2.*Y2))

% 3. Low-pass and High-pass filter (1 point)    
% This part attempts to create an einstein-monroe illusion
% like what you have seen in intro.zip (marilyneinstein.jpg) by playing with
% low-pass and high-pass filters.
x1m=<apply a low-pass filter to x1>;
% Hint: all-pass=low-pass+high-pass
x2m=<apply a high-pass filter to x2>;
x12=(x1m+x2m)/2;
% Does it look like einstein at a close distance and monroe at a far
% distance? If not, what could be the reasons? The bonus part of this CA
% will supply a better tool for creating the desired illusion.
<display the mixed image x12>

% Bonus part: Einstein or Monroe? (1 point)
x=imread('marilyneinstein.jpg');
% Is this a picture of Albert Einstein? Yes. But wait - look at it far away
% Do you see Marillyne Monroe now? That is strange!!!
imshow(x,[]);
% can you separate the image of Einstein from that of Monroe?
% Hint: roughly speaking, we want to separate spatially high-frequency from low-frequency
% Please do not try too hard on this one because it is still an open research problem.
% Demonstrating partial success is sufficient for meriting the bonus half-point.
{create two images from x - one looks more like Einstein and the other more like Monroe}