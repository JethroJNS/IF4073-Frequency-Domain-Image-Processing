classdef IdealHighPassFilter
    methods (Static)

        function H = create(rows, cols, cutoff)
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'nonnegative'});

            D = createFrequencyGrid(rows, cols);
            H = double(D > cutoff);
        end

        function filtered = apply(img, cutoff)
            [filtered, ~] = IdealHighPassFilter.applyWithFilter(img, cutoff);
            filtered = max(0, min(1, filtered));
        end

        function filtered = applyRaw(img, cutoff)
            [filtered, ~] = IdealHighPassFilter.applyWithFilter(img, cutoff);
        end

        function [filtered, H] = applyWithFilter(img, cutoff)
            validateattributes(img, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'nonnegative'});

            img = im2double(img);
            [rows, cols] = size(img);

            F = fftshift(fft2(img));
            H = IdealHighPassFilter.create(rows, cols, cutoff);

            filtered = real(ifft2(ifftshift(F .* H)));
        end
    end
end