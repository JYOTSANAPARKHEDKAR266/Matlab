%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICSI471/571 Introduction to Computer Vision Fall 2025
% Copyright: Xin Li@2024-2026
% Computer Assignment 3: Image Enhancement
% Due Date: Sep. 30, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Name : Jyotsana Parkhedkar   --   001661399


% General instructions: 
% 1. Wherever you see a pair of <...>, you need to replace <>
% by the MATLAB code you come up with
% 2. Wherever you see a pair of [...], you need to write a new MATLAB
% function with the specified syntax
% 3. Wherever you see a pair of {...}, you need to write your answers as
% MATLAB annotations, i.e., starting with %

% The objective of this assignment is to play with various image
% filtering and transform related MATLAB functions and feel about the difference
% between linear and nonlinear filters.
% MATLAB functions: hit, imhist, histeq, adapthisteq, localcontrast, imsharpen 


%% Part 1: Histogram-based image enhancement experiments (6 points)

%% 1. calculate the histogram of a given image (2 points)

% Read the image
x = imread('cube.tif');     % grayscale 8-bit image

% Custom histogram
h_x = my_hist(x, 256);

% MATLAB's reference histogram
h_ref = hist(double(x(:)), 0:255);

% Display side-by-side
figure('Name','Histogram comparison','NumberTitle','off');

subplot(1,2,1);
bar(0:255, h_x, 'BarWidth', 1);
title('my\_hist (0..255)');
xlabel('Intensity'); ylabel('Count'); xlim([0 255]);

subplot(1,2,2);
bar(0:255, h_ref, 'BarWidth', 1);
title('MATLAB hist (0..255)');
xlabel('Intensity'); ylabel('Count'); xlim([0 255]);

% {do they look similar?}
% {Yes. They are nearly identical up to bin-edge/centering conventions.
%  my_hist bins exactly at integer intensities 0..255, while hist uses bin centers at 1..256.
%  Any tiny differences are due to these conventions, not the underlying counts.}

% Observations (Q1):
% - The histogram produced by my_hist is almost identical to MATLAB's hist.
% - Both show the same intensity distribution: a dominant spike near ~150
%   (the cube image's main gray level) with smaller peaks around higher values.
% - This confirms that the custom my_hist function is correct.
% - Any tiny differences are due to binning conventions (0–255 vs 1–256 centers).


%% 2. enhancement of a microarray image (2 points)
x = double(imread('microarray.png'));  % assume grayscale; if RGB, convert with rgb2gray first
if size(x,3) == 3
    x = rgb2gray(uint8(x));
    x = double(x);
end

% >help histeq 
x_enh1 = histeq(uint8(x));             % enhance this image by histogram equalization
figure('Name','Microarray: Global hist-eq','NumberTitle','off');
imshow(x_enh1/255,[]);
title('Histogram Equalization (global)');

% >help adapthisteq 
x_enh2 = adapthisteq(uint8(x));        % enhance this image by adaptive histogram equalization (CLAHE)
figure('Name','Microarray: Adaptive hist-eq','NumberTitle','off');
imshow(x_enh2/255,[]);
title('Adaptive Histogram Equalization (CLAHE)');

% {what is the difference between two enhanced images?}
% {Global histeq redistributes intensities using the overall histogram—contrast improves but can leave
%  local low-contrast regions under-enhanced or over-enhance already bright/dark regions.
%  Adaptive (CLAHE) boosts local contrast tile-by-tile, revealing faint spots and fine patterns more uniformly.
%  CLAHE may amplify local noise or produce slight tiling artifacts if overdone.}

% Observations (Q2):
% - Histogram Equalization (global): The contrast across the whole image increases,
%   but background noise is also amplified. The microarray looks cluttered with 
%   too many bright spots.
% - Adaptive Histogram Equalization (CLAHE): Local contrast enhancement makes the
%   actual spots stand out clearly against a darker background. Fewer background 
%   pixels are enhanced, so the meaningful structures are more visible.
% - Difference: Global equalization improves overall contrast but exaggerates noise,
%   while CLAHE focuses on local contrast, producing a cleaner and more useful image.


%% 3. histogram matching (2 points)
% Learn how to use histeq function to process an input image A such that
% the histogram of the output matches that of a target image B
A = double(imread('cube.tif'));
B = double(imread('cameraman.tif'));

% create a new image (A_modified) such that its histogram is similar to that of image B
% (they won't be identical due to low dynamic range)
A_u8 = uint8(A);
B_u8 = uint8(B);

% Option 1 (per prompt): use histeq with a target histogram derived from B
target_hist = imhist(B_u8);                      % target histogram (256x1)
A_modified = histeq(A_u8, target_hist);          % histogram specification via histeq

% Display result and compare histograms
figure('Name','Histogram Matching','NumberTitle','off');
subplot(1,3,1); imshow(A_u8); title('A (original)');
subplot(1,3,2); imshow(B_u8); title('B (target)');
subplot(1,3,3); imshow(A_modified); title('A\_modified (matched)');

hA = hist(double(A_modified(:)), 1:256);
hB = hist(double(B_u8(:)), 1:256);
figure('Name','Histograms: A\_modified vs B','NumberTitle','off');
i = 1:256;
plot(i, hA, 'LineWidth', 1.2); hold on;
plot(i, hB, 'LineWidth', 1.2);
legend('A\_modified','B (target)');
xlabel('Intensity bin'); ylabel('Count'); grid on; title('Histogram Comparison');

% Observations (Q3):
% - After histogram matching, the image A (cube) acquires an intensity distribution
%   similar to image B (cameraman).
% - The matched image A_modified looks visually closer in tone/contrast to B,
%   though not identical because the cube image has a lower dynamic range.
% - The histogram plot confirms that A_modified follows the general shape of B's 
%   histogram, showing that histogram specification worked as expected.


%% Part 2 (Bonus) — Smoother teapot enhancement
A = imread('teapot.png');
if size(A,3) == 3
    Agray = rgb2gray(A);
else
    Agray = A;
end

% 1) Upscale for nicer edges when sharpening later
U = imresize(Agray, 2, 'bicubic');

% 2) Mild denoise to avoid amplifying sensor noise / JPEG blocks
Udn = medfilt2(U, [3 3]);          % try [5 5] if still noisy

