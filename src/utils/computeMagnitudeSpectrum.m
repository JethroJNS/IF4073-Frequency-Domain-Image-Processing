% menghitung spektrum magnitudo logaritmik dengan titik pusat di tengah
function spectrum = computeMagnitudeSpectrum(img)
    validateattributes(img, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});

    if ~isa(img, 'double')
        img = im2double(img);
    end

    F = fftshift(fft2(img));
    spectrum = log1p(abs(F));
end