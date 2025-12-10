function x = inverse_filtering(y, f)
%INVERSE_FILTERING  Stable inverse filtering in the frequency domain.
%   x = inverse_filtering(y, f) deblurs image y using PSF f.
%   Uses a damped pseudo-inverse to avoid blowing up noise where |F|~0.
%
%   If you need the exact inverse (not recommended), set lambda = 0 below.

    % --- Type/shape prep ---
    if ~isa(y,'double'); y = double(y); end
    if ~isa(f,'double'); f = double(f); end
    [M, N] = size(y);

    % Normalize PSF (helps conditioning and deconvolution algorithms)
    s = sum(f(:));
    if s ~= 0
        f = f / s;
    end

    % --- FFTs ---
    Y = fft2(y);
    F = fft2(f, M, N);

    % --- Stable pseudo-inverse (Tikhonov-style damping) ---
    % lambda controls stability; larger -> safer but blurrier.
    % You can tune this depending on noise level. For small noise, try 1e-4..1e-3.
    F2 = abs(F).^2;
    lambda = 1e-3 * max(F2(:));    % heuristic damping
    % For exact inverse (unstable), uncomment next line:
    % lambda = 0;

    % Pseudo-inverse in frequency domain:
    % X = Y .* conj(F) ./ (|F|^2 + lambda)
    X = Y .* conj(F) ./ (F2 + lambda);

    % --- IFFT back to spatial domain ---
    x = real(ifft2(X));

    % --- Optional: restore dynamic range to match input y ---
    ymin = min(y(:)); ymax = max(y(:));
    if ymin ~= ymax
        x = (x - min(x(:))) / max(eps, (max(x(:)) - min(x(:))));
        x = x * (ymax - ymin) + ymin;
    end
end