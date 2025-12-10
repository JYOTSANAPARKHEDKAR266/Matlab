%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICSI471/571 Introduction to Computer Vision Fall 2025
% Copyright: Xin Li@2024-2026
% Computer Assignment 5: Image Deblurring and Midterm Practice
% Due Date: Oct. 14, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% General instructions: 
% 1. Wherever you see a pair of <...>, you need to replace <>
% by the MATLAB code you come up with
% 2. Wherever you see a pair of [...], you need to write a new MATLAB
% function with the specified syntax
% 3. Wherever you see a pair of {...}, you need to write your answers as
% MATLAB annotations, i.e., starting with %

% The objective of this assignment is to play with various image
% interpolation related MATLAB functions (easy and fun)
% MATLAB functions: hist, histeq, adapthisteq, imadjust, imhist  

% Part I: Image deblurring experiments (3 points)
% 1. Simulated Experiment of Image Blurring (1 point)
x1=double(imread('saturn.jpg'));
% crop out the saturn region 
x1=x1(101:200,51:350);
[M,N]=size(x1);
% specify a uniform 9-by-9 blurring kernel
psf = fspecial('gaussian',9,2);
% optical transfer function (otf) is the FT of point-spread function (psf)
otf  = psf2otf(psf,[31 31]); % PSF --> OTF
subplot(1,2,1); surf(psf); title('PSF');
axis square; axis tight
% otf of a uniform blur is a 2D sinc function
subplot(1,2,2); surf(fftshift(abs(otf))); title('corresponding |OTF|');
axis square; axis tight
       
% 2. artificially generate the blurred image (1 point)
y1=imfilter(x1,psf,'symmetric');
% visually inspect the blurred image
imshow(y1,[]);
% now let us see how inverse filtering method works
Y1=<apply fft2 to image y1>;
% for kernel, you can specify the size of FT by
% using FFT2(X,MROWS,NCOLS)
H=<apply fft2 with size M-by-N to the blurring kernel psf>;
% inver filtering in the frequency domain
Z1=Y1./H;
z1=abs(ifft2(Z1));
% verify it does look like x1 - the original image
subplot(1,2,1);imshow(x1,[]);
subplot(1,2,2);imshow(z1,[]);
% Now we will repeat the above experiment for a noisy blurred image
% Note that the amount of noise is very small
sigma=1;
y2=imfilter(x1,psf,'symmetric')+randn(size(x1))*sigma;
% Visually no difference between y1 and y2
imshow([y1 y2],[]);

[Write a new MATLAB function inverse_filtering.m to implement the 
procedures of Lines 42-48.]
z2=inverse_filtering(y2,psf);
subplot(1,2,1);imshow(z1,[]);
subplot(1,2,2);imshow(z2,[]);
{Explain why image information in z2 is totially destroyed.}

% 3. Deblur real-world image with optical blur (1 point)
% use >help fitsread to learn how to handle .FITS image
y=<read image data ClockB.fit into matlab>;
psf=<read psf data ClockPSF.fit into matlab>;
% use >help deconvlucy to learn how to deblur an image with given psf
x=<deconvoluted clock image by Lucy-Richardson algorithm>;
imshow(x,[]);


% Part 2: Practice Problems for the Midterm Exam (3 points)

% Problem 1: find out the total number of pixels whose intensity values are 
% in the range of [50,200] for a given image (1/2 point)
x=imread('moon.tif');
total_number_of_pixels_between_50_and_200=<your answer enters here>;

% Problem 2: find the size difference (in terms of # of pixels) of dark and bright circles in the given image(1/2 point) 
x=imread('circlesBrightDark.png');
size_difference_of_bright_and_dark_circles=<your answer enters here>;

% Problem 3: estimate the size of green leaves (in terms of number of pixels) in the given image (1/2 point)
% Hint: Matlab also provides an image of segmentation map called
% ``yellowlily-segmented.png'' (you don't have to use this image if you opt tp directly work with the original .JPG image).
x=imread('yellowlily.jpg');
leaves_size_estimation=<your answer enters here>;

% Problem 4: estimate the total area of threads (in terms of number of pixels) in the given image (1/2 point)
x=imread('threads.png');
total_threads_area=<your answer enters here>; 

% Problem 5: estimate the angle of moon shadow in the given image (in terms of degrees) (1/2 point)
% Note that the angle is defined with respect to the horizontal line (the row direction).
x=imread('moon.tif');imtool(x);
shadow_angle=<your answer enters here>

% Problem 6: solve image jigsaw puzzle
% You are given a shuffled license plate image. Shuffle it back under
% Matlab
x=imread('plate_shuffled.png');imhsow(x);
<your codes enter here>
<display the unshuffled image to check its validity>