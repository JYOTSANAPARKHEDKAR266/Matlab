%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICSI471/571 Introduction to Computer Vision Fall 2025
% Copyright: Xin Li@2024-2026
% Computer Assignment 5: Image Deblurring and Midterm Practice
% Due Date: Oct. 14, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Name : Jyotsana Parkhedkar  - 001661399

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


close all; clear; clc;

% Part I: Image deblurring experiments (3 points)
% 1. Simulated Experiment of Image Blurring (1 point)
try
    x1_raw = imread('saturn.jpg');
catch
    % Many MATLAB installs ship 'saturn.png' in imdata
    warning('saturn.jpg not found; using saturn.png instead.');
    x1_raw = imread('saturn.png');
end

% Convert to grayscale double if needed
if size(x1_raw,3) == 3
    x1 = rgb2gray(x1_raw);
else
    x1 = x1_raw;
end
x1 = double(x1);

% crop out the saturn region (as specified)
% NOTE: If your image is smaller, adjust indices or guard them.
r1 = 101:200; c1 = 51:350;
r1(r1 > size(x1,1)) = [];
c1(c1 > size(x1,2)) = [];
x1 = x1(r1, c1);
[M,N] = size(x1);

% specify a uniform 9-by-9 (Gaussian) blurring kernel
psf = fspecial('gaussian', 9, 2);

