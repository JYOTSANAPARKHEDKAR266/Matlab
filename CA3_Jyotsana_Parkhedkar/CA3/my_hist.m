function h = my_hist(x, nbins)
%MY_HIST  Compute a histogram for an image with specified number of bins.
%   h = MY_HIST(x, nbins) returns a column vector h (nbins x 1) with counts.
%
%   Inputs:
%     x     - grayscale image (uint8, double, etc.)
%     nbins - number of histogram bins (default = 256)
%
%   Output:
%     h     - histogram counts (nbins x 1)
%
%   Example:
%     x = imread('cube.tif');
%     h = my_hist(x, 256);
%     bar(0:255, h);

    % Default to 256 bins if not provided
    if nargin < 2
        nbins = 256;
    end

    % Convert image to double and vectorize
    x = double(x(:));

    % Assume 8-bit image range if nbins=256, otherwise auto-scale
    if nbins == 256 && min(x) >= 0 && max(x) <= 255
        xmin = 0;
        xmax = 255;
    else
        xmin = min(x);
        xmax = max(x);
    end

    % Avoid division by zero if image is constant
    if xmax == xmin
        h = zeros(nbins,1);
        h(1) = numel(x);
        return;
    end

    % Map pixel values to bin indices
    idx = floor((x - xmin) ./ (xmax - xmin) * nbins) + 1;

    % Clamp out-of-range indices
    idx(idx < 1) = 1;
    idx(idx > nbins) = nbins;

    % Count frequencies
    h = accumarray(idx, 1, [nbins, 1]);
end