% 3) CLAHE with gentler settings (more tiles, lower clip)
%    More tiles -> more local adaption; lower ClipLimit -> less over-boost
C = adapthisteq(Udn, 'NumTiles',[16 16], 'ClipLimit',0.005, 'Distribution','uniform');

% 4) Edge-preserving smoothing to kill blockiness without blurring edges
%    If imbilatfilt is not available in your MATLAB, comment this and keep the Gaussian below.
try
    C_smooth = imbilatfilt(C, 0.4, 9);   % (degreeOfSmoothing, spatialSigma)
catch
    C_smooth = C;
end

% 5) Light Gaussian to unify patches (very small sigma)
C_smooth = imgaussfilt(C_smooth, 0.6);

% 6) Gentle global stretch (avoid clipping extremes)
C_tone = imadjust(C_smooth, stretchlim(C_smooth, [0.01 0.99]), []);

% 7) Subtle sharpening (reduced Amount to avoid halos)
B = imsharpen(C_tone, 'Radius',1, 'Amount',0.75, 'Threshold',0.01);

% OPTIONAL: tiny local contrast touch if you still want a bit more pop
% (comment out if your MATLAB doesn't have localcontrast)
try
    B = localcontrast(B, 0.25, 0.6);   % smaller edgeStrength & smoother
end

figure('Name','Teapot Enhancement (Smoother)','NumberTitle','off');
subplot(1,2,1); imshow(Agray); title('Original (grayscale)');
subplot(1,2,2); imshow(B);     title('Enhanced (smoothed)');

% Observations (Bonus):
% - The original teapot image is very dark with low contrast; the teapot is hardly visible.
% - After enhancement (CLAHE + smoothing + sharpening), the teapot edges, handle,
%   and spout become much clearer.
% - Local contrast enhancement brings out hidden details, while denoising and 
%   smoothing reduce block artifacts.
% - Limitation: Noise and artifacts may still appear in very dark or flat regions,
%   but overall the teapot is now recognizable and visually enhanced.