% optical transfer function (otf) is the FT of psf
% (for visualization we follow the prompt's [31 31] size)
otf_vis  = psf2otf(psf, [31 31]); % PSF --> OTF (for display)

figure('Name','PSF & |OTF| (visualization)');
subplot(1,2,1); surf(psf); title('PSF'); axis square; axis tight
subplot(1,2,2); surf(fftshift(abs(otf_vis))); title('corresponding |OTF|');
axis square; axis tight


% 2. artificially generate the blurred image (1 point)
y1 = imfilter(x1, psf, 'symmetric');

% visually inspect the blurred image
figure('Name','Blurred Image y1'); imshow(y1,[]); title('y1 (blurred, no noise)');

% now let us see how inverse filtering method works
% (Fill-ins from the prompt)
Y1 = fft2(y1);                     % <apply fft2 to image y1>
H  = fft2(psf, M, N);              % <apply fft2 with size M-by-N to psf>

% inverse filtering in the frequency domain
Z1 = Y1 ./ H;
z1 = abs(ifft2(Z1));

% verify it does look like x1 - the original image
figure('Name','Original vs Inverse-Filtered (Noiseless)');
subplot(1,2,1); imshow(x1,[]); title('Original x1');
subplot(1,2,2); imshow(z1,[]); title('Inverse filter result z1');

% Now repeat the above experiment for a noisy blurred image
sigma = 1; % Note that the amount of noise is very small
y2 = imfilter(x1, psf, 'symmetric') + randn(size(x1)) * sigma;

% Visually no difference between y1 and y2
figure('Name','y1 vs y2 (visual similarity)'); 
imshow([y1 y2],[]); title('Left: y1 (no noise) | Right: y2 (with small noise)');

% Implement Lines 42-48 as a separate function inverse_filtering.m
z2 = inverse_filtering(y2, psf);

figure('Name','Inverse Filtering: Noiseless vs Noisy');
subplot(1,2,1); imshow(z1,[]); title('z1 (noiseless inverse filter)');
subplot(1,2,2); imshow(z2,[]); title('z2 (noisy inverse filter)');


% 3. Deblur real-world image with optical blur (1 point)
% use >help fitsread to learn how to handle .FITS image
try
    y = fitsread('ClockB.fit');        % <read image data ClockB.fit into MATLAB>
    psf_clock = fitsread('ClockPSF.fit'); % <read psf data ClockPSF.fit into MATLAB>
catch ME
    error(['FITS files not found or cannot be read: ', ME.message, ...
           '\nPlease place ClockB.fit and ClockPSF.fit in the current folder.']);
end

% Normalize PSF (important for many deconvolution algorithms)
psf_clock = psf_clock ./ sum(psf_clock(:) + eps);

% use >help deconvlucy to learn how to deblur an image with given psf
% Choose a reasonable iteration count (e.g., 10–30). We'll use 20.
iters = 20;
x = deconvlucy(y, psf_clock, iters);   % <deconvoluted clock image>

figure('Name','Lucy-Richardson Deconvolution (Clock)');
subplot(1,3,1); imshow(y,[]); title('Observed (blurred) y');
subplot(1,3,2); imshow(psf_clock,[]); title('PSF (normalized)');
subplot(1,3,3); imshow(x,[]); title(sprintf('Deblurred (Lucy-Richardson, %d iters)', iters));

% Part 1 — Image Deblurring
% PSF/OTF: Gaussian PSF smooth; OTF peaks at DC and decays → high-freq detail attenuated.
% y1: blur softens edges; inverse filter z1 recovers detail but rings from small |H(f)|.
% y2→z2: tiny noise explodes after division by near-zero |H(f)| → heavy noise/artifacts.
% Lucy–Richardson: sharper clock hands/ticks; some halos/noise remain; PSF normalization helps.


% Part 2: Practice Problems for the Midterm Exam (3 points)

%% Problem 1: count pixels in [50,200]
x = imread('moon.tif');
if ndims(x) == 3
    x = rgb2gray(x);           % ensure grayscale
end
x = im2uint8(x);               % ensure 0–255 range (uint8)

% Using histogram (typical for this topic):
counts = imhist(x);            % counts(k) corresponds to intensity k-1
total_number_of_pixels_between_50_and_200 = sum(counts(51:201));

%% Problem 2: size difference (pixels) between largest bright and dark circles
x = imread('circlesBrightDark.png');
if size(x,3)==3, xg = rgb2gray(x); else, xg = x; end
xg = mat2gray(xg);
[h,w] = size(xg);
fprintf('Image size: %dx%d, total=%d\n', h, w, numel(xg));

% 3-class segmentation: [dark | mid | bright]
T = multithresh(xg, 2);          % two thresholds t1 < t2
L = imquantize(xg, T);           % 1=dark, 2=mid, 3=bright

bw_dark   = (L == 1);
bw_bright = (L == 3);

% clean and keep the largest blob in each class
bw_dark   = bwareaopen(bw_dark, 30);
bw_bright = bwareaopen(bw_bright, 30);
bw_dark   = bwareafilt(bw_dark,   1);
bw_bright = bwareafilt(bw_bright, 1);

A_dark   = round(bwarea(bw_dark));
A_bright = round(bwarea(bw_bright));
size_difference_of_bright_and_dark_circles = abs(A_bright - A_dark);

fprintf('Largest BRIGHT circle=%d, largest DARK circle=%d, |diff|=%d\n', ...
        A_bright, A_dark, size_difference_of_bright_and_dark_circles);

% (optional) visualize
figure('Name','Problem 2: Segmentation (multi-Otsu)');
subplot(1,3,1), imshow(xg,[]), title('Input')
subplot(1,3,2), imshow(bw_bright), title('Largest BRIGHT circle')
subplot(1,3,3), imshow(bw_dark),   title('Largest DARK circle')
%% Problem 3: estimate #pixels of green leaves in yellowlily (robust + overlay)
x = imread('yellowlily.jpg');
if size(x,3) == 1, x = repmat(x, [1 1 3]); end
x_d = im2double(x);

leaves_mask = [];

% --- Optionally use provided segmented PNG, whatever its format/size ---
if exist('yellowlily-segmented.png','file')
    [seg, cmap] = imread('yellowlily-segmented.png');   % seg may be indexed, gray, or RGB
    if ~isempty(cmap)
        segRGB = ind2rgb(seg, cmap);                    % double in [0,1]
    else
        segRGB = seg;
        if size(segRGB,3) == 1
            segRGB = repmat(im2double(segRGB), [1 1 3]);
        else
            segRGB = im2double(segRGB);
        end
    end

    % Resize segmented image to photo size for any subsequent operations
    segRGB = imresize(segRGB, [size(x,1) size(x,2)], 'nearest');

    % Use color info to pull green-ish regions (HSV thresholds)
    hsvS = rgb2hsv(segRGB);
    Hs = hsvS(:,:,1); Ss = hsvS(:,:,2); Vs = hsvS(:,:,3);
    mask_from_seg = (Hs >= 0.22 & Hs <= 0.45) & (Ss >= 0.35) & (Vs >= 0.12);

    % Clean
    mask_from_seg = imopen(mask_from_seg,  strel('disk',3));
    mask_from_seg = imclose(mask_from_seg, strel('disk',7));
    mask_from_seg = imfill(mask_from_seg,  'holes');

    leaves_mask = mask_from_seg;
end

% --- Fallback or refinement using the original photo (HSV) ---
if isempty(leaves_mask)
    hsv = rgb2hsv(x_d);
    H = hsv(:,:,1); S = hsv(:,:,2); V = hsv(:,:,3);
    leaves_mask = (H >= 0.22 & H <= 0.45) & (S >= 0.35) & (V >= 0.12);
    leaves_mask = imopen(leaves_mask,  strel('disk',3));
    leaves_mask = imclose(leaves_mask, strel('disk',7));
    leaves_mask = imfill(leaves_mask,  'holes');
end

% --- Ensure mask matches the photo size (prevents labeloverlay error) ---
[h,w,~] = size(x);
if ~isequal(size(leaves_mask,1), h) || ~isequal(size(leaves_mask,2), w)
    leaves_mask = imresize(leaves_mask, [h w], 'nearest');
end

% --- Count pixels ---
leaves_size_estimation = nnz(leaves_mask);
fprintf('P3) Estimated leaf area: %d pixels\n', leaves_size_estimation);

% --- Visualization (3 panels) ---
figure('Name','Problem 3: Leaves Segmentation');
subplot(1,3,1), imshow(x), title('yellowlily.jpg')
subplot(1,3,2), imshow(leaves_mask), title('Leaves mask')

% Overlay (choose either labeloverlay or manual overlay)
try
    subplot(1,3,3), imshow(labeloverlay(x, leaves_mask)), title('Overlay')
catch
    % Manual overlay fallback (red-tinted mask)
    subplot(1,3,3);
    overlay = cat(3, leaves_mask, zeros(size(leaves_mask)), zeros(size(leaves_mask))); % red
    imshow(max(x_d, 0.7*overlay)); title('Overlay')
end


%% Problem 4: total area of threads in threads.png
x = imread('threads.png');
if size(x,3) == 3, xg = rgb2gray(x); else, xg = x; end
xg = mat2gray(xg);

% Adaptive threshold (bright threads on darker background)
bw = imbinarize(xg, 'adaptive', 'ForegroundPolarity','bright', 'Sensitivity',0.5);
bw = bwareaopen(bw, 20);
bw = imclose(bw, strel('disk',2));
bw = imfill(bw, 'holes');

total_threads_area = nnz(bw);
fprintf('P4) Total threads area: %d pixels\n', total_threads_area);

% Optional visualization
figure('Name','Problem 4: Threads Segmentation');
subplot(1,2,1), imshow(xg,[]), title('threads.png (gray)')
subplot(1,2,2), imshow(bw), title('Threads mask')

%% Problem 5: angle (deg) of moon shadow wrt horizontal
x = imread('moon.tif');
if size(x,3) == 3, xg = rgb2gray(x); else, xg = x; end
xg = mat2gray(xg);

% Detect strong line(s) with Hough
E = edge(xg, 'canny');
[H,T,R] = hough(E);
P  = houghpeaks(H, 5, 'threshold', ceil(0.3*max(H(:))));
lines = houghlines(E, T, R, P, 'FillGap', 10, 'MinLength', 30);

% Choose the longest detected line as the shadow
bestLen = 0; theta_deg = NaN;
for k=1:numel(lines)
    p1 = lines(k).point1; p2 = lines(k).point2;
    L = hypot(p1(1)-p2(1), p1(2)-p2(2));
    if L > bestLen
        bestLen = L;
        % angle wrt horizontal: atan2(dy, dx) in degrees
        dx = p2(1)-p1(1); dy = p2(2)-p1(2);
        theta_deg = atan2d(dy, dx); % +ve = counterclockwise from +x
    end
end
shadow_angle = theta_deg; % degrees wrt horizontal
fprintf('P5) Estimated moon shadow angle: %.2f degrees (w.r.t. horizontal)\n', shadow_angle);

% Visualization
figure('Name','Problem 5: Hough Lines');
imshow(xg,[]); hold on; title(sprintf('Shadow angle ~ %.2f^\\circ', shadow_angle));
for k=1:numel(lines)
    xy = [lines(k).point1; lines(k).point2];
    plot(xy(:,1), xy(:,2), 'LineWidth', 2);
end
hold off;

%% Problem 6: unshuffle license plate image
% We will try several small grid sizes and pick the best by border matching
x = imread('plate_shuffled.png'); 
if size(x,3) == 1
    Xrgb = repmat(x,1,1,3);
else
    Xrgb = x;
end
[h,w,~] = size(Xrgb);

% Candidate grids to try (keeps runtime small but practical)
candidate_grids = [2 2; 2 3; 3 2];

bestImg  = Xrgb;
bestCost = inf;
bestGrid = [];

for gi = 1:size(candidate_grids,1)
    gh = candidate_grids(gi,1); 
    gw = candidate_grids(gi,2);
    if mod(h,gh)~=0 || mod(w,gw)~=0
        continue; 
    end

    th = h/gh; 
    tw = w/gw;

    % Cut tiles
    tiles = cell(gh,gw);
    for r = 1:gh
        for c = 1:gw
            rr = (r-1)*th+1 : r*th;
            cc = (c-1)*tw+1 : c*tw;
            tiles{r,c} = Xrgb(rr,cc,:);
        end
    end

    % Flatten to list
    T = reshape(tiles, 1, []);
    K = numel(T);

    % Edge-cost helpers (anonymous one-liners)
    rightCost = @(A,B) mean(abs( ...
        reshape(double(squeeze(A(:,end,:))) - double(squeeze(B(:,1,:))), [], 1)));
    leftCost  = @(A,B) mean(abs( ...
        reshape(double(squeeze(A(:,1,:))) - double(squeeze(B(:,end,:))), [], 1)));
    downCost  = @(A,B) mean(abs( ...
        reshape(double(squeeze(A(end,:,:))) - double(squeeze(B(1,:,:))), [], 1)));
    upCost    = @(A,B) mean(abs( ...
        reshape(double(squeeze(A(1,:,:))) - double(squeeze(B(end,:,:))), [], 1)));

    % Build cost matrices
    R = inf(K); L = inf(K); U = inf(K); D = inf(K);
    for i = 1:K
        for j = 1:K
            if i == j, continue; end
            R(i,j) = rightCost(T{i}, T{j});
            L(i,j) = leftCost (T{i}, T{j});
            U(i,j) = upCost   (T{i}, T{j});
            D(i,j) = downCost (T{i}, T{j});
        end
    end

    % --------- Greedy placement ---------
    placement = zeros(gh, gw);
    used = false(1,K);

    % pick start as the tile with minimal sum of best neighbor costs
    score = inf(1,K);
    for i = 1:K
        rrow = R(i, :); rrow = rrow(isfinite(rrow));
        drow = D(i, :); drow = drow(isfinite(drow));
        if ~isempty(rrow) && ~isempty(drow)
            score(i) = min(rrow) + min(drow);
        end
    end
    [~, startIdx] = min(score);

    placement(1,1) = startIdx; 
    used(startIdx) = true;

    % fill first row (left->right)
    for c = 2:gw
        leftIdx = placement(1, c-1);
        cand = find(~used);
        [~, bestJ] = min(R(leftIdx, cand));
        placement(1,c) = cand(bestJ);
        used(placement(1,c)) = true;
    end

    % fill remaining rows
    for r = 2:gh
        % first column: match above
        aboveIdx = placement(r-1, 1);
        cand = find(~used);
        [~, bestJ] = min(D(aboveIdx, cand));
        placement(r,1) = cand(bestJ);
        used(placement(r,1)) = true;

        % rest of row: match both left and above (sum cost)
        for c = 2:gw
            leftIdx  = placement(r, c-1);
            aboveIdx = placement(r-1, c);
            cand = find(~used);
            costs = R(leftIdx, cand) + D(aboveIdx, cand);
            [~, kbest] = min(costs);
            placement(r,c) = cand(kbest);
            used(placement(r,c)) = true;
        end
    end

    % Compute total internal border cost of the placement
    totalCost = 0;
    for r = 1:gh
        for c = 1:gw
            i = placement(r,c);
            if c < gw
                j = placement(r, c+1);
                totalCost = totalCost + R(i,j);
            end
            if r < gh
                j = placement(r+1, c);
                totalCost = totalCost + D(i,j);
            end
        end
    end

    % Keep best reconstruction
    if totalCost < bestCost
        bestCost = totalCost; 
        bestGrid = [gh gw];
        % Reconstruct image
        rec = zeros(size(Xrgb), 'like', Xrgb);
        for r = 1:gh
            for c = 1:gw
                rr = (r-1)*th+1 : r*th;
                cc = (c-1)*tw+1 : c*tw;
                rec(rr,cc,:) = T{placement(r,c)};
            end
        end
        bestImg = rec;
    end
end

figure('Name','Problem 6: License Plate Unshuffle');
subplot(1,2,1), imshow(Xrgb), title('Shuffled input')
subplot(1,2,2), imshow(bestImg), ...
    title(sprintf('Reconstructed (grid=%s, cost=%.1f)', mat2str(bestGrid), bestCost));
% For the variable the prompt asks to "display the unshuffled image":
% (Not a required variable name, but we expose one)
unshuffled_image = bestImg;

% Part 2 — Midterm Practice
% P1: Most moon pixels fall in mid-range [50,200] consistent with mid-gray image.
% P2: Largest bright ≈ 9698 px, dark ≈ 9433 px → |diff| ≈ 265 px (circles nearly same size).
% P3: Leaf area ≈ 349,071 px; HSV + morphology captures green leaves, excludes flower mostly.
% P4: Threads area ≈ 73,521 px; adaptive binarization + cleanup isolates thread strokes.
% P5: Shadow angle ≈ 90° w.r.t. horizontal; terminator essentially vertical.
% P6: Jigsaw solved with grid [2 3]; text lines align; low match cost indicates correct assembly.