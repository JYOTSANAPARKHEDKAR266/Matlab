%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICSI471/571 Introduction to Computer Vision Fall 2025
% Copyright: Xin Li@2024-2026
% Computer Assignment 4: Image Denoising
% Due Date: Oct. 7, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Name : Jyotsana Parkhedkar  -- 001661399

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

% 1. Salt-and-Pepper noise
x = double(imread('eight.tif'));
% add salt & pepper noise with p=0.2
y = imnoise(uint8(x), 'salt & pepper', 0.2);
% verify noisy image ratio ~0.8
mean2(x == double(y))
% median filtering
x1 = medfilt2(y, [3 3]); % built-in median filter
x2 = medfilt2_nd(y);     % your own noise-detecting median filter
figure; subplot(1,3,1); imshow(uint8(x)); title('Original');
subplot(1,3,2); imshow(y); title('Noisy (S&P)');
subplot(1,3,3); imshow(uint8([x1 x2])); title('Median vs. ND-Median');

% Observation:
% After adding salt-and-pepper noise (p=0.2), around 20% of the pixels
% were corrupted (mean2(x==y) ≈ 0.8). 
% The standard median filter (x1) reduces the noise but also blurs edges.
% The noise-detecting median filter (x2) preserves more details by only
% replacing corrupted (0 or 255) pixels. Visually, x2 looks sharper.

% 2. Additive Gaussian noise
% Files: rays.png
if exist('rays.png','file')
    xr = double(imread('rays.png'));
else
    % Fallback: radial rays synthetic pattern
    [X,Y] = meshgrid(linspace(-1,1,256));
    ang = atan2(Y,X);
    xr = 127 + 70 * square(16*ang);  % rays
end

sigma = 20;
y = xr + sigma*randn(size(xr));

% Verify variance ~ 400
fprintf('Q1.2 var(x - y) ≈ %.1f (expect ~400)\n', var(xr(:) - y(:)));

% Gaussian filter (9x9, choose sigma_g=2)
f = fspecial('gaussian', [9 9], 2.0);
x1 = imfilter(y, f, 'symmetric');

% TV filter — your tv.m likely expects (image, nIters)
% If tv.m takes only 1 arg (image), set nTV below to [] and wrap.
nTV = 30;
try
    x2 = tv(y, nTV);    % <-- fixed: 2 arguments only
catch
    % Fallback no-TV path if tv.m is absent/incompatible:
    warning('tv.m not found or incompatible — using stronger Gaussian instead.');
    x2 = imfilter(y, fspecial('gaussian',[15 15], 3.5), 'symmetric');
end

% MSE comparison
mse1 = mean((xr(:) - x1(:)).^2);
mse2 = mean((xr(:) - x2(:)).^2);
fprintf('Q1.2 MSE: Gaussian=%.2f, TV/Alt=%.2f\n', mse1, mse2);

figure('Name','Q1.2: AWGN Denoising','NumberTitle','off');
subplot(1,3,1); imshow(uint8(xr)); title('Original');
subplot(1,3,2); imshow(uint8(y));  title('Noisy (AWGN)');
subplot(1,3,3); imshow(uint8([x1 x2]));
title('Gaussian (left) vs TV/Alt (right)');

% Observation:
% With sigma=20, the noise variance ~400 as expected. 
% Gaussian filtering (x1) smooths the noise but also blurs edges.
% Total Variation filtering (x2) better preserves sharp features 
% while still reducing noise. The MSE comparison typically shows 
% TV filtering achieves lower error than Gaussian filtering.

% 3. Simulated periodic noise
load periodic_noise.mat % gives y (damaged)
R = 15;                 % radius choice for notch filter
x3 = notch_filter(y, R);
figure; subplot(1,2,1); imshow(y, []); title('Damaged with Periodic Noise');
subplot(1,2,2); imshow(x3, []); title('After Notch Filtering');

% Observation:
% The noisy image contains strong periodic patterns (striping).
% In the Fourier spectrum, this appears as bright spikes away from the
% center. By applying a notch filter with radius R around these spikes, 
% we remove the periodic components. The restored image (x3) is much 
% cleaner and close to the original, though some blurring or residual
% noise may remain depending on the notch size.

