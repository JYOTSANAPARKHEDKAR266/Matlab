%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICSI471/571 Introduction to Computer Vision Fall 2025
% Copyright: Xin Li@2024-2026
% Computer Assignment 2: Image Interpolation 
% Due Date: Sep. 23, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Name: Jyotsana Parkhedkar

% The objective of this assignment is to play with various image
% interpolation and enhancement related MATLAB functions (easy and fun)
% MATLAB functions: imresize, imrotate, griddata  

%% ========================= Part 1 (2 points) ===========================
% Image interpolation experiments

x = imread('oil_painting.bmp');                % could be RGB
if ndims(x)==3, x = rgb2gray(x); end
x = double(x);

whos x  % check resolution

tic; 
x1 = imresize(x, 2, 'bilinear');               % bilinear interpolation
t_bilinear = toc;

tic; 
x2 = imresize(x, 2, 'bicubic');                % bicubic interpolation
t_bicubic  = toc;

if exist('sri_color','file')==2
    I01 = x/255;                       % normalize to [0,1]
    if ndims(I01)==2
        % sri_color expects 3 channels; replicate gray to RGB
        I01_rgb = repmat(I01, [1 1 3]);
        tic;
        Yrgb = sri_color(I01_rgb, 1);   % returns [0,1]
        t_nedi = toc;
        % convert back to gray (mean of channels) and scale to [0,255]
        x3 = mean(Yrgb, 3) * 255;
    else
        tic;
        Y = sri_color(I01, 1);          % RGB in [0,1]
        t_nedi = toc;
        x3 = double(Y) * 255;
    end
elseif exist('sri','file')==2
    % sri typically accepts single-channel in [0,1]
    tic;
    x3 = double(sri(x/255, 1)) * 255;    % returns [0,255] double
    t_nedi = toc;
else
    error('NEDI file not found (expected sri_color.m or sri.m).');
end

fprintf('Timings (sec): bilinear=%.3f  bicubic=%.3f  NEDI=%.3f\n', ...
        t_bilinear, t_bicubic, t_nedi);

figure(1); imshow(x1/255,[]); title('Bilinear (2x)'); pause;
figure(1); imshow(x2/255,[]); title('Bicubic (2x)');  pause;
figure(1); imshow(x3/255,[]); title('NEDI (2x)');

% Save outputs
imwrite(uint8(x1), 'oil_bilinear_2x.png');
imwrite(uint8(x2), 'oil_bicubic_2x.png');
imwrite(uint8(x3), 'oil_nedi_2x.png');

% Observations:
% - Bilinear interpolation:
%   Produces a visibly smoother and blurrier result. Fine textures and edge
%   details are noticeably softened because bilinear simply averages nearby
%   pixels without considering curvature.
%
% - Bicubic interpolation:
%   Preserves edges and textures better than bilinear. Lines and contours
%   look sharper, though some slight ringing or overshoot can appear near
%   high-contrast edges. Processing time is moderately higher.
%
% - NEDI (New Edge-Directed Interpolation):
%   Provides the most natural-looking upscaled image with edges that appear
%   sharp and less blurred. Thin structures and textures are better
%   preserved compared to bilinear or bicubic. However, this method is
%   significantly slower to compute due to its adaptive, edge-directed
%   estimation process.
%
% Summary:
%   - Bilinear → fastest but blurriest
%   - Bicubic  → good compromise between quality and speed
%   - NEDI     → best quality (especially on edges), but slowest runtime

%% ========================= Part 2 (2 points) ===========================
% Image rotation experiment

im = read_raw('clock.raw','uchar',512,512)';   % RAW 512x512, 8-bit

x = double(imresize(im, .5));
y = x;

for i = 1:12
    y = imrotate(y, -30, 'bicubic', 'crop');   % clockwise rotation
end

figure(2); imshow([x y]/255,[]);
title('Original (left) vs 12×30° Clockwise Rotations (right)');

% Save output
imwrite(uint8([x y]), 'clock_rotations_side_by_side.png');

% {Observation:
%  After twelve 30° rotations, the image does not perfectly match the
%  original: edges appear less sharp, fine details are diminished, and
%  slight blur or ringing artifacts can be seen.
%
%  Explanation:
%  Each rotation requires resampling the image on a discrete pixel grid.
%  Pixel values that fall between grid points are estimated through
%  interpolation (here, bicubic), which smooths out high-frequency details
%  and introduces minor quantization errors. These small distortions build
%  up over multiple rotations. In continuous space, a 360° rotation would
%  return an image unchanged, but in the discrete case, interpolation makes
%  some loss of information unavoidable. }

%% ========================= Part 3 (2 points) ===========================
% Fun distortions with interpolation

