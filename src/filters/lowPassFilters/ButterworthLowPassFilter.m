classdef ButterworthLowPassFilter
    methods (Static)

        function H = create(rows, cols, cutoff, order)
            if nargin < 4
                order = 2;
            end

            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(order, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive', 'integer'});

            D = createFrequencyGrid(rows, cols);
            H = 1 ./ (1 + (D ./ cutoff).^(2 * order));
        end

        function filtered = apply(img, cutoff, order)
            if nargin < 3
                order = 2;
            end
            [filtered, ~] = ButterworthLowPassFilter.applyWithFilter(img, cutoff, order);
            filtered = max(0, min(1, filtered));
        end

        function filtered = applyRaw(img, cutoff, order)
            if nargin < 3
                order = 2;
            end
            [filtered, ~] = ButterworthLowPassFilter.applyWithFilter(img, cutoff, order);
        end

        function [filtered, H] = applyWithFilter(img, cutoff, order)
            if nargin < 3
                order = 2;
            end

            validateattributes(img, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(order, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive', 'integer'});

            img = im2double(img);
            [rows, cols] = size(img);

            F = fftshift(fft2(img));
            H = ButterworthLowPassFilter.create(rows, cols, cutoff, order);

            filtered = real(ifft2(ifftshift(F .* H)));
        end
    end
end