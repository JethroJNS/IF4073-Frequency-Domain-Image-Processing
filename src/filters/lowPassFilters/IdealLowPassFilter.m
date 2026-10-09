% Pemisahan clipping:
% apply(): hasil ter-clip ke [0,1]
% applyWithFilter(): respons matematis murni tanpa clipping + mask H
% applyRaw(): alias eksplisit untuk respons matematis murni
classdef IdealLowPassFilter
    methods (Static)

        function H = create(rows, cols, cutoff)
            % create - Create Ideal Low-Pass Filter mask
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'nonnegative'});

            D = createFrequencyGrid(rows, cols);
            H = double(D <= cutoff);
        end

        function filtered = apply(img, cutoff)
            % apply - Hasil TER-CLIP ke [0,1] (kompatibel test)
            [filtered, ~] = IdealLowPassFilter.applyWithFilter(img, cutoff);
            filtered = max(0, min(1, filtered));
        end

        function filtered = applyRaw(img, cutoff)
            % applyRaw - Respons matematis MURNI tanpa clipping
            [filtered, ~] = IdealLowPassFilter.applyWithFilter(img, cutoff);
        end

        function [filtered, H] = applyWithFilter(img, cutoff)
            % applyWithFilter - Respons matematis murni + mask H
            validateattributes(img, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'nonnegative'});

            img = im2double(img);
            [rows, cols] = size(img);

            F = fftshift(fft2(img));
            H = IdealLowPassFilter.create(rows, cols, cutoff);

            filtered = real(ifft2(ifftshift(F .* H)));
        end
    end
end