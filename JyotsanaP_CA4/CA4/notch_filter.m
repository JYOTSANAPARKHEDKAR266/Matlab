function out = notch_filter(img,R)
% Simple notch filter for periodic noise
F = fftshift(fft2(double(img)));
[M,N] = size(F);
Cx = round(M/2); Cy = round(N/2);
% Remove symmetric spikes manually (demo: remove horizontal/vertical stripes)
mask = ones(M,N);
for u=1:M
    for v=1:N
        if (abs(u-Cx)<R && abs(v-Cy*0.5)<R) || (abs(v-Cy)<R && abs(u-Cx*0.5)<R)
            mask(u,v)=0;
        end
    end
end
F_filtered = F .* mask;
out = real(ifft2(ifftshift(F_filtered)));
end