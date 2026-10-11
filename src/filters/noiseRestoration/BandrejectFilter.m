% Bandreject filter ranah frekuensi (Ideal, Butterworth, Gaussian)
classdef BandrejectFilter
    properties (SetAccess = private)
        mask
        rows
        cols
        filterType
        cutoff
        bandwidth
        order
    end

    methods
        function obj = BandrejectFilter(rows, cols, filterType, cutoff, bandwidth, order)
            if nargin < 6
                order = 2;
            end

            validateattributes(rows, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cols, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(bandwidth, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(order, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});

            validTypes = {'ideal', 'butterworth', 'gaussian'};
            filterType = validatestring(lower(filterType), validTypes);

            if cutoff - (bandwidth / 2) <= 0
                error('Cutoff must be strictly greater than half bandwidth (cutoff - bandwidth/2 > 0).');
            end

            obj.rows = rows;
            obj.cols = cols;
            obj.filterType = filterType;
            obj.cutoff = cutoff;
            obj.bandwidth = bandwidth;
            obj.order = order;
            obj.mask = BandrejectFilter.createMask(rows, cols, filterType, cutoff, bandwidth, order);
        end

        function filtered = apply(obj, img)
            [filtered, ~] = obj.applyWithFilter(img);
            filtered = max(0, min(1, filtered));
        end

        function filtered = applyRaw(obj, img)
            [filtered, ~] = obj.applyWithFilter(img);
        end

        function [filtered, H] = applyWithFilter(obj, img)
            filtered = obj.filterInternal(img);
            H = obj.mask;
        end

        function H = double(obj)
            H = obj.mask;
        end
    end

    methods (Static)
        function filter = create(rows, cols, filterType, cutoff, bandwidth, order)
            if nargin < 6
                order = 2;
            end
            filter = BandrejectFilter(rows, cols, filterType, cutoff, bandwidth, order);
        end

        function H = createMask(rows, cols, filterType, cutoff, bandwidth, order)
            if nargin < 6
                order = 2;
            end

            validateattributes(rows, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cols, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(bandwidth, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(order, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});

            validTypes = {'ideal', 'butterworth', 'gaussian'};
            filterType = validatestring(lower(filterType), validTypes);

            D = createFrequencyGrid(rows, cols);

            switch filterType
                case 'ideal'
                    dLow = cutoff - (bandwidth / 2);
                    dHigh = cutoff + (bandwidth / 2);
                    H = ones(rows, cols);
                    H(D >= dLow & D <= dHigh) = 0;

                case 'butterworth'
                    denom = D.^2 - cutoff^2;
                    H = ones(rows, cols);
                    idxZero = (denom == 0);
                    idxNonzero = ~idxZero;
                    ratio = (D(idxNonzero) * bandwidth) ./ denom(idxNonzero);
                    H(idxNonzero) = 1 ./ (1 + ratio.^(2 * order));
                    H(idxZero) = 0;

                case 'gaussian'
                    H = ones(rows, cols);
                    denom = D * bandwidth;
                    idxZero = (denom == 0);
                    idxMatch = (D == cutoff);
                    idxNormal = ~idxZero & ~idxMatch;

                    term = (D(idxNormal).^2 - cutoff^2) ./ denom(idxNormal);
                    H(idxNormal) = 1 - exp(-0.5 * (term.^2));
                    H(idxMatch) = 0;
                    H(idxZero) = 1;
            end
        end
    end

    methods (Access = private)
        function filtered = filterInternal(obj, img)
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

            [r, c, ~] = size(img);
            if r ~= obj.rows || c ~= obj.cols
                error('Image size (%dx%d) does not match filter size (%dx%d).', ...
                    r, c, obj.rows, obj.cols);
            end

            if isColor
                filtered = zeros(size(img));
                for ch = 1:3
                    F = fftshift(fft2(img(:, :, ch)));
                    filtered(:, :, ch) = real(ifft2(ifftshift(F .* obj.mask)));
                end
            else
                F = fftshift(fft2(img));
                filtered = real(ifft2(ifftshift(F .* obj.mask)));
            end
        end
    end
end
