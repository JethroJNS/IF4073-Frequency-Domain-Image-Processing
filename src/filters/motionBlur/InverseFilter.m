% Restorasi dekonvolusi invers ranah frekuensi
classdef InverseFilter
    methods (Static)
        function M_inv = createFilterMask(H, radiusCutoff, threshold)
            validateattributes(H, {'numeric'}, {'2d', 'finite', 'nonempty'});
            [rows, cols] = size(H);

            if nargin < 2 || isempty(radiusCutoff)
                radiusCutoff = min(rows, cols) / 3;
            end
            if nargin < 3 || isempty(threshold)
                threshold = 0.01;
            end

            validateattributes(radiusCutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(threshold, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});

            D = createFrequencyGrid(rows, cols);
            magH = abs(H);

            M_inv = zeros(rows, cols);
            valid = (D <= radiusCutoff) & (magH >= threshold);
            M_inv(valid) = 1 ./ H(valid);
        end

        function filtered = apply(img, H, radiusCutoff, threshold)
            if nargin < 3; radiusCutoff = []; end
            if nargin < 4; threshold = []; end
            [filtered, ~] = InverseFilter.applyWithFilter(img, H, radiusCutoff, threshold);
            filtered = max(0, min(1, filtered));
        end

        function filtered = applyRaw(img, H, radiusCutoff, threshold)
            if nargin < 3; radiusCutoff = []; end
            if nargin < 4; threshold = []; end
            [filtered, ~] = InverseFilter.applyWithFilter(img, H, radiusCutoff, threshold);
        end

        function [filtered, M_inv] = applyWithFilter(img, H, radiusCutoff, threshold)
            if nargin < 3; radiusCutoff = []; end
            if nargin < 4; threshold = []; end

            validateattributes(img, {'numeric'}, {'real', 'finite', 'nonempty'});
            if ~isa(img, 'double')
                img = im2double(img);
            end

            if ndims(img) == 2
                isColor = false;
            elseif ndims(img) == 3 && size(img, 3) == 3
                isColor = true;
            else
                error('Input image must be 2D grayscale or 3D RGB.');
            end

            [rows, cols, ~] = size(img);
            if size(H, 1) ~= rows || size(H, 2) ~= cols
                error('Degradation function H (%dx%d) does not match image (%dx%d).', ...
                    size(H, 1), size(H, 2), rows, cols);
            end

            M_inv = InverseFilter.createFilterMask(H, radiusCutoff, threshold);

            if isColor
                filtered = zeros(size(img));
                for ch = 1:3
                    F = fftshift(fft2(img(:, :, ch)));
                    filtered(:, :, ch) = real(ifft2(ifftshift(F .* M_inv)));
                end
            else
                F = fftshift(fft2(img));
                filtered = real(ifft2(ifftshift(F .* M_inv)));
            end
        end
    end
end
