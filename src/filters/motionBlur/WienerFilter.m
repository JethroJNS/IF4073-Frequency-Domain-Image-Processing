% Restorasi dekonvolusi Wiener ranah frekuensi
classdef WienerFilter
    methods (Static)
        function W = createFilterMask(H, K)
            validateattributes(H, {'numeric'}, {'2d', 'finite', 'nonempty'});
            [rows, cols] = size(H);

            if nargin < 2 || isempty(K)
                K = 0.01;
            end
            validateattributes(K, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'});

            magH2 = abs(H).^2;
            denom = magH2 + K;

            W = zeros(rows, cols);
            valid = denom > 0;
            W(valid) = conj(H(valid)) ./ denom(valid);
        end

        function filtered = apply(img, H, K)
            if nargin < 3; K = []; end
            [filtered, ~] = WienerFilter.applyWithFilter(img, H, K);
            filtered = max(0, min(1, filtered));
        end

        function filtered = applyRaw(img, H, K)
            if nargin < 3; K = []; end
            [filtered, ~] = WienerFilter.applyWithFilter(img, H, K);
        end

        function [filtered, W] = applyWithFilter(img, H, K)
            if nargin < 3; K = []; end

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

            W = WienerFilter.createFilterMask(H, K);

            if isColor
                filtered = zeros(size(img));
                for ch = 1:3
                    F = fftshift(fft2(img(:, :, ch)));
                    filtered(:, :, ch) = real(ifft2(ifftshift(F .* W)));
                end
            else
                F = fftshift(fft2(img));
                filtered = real(ifft2(ifftshift(F .* W)));
            end
        end
    end
end
