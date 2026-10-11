% menghitung magnitudo spektrum dari representasi Fourier
function M = computeMagnitudeFromSpectrum(F)
    validateattributes(F, {'numeric'}, ...
        {'2d', 'finite', 'nonempty'});

    M = abs(F);
end
