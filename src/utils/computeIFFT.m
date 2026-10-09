% merekonstruksi citra dari spektrum Fourier yang telah digeser
function imgOut = computeIFFT(F, wasShifted)
    validateattributes(F, {'numeric'}, ...
        {'2d', 'finite', 'nonempty'});

    if nargin < 2
        wasShifted = true;
    end

    validateattributes(wasShifted, {'logical', 'numeric'}, ...
        {'scalar', 'real', 'finite', 'binary'});
    wasShifted = logical(wasShifted);

    if wasShifted
        F = ifftshift(F);
    end

    imgOut = ifft2(F);
    imgOut = real(imgOut);
end