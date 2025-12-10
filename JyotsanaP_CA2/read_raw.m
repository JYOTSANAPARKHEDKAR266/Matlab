function X = read_raw(name, fmt, height, width)
%READ_RAW Read a headerless RAW image into MATLAB.
%   X = READ_RAW(NAME, FMT, H, W)
%   NAME:  filename (e.g., 'clock.raw')
%   FMT:   numeric class string for fread (e.g., 'uchar' for 8-bit)
%   H, W:  image height and width
%
% Returns X as double with the same numeric range as the underlying type.

    fid = fopen(name, 'rb');
    if fid < 0
        error('Cannot open file: %s', name);
    end
    [data, count] = fread(fid, height*width, ['*' fmt]);
    fclose(fid);

    if count ~= height*width
        error('File size does not match H*W for %s (fmt=%s).', name, fmt);
    end

    X = reshape(data, [width, height])';  % reshape + transpose to HxW
    X = double(X);
end