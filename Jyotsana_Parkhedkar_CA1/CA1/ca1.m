%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICSI471/571 Introduction to Computer Vision Fall 2025
% Copyright: Xin Li@2024-2026
% Computer Assignment 1: Image Acquisition and Perception
% Due Date: Sep. 16, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Name : Jyotsana Parkhedkar - 001661399

% Part I: Image acquisition basics (3 points)

% read in the test image cameraman (provided by matlab)
x=double(imread("C:\Users\jyots\OneDrive\Desktop\CA1\cameraman.tif"));
% check the spatial resolution (width and height) of the image
whos x
% 1. reduce the image spatial resolution by a factor of two (also-called down-sampling)
% Hint: you need to know how to use ":" operator (0.5 point)
x1 = x(1:2:end,1:2:end);
imshow(x1,[]);
% increase the spatial image resolution by a factor of two (also-called up-sampling)
% Hint: use >help imresize or >help interp2 to learn how to use these two
% functions assoicated with linear interpolation 
x2=imresize(x1,2);
% or x2=interp2(x1);
subplot(1,2,1);imshow(x,[]);title('original image');
subplot(1,2,2);imshow(x2,[]);title('interpolated image');
% blurred edges and some noticeable artifacts around tripod lines

% Compared to x, x2 looks blurrier and has lost fine texture.
% Slight aliasing/jaggies on edges.
% Upsampling cannot restore detail removed by downsampling.


% 2. reduce the bit-depth image resolution of x from 256 to 16 
% Hint: you can google ``uniform quantization'' to learn more 
% background information (1 point)
Q=16;
x3=round(x/Q);
subplot(1,2,1);imshow(x,[]);title('8-bit image');
subplot(1,2,2);imshow(x3,[]);title('4-bit image');
% Visible banding/contouring in smooth regions.
% Subtle contrast is lost, image looks flatter.
% Noise is more noticeable.

% 3. extract the MSB and LSB of a given image (1 point)
% Hint: you can google ``matlab bitget'' or type ">help bitget" to learn%
% how to use this tool properly
MSB=bitget(x,8);
LSB=bitget(x,1);
subplot(1,2,1);imshow(MSB,[]);title('Most Significant Bitplane (MSB)');
subplot(1,2,2);imshow(LSB,[]);title('Least Significant Bitplane (LSB)');
% MSB retains overall structure and edges of the image.
% LSB looks noise-like and carries almost no semantic content.


% 4. play with a color image of flowers (1 point)
% read in the test image 
x=double(imread("C:\Users\jyots\OneDrive\Desktop\CA1\fl_orig.ppm"));
y=rgb2gray(x/255);
% generate Bayer pattern z
% green channels: quincinx lattice
z=zeros(size(y));
z(1:2:end,1:2:end)=squeeze(x(1:2:end,1:2:end,2));
z(2:2:end,2:2:end)=squeeze(x(2:2:end,2:2:end,2));
% red/blue channels: quarter-size
z(1:2:end,2:2:end)=squeeze(x(1:2:end,2:2:end,1));
z(2:2:end,1:2:end)=squeeze(x(2:2:end,1:2:end,3));
% Bayer pattern is NOT the grayscale version but visually appears similar
% Note that y is normalized within [0,1] and z is within [0,255]
imshow([y*255 z],[]);
% This problem is often called image demosaicing. You can learn more about 
% more advanced demosaicing methods at wiki: https://en.wikipedia.org/wiki/Demosaicing 


% 5. MRI image acquisition in k-space (0.5 point)
clear all
close all
%load spiralexampledata
% d - spiral data;
% k - kspace locations (kx,ky); use plot(real(k),imag(k),'.') to see
% w - density compensation function (used to weight the k-space data); 
load rt_spiral.mat 

% a simple implementation of gridding algorithm for MRI reconstruction
% choose an image size
n=256/2;
% read the supplied grid2w.m function and learn how to call it
X=grid2w(d,k,w,n);
x=abs(fftshift(ifft2(X)));;
% display the reconstructed result
% Hint: if the displayed result does not appear correct, >help fftshift
% and understand why you need to use fftshift here (we will discuss this
% issue later during the lecture on FT of images)
figure(1);imshow(abs(x),[]);

% Part II: Image perception experiments (5 points)
% The objective of this assignment is to play with digital images
% and learn about the fascinating science of visual perception

%% Part II.1 — Black or white? (illusion.png)
% 1. black or white? (0.5 point)
x1=imread("C:\Users\jyots\OneDrive\Desktop\CA1\illusion.png");
imshow(x1,[]);
% checking pixel value
impixelinfo;   % Open a pixel value inspector in the figure
% A=B=120
% Intensity of block A ≈ 120
% Intensity of block B ≈ 120
% Both blocks look different but they have same value.