portrait = 'C:\Users\jyots\AppData\Local\Temp\a4084e28-7c7f-4bf6-9aaa-a71efad315f7_CA2.zip.5f7\CA2\Bill_Gates.jpg';
if ~exist(portrait,'file'), portrait = 'Bill_Gates.jpg'; end
if ~exist(portrait,'file'), error('Portrait image not found.'); end

x = double(imresize(rgb2gray(imread(portrait)), .5));
[M,N] = size(x);
[r,c] = meshgrid(1:N,1:M);

% Random jitter
rng(0);                          % reproducible randomness
w = randn(1,M);
r1 = r + repmat(w, N, 1)';
y  = griddata(r1, c, x, r, c, 'cubic'); y(isnan(y))=0;
figure(3); imshow(y,[]); title('Random row jitter');
imwrite(uint8(y), 'portrait_jitter.png');

% Vertical sine ripple
ampA = 10; freqA = 2*pi/80;
rA   = r + ampA * sin(freqA * c);
yA   = griddata(rA, c, x, r, c, 'cubic'); yA(isnan(yA))=0;
figure(4); imshow(yA,[]); title('Vertical sine ripple');
imwrite(uint8(yA), 'portrait_ripple_vertical.png');

% Horizontal ripple
ampB = 8; freqB = 2*pi/60;
cB   = c + ampB * sin(freqB * r);
yB   = griddata(r, cB, x, r, c, 'cubic'); yB(isnan(yB))=0;
figure(5); imshow(yB,[]); title('Horizontal ripple');
imwrite(uint8(yB), 'portrait_ripple_horizontal.png');

% Swirl
cx = (N+1)/2; cy = (M+1)/2;
dx = r - cx; dy = c - cy;
[theta, rho] = cart2pol(dx, dy);
k = 0.002;
theta2 = theta + k*rho;
[dx2, dy2] = pol2cart(theta2, rho);
rC = dx2 + cx; cC = dy2 + cy;
yC = griddata(rC, cC, x, r, c, 'cubic'); yC(isnan(yC))=0;
figure(6); imshow(yC,[]); title('Swirl distortion');
imwrite(uint8(yC), 'portrait_swirl.png');

% Observations:
%
% - Random row jitter:
%   The portrait appears wavy in a chaotic fashion — rows are shifted by
%   random amounts, producing a "shaky" or distorted look. The effect feels
%   like the image is melting vertically without a consistent pattern.
%
% - Vertical sine ripple:
%   Produces smooth, periodic oscillations along the vertical direction.
%   The image looks as if it is flowing like water or printed on a
%   flag rippling in the wind. Vertical structures bend sinusoidally.
%
% - Horizontal ripple:
%   Similar to the vertical ripple but applied across rows. Horizontal
%   features are displaced up and down in a wave pattern, giving a
%   "corrugated" or wave-like effect across the image.
%
% - Swirl distortion:
%   The image is twisted around its center, with pixels rotated by angles
%   proportional to their distance from the middle. The result is a
%   vortex-like warping where the central region remains fairly intact,
%   but the outer areas spiral strongly. It's visually striking and creates
%   a surreal effect.
%
% Summary:
%   Each distortion demonstrates how altering pixel coordinate grids with
%   interpolation creates very different visual illusions — from random
%   noise-like jitter to structured waves and dramatic nonlinear warps.


%% ====================== Bonus Part (1 point) ===========================
% Castle repair

x = imread('castle_orig.pbm');
y = imread('castle_damaged.pbm');
figure(8); imshow([x y]); title('Original (left) and Damaged (right)');

xx = castle_repair(y);

figure(9); imshow([x y xx]); title('orig | damaged | repaired');
imwrite(x,  'castle_orig_view.png');
imwrite(y,  'castle_damaged_view.png');
imwrite(xx, 'castle_repaired.png');

if exist('castle_test.m','file')
    castle_test(x, xx)
end

% Observations:
%
% - The damaged castle image shows broken walls, missing pixels, and
%   scattered noise that disrupts the silhouette of the structure.
%
% - After applying the castle_repair function:
%   • Small holes within the castle regions are filled.
%   • Thin cracks and breaks in the outline are bridged and connected.
%   • Isolated noise specks outside the castle are removed.
%   • Edges appear more continuous, and the overall castle shape is
%     restored to closely match the original.
%
% - The repaired version is not mathematically identical to the original,
%   but visually it preserves the main structure while removing most of the
%   damage. Any slight loss of fine detail is the trade-off for smoothing
%   and morphological cleanup.
%
% - Overall, morphological tools (bridge, close, fill, clean, area-open)
%   effectively reconstruct the binary silhouette, making the repaired
%   image suitable for comparison with the original using castle_test.