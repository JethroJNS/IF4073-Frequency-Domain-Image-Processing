classdef GaussianLowPassFilter
    methods (Static)

        function H = create(rows, cols, cutoff)
            % cutoff diperlakukan sebagai sigma (harus > 0)
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});

            D = createFrequencyGrid(rows, cols);
            H = exp(-(D.^2) / (2 * cutoff^2));
        end

        function filtered = apply(img, cutoff)
            [filtered, ~] = GaussianLowPassFilter.applyWithFilter(img, cutoff);
            filtered = max(0, min(1, filtered));
        end

        function filtered = applyRaw(img, cutoff)
            [filtered, ~] = GaussianLowPassFilter.applyWithFilter(img, cutoff);
        end

        function [filtered, H] = applyWithFilter(img, cutoff)
            validateattributes(img, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});

            img = im2double(img);
            [rows, cols] = size(img);

            F = fftshift(fft2(img));
            H = GaussianLowPassFilter.create(rows, cols, cutoff);

            filtered = real(ifft2(ifftshift(F .* H)));
        end
    end
end