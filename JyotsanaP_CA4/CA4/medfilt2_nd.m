function out = medfilt2_nd(img)
% Median filter with noise detection for salt & pepper
% Idea: only replace noisy pixels (0 or 255), keep others unchanged
[m,n] = size(img);
out = img;
pad = padarray(img,[1 1],'symmetric');
for i=2:m+1
    for j=2:n+1
        window = pad(i-1:i+1, j-1:j+1);
        if pad(i,j)==0 || pad(i,j)==255
            out(i-1,j-1) = median(window(:));
        end
    end
end
end