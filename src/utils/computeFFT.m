% menghitung FFT 2D dan mengembalikan spektrum dengan titik pusat di tengah
function [F, magnitude, phase] = computeFFT(img)
    validateattributes(img, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});

    if ~isa(img, 'double')
        img = im2double(img);
    end

    F = fft2(img);
    F = fftshift(F);

    magnitude = log1p(abs(F));
    phase = angle(F);
end