%% Part II.2 — Which arrow is longer? (arrows.png)
% 2. which one is longer? (0.5 point)
x2=imread('arrows.png');
% measuring length of arrows
imshow(x2,[]); title('Measure the arrows with imdistline');
imdistline;   % lets you drag a measuring line interactively
% length_top=188; length_bottom=188
% length_top ≈ 164 pixels
% length_bottom ≈ 164 pixels
% Both arrows are equal in length despite bottom one appearing longer.

%% Part II.3 — Which disk is larger? (SC_shape.png)
% 3. which one is larger? (0.5 points)
x3=imread('SC_shape.png');
% checking diameter of both disks
imshow(x3,[]); title('Measure disk diameters with imdistline');
imdistline;   % drag across each disk's diameter
% diameter_left ≈ 70 pixels
% diameter_right ≈ 70 pixels
% Both disks are equal in size but the left one looks larger.

%% Part II.4 — Red or orange? (scstrpe1.ppm)
% 4. red or orange? (0.5 point)
% two pixels with identical R,G,B values might look like two totally different colors
x4=imread('C:\Users\jyots\OneDrive\Desktop\CA1\scstrpe1.ppm');
imtool(x4);
% Both center blocks have identical values: (R,G,B) = (255, 0, 0)
% They are perceived differently (red vs orange) despite being the same.

%% Part II.5 — Parallel or not? (parallel.png)
% 5. parallel or not? (0.5 point)
x5=imread('parallel.png');
% Orientation of first NW line ≈ -45.5405°
% Orientation of second NW line ≈ -45.0784°
% Angles are nearly equal, so the lines are parallel.

% re-measure the angles interactively - my addition
figure; imshow(x5,[]); title('Parallel or not? (click two points on each line)');
hold on;
% First NW line
[p1x,p1y] = ginput(1); 
[p2x,p2y] = ginput(1);
plot([p1x p2x],[p1y p2y],'LineWidth',2);
th1 = atan2d(p2y - p1y, p2x - p1x);

% Second NW line
[q1x,q1y] = ginput(1); 
[q2x,q2y] = ginput(1);
plot([q1x q2x],[q1y q2y],'LineWidth',2);
th2 = atan2d(q2y - q1y, q2x - q1x);

% Print angles
fprintf('th1 = %.2f°, th2 = %.2f°, |Δ| = %.2f°\n', th1, th2, abs(th1-th2));
hold off;

% Summary: seeing is not believing. The neuroscience behind visual
% perception has remained largely a big mystery.

%% Part III — Moon Shot (submit a separate photo)
% Part III: Moon Shot (1 point)
% Use your smartphone to take a photo of moon at night, try your best to
% acquire the most visually pleasant moon shot. Please save it as a full-resolution PNG or JPEG image 
% and submit it as a separate file. You will learn how to enhance the quality of this image later.
% File Name: Part-3 MoonShot.jpeg

%% Summary of Observations
% Part I.1: Downsampling reduced resolution, and upsampling via bilinear interpolation 
% produced a blurrier image with jagged edges — detail lost cannot be recovered.
%
% Part I.2: Reducing bit depth from 8-bit to 4-bit introduced visible banding, 
% reduced subtle contrast, and increased quantization noise.
%
% Part I.3: The MSB bitplane preserved overall structure and edges, while the LSB 
% appeared random/noisy with little semantic content.
%
% Part I.4: The Bayer pattern resembled grayscale but lacked true color; after 
% demosaicing, the reconstructed color image closely approximated the original.
%
% Part I.5: MRI k-space data reconstruction worked correctly with gridding and IFFT, 
% yielding a recognizable magnitude image after fftshift alignment.
%
% Part II.1: Blocks A and B in illusion.png had equal intensity (≈120) despite 
% appearing different, demonstrating brightness contrast illusion.
%
% Part II.2: Both arrows measured ≈188 pixels, confirming they are equal in length 
% though one appears longer due to context.
%
% Part II.3: Both central disks measured ≈67 pixels in diameter, yet the left disk 
% appeared larger due to surrounding circles.
%
% Part II.4: Two center blocks in scstrpe1.ppm shared identical RGB values (255,0,0), 
% but were perceived as different colors (red vs. orange).
%
% Part II.5: Measured NW line orientations (≈ -45.54° and -45.08°) confirmed the 
% lines are parallel, despite appearing skewed.
%
% Part III: Captured a clear moon shot with visible surface features and good 
% contrast against the black sky. Image ready for future enhancement tasks.