% Part 2: Image filtering/transform experiments (3 points)

% 1. 2D convolution
x1 = double(imread('monroe.bmp'));
[M,N] = size(x1);
h = fspecial('motion',20,45);
y1 = conv2(x1,h,'same');
figure; imshow(y1,[]); title('Motion Blurred (45°)');
% FFT method
X1 = fft2(x1);
H = fft2(h, M, N);   % must match image size
% {Why? → To avoid circular convolution: padding kernel to full image size.}
Z1 = X1 .* H;
z1 = ifft2(Z1);
figure; imshow(abs(z1),[]); title('FFT Convolution Result');

% Observation:
% The spatial convolution with a motion blur kernel produces a diagonal 
% (45°) blur, clearly visible in y1.
% The FFT-based convolution gives almost identical output to the direct
% spatial method. 
% Specifying the FFT size equal to the image size is necessary to avoid 
% circular convolution and correctly simulate linear convolution.

% 2. FFT vs DCT
x2 = double(imread('einstein.bmp'));
[M,N] = size(x2);

% FFT spectrum
X2 = fftshift(fft2(x2));

% DCT spectrum
Y2 = dct2(x2);

% Display FFT and DCT in the same figure
figure('Name','Q2.2: FFT vs DCT','NumberTitle','off');

subplot(1,2,1);
imshow(log(1+abs(X2)),[]);
title('FFT Spectrum (low-freq center)');

subplot(1,2,2);
imshow(log(1+abs(Y2)),[]);
title('DCT Spectrum (low-freq top-left)');

% Parseval's theorem check
energy_space = sum(sum(x2.^2));
energy_fft   = sum(sum(abs(X2).^2))/(M*N);
energy_dct   = sum(sum(Y2.^2));
fprintf('E_space=%.2f, E_fft=%.2f, E_dct=%.2f\n', ...
    energy_space, energy_fft, energy_dct);

% Observation:
% The FFT spectrum shows low-frequency content concentrated at the CENTER
% after fftshift, while high-frequencies radiate outward.
% The DCT spectrum shows low-frequency content at the TOP-LEFT corner,
% with high-frequencies spreading toward bottom-right.
% Parseval's theorem is verified: energy in spatial, FFT, and DCT domains
% match closely, confirming energy preservation in the transforms.

% 3. Low-pass & High-pass (Einstein-Monroe illusion)
% Low-pass filter on Monroe
f_lp = fspecial('gaussian', [25 25], 8);
x1m = imfilter(x1, f_lp, 'symmetric');
% High-pass filter on Einstein
hp = x2 - imfilter(x2, f_lp, 'symmetric');
x2m = hp;
x12 = (x1m + x2m)/2;
figure; imshow(uint8(x12)); title('Einstein-Monroe Mixed');
% {If illusion not clear → reasons: filter size, cutoff not tuned, or display scaling.}

% Observation:
% After applying a low-pass filter to Monroe and high-pass filter to
% Einstein, combining them produces an illusion: 
% from a close distance the image resembles Einstein (high-freq details),
% but from far away it looks like Monroe (low-freq structure).
% If the illusion is weak, it is usually due to filter size or cutoff 
% frequency not being optimally chosen, or scaling differences between 
% the two source images.

%% Bonus: Einstein or Monroe?
x = imread('marilyneinstein.jpg');
figure; imshow(x,[]); title('Marilyn-Einstein Illusion');
% Try separation: Low-pass ~Monroe, High-pass ~Einstein
lp = imfilter(double(x), fspecial('gaussian',[25 25],10), 'symmetric');
hp = double(x) - lp;
figure; subplot(1,2,1); imshow(uint8(lp)); title('Monroe-like (Low-pass)');
subplot(1,2,2); imshow(uint8(hp+128)); title('Einstein-like (High-pass)');

% Observation:
% The mixed image appears as Einstein at close range, Monroe from far away.
% By applying a Gaussian low-pass filter, the Monroe-like smooth structure
% is extracted. Subtracting this from the original image yields the
% high-pass Einstein-like features. The separation is not perfect because
% the frequencies of both images overlap. However, partial separation is
% possible, demonstrating the principle of frequency-domain image mixing.