% Notch reject filter ranah frekuensi (Ideal, Butterworth, Gaussian)
classdef NotchRejectFilter
    properties (SetAccess = private)
        mask
        rows
        cols
        filterType
        notchCenters
        D0
        order
    end

    methods
        function obj = NotchRejectFilter(rows, cols, filterType, notchCenters, D0, order)
            if nargin < 6
                order = 2;
            end

            validateattributes(rows, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cols, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(D0, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(order, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});

            validTypes = {'ideal', 'butterworth', 'gaussian'};
            filterType = validatestring(lower(filterType), validTypes);

            if ~isempty(notchCenters)
                validateattributes(notchCenters, {'numeric'}, ...
                    {'2d', 'real', 'finite'});
                if size(notchCenters, 2) ~= 2
                    error('notchCenters must be a K x 2 matrix with columns [u, v].');
                end
            end

            obj.rows = rows;
            obj.cols = cols;
            obj.filterType = filterType;
            obj.notchCenters = notchCenters;
            obj.D0 = D0;
            obj.order = order;
            obj.mask = NotchRejectFilter.createMask(rows, cols, filterType, notchCenters, D0, order);
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
        function filter = create(rows, cols, filterType, notchCenters, D0, order)
            if nargin < 6
                order = 2;
            end
            filter = NotchRejectFilter(rows, cols, filterType, notchCenters, D0, order);
        end

        function H = createMask(rows, cols, filterType, notchCenters, D0, order)
            if nargin < 6
                order = 2;
            end

            validateattributes(rows, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cols, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(D0, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(order, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});

            validTypes = {'ideal', 'butterworth', 'gaussian'};
            filterType = validatestring(lower(filterType), validTypes);

            H = ones(rows, cols);
            if isempty(notchCenters)
                return;
            end

            validateattributes(notchCenters, {'numeric'}, ...
                {'2d', 'real', 'finite'});
            if size(notchCenters, 2) ~= 2
                error('notchCenters must be a K x 2 matrix with columns [u, v].');
            end

            [U, V, ~] = createFrequencyCoordinates(rows, cols);

            for k = 1:size(notchCenters, 1)
                uk = notchCenters(k, 1);
                vk = notchCenters(k, 2);

                if uk == 0 && vk == 0
                    warning('NotchRejectFilter:DCNotchIgnored', ...
                        'Notch at (0,0) is ignored to preserve image DC component.');
                    continue;
                end

                du_k = min(mod(abs(U - uk), cols), cols - mod(abs(U - uk), cols));
                dv_k = min(mod(abs(V - vk), rows), rows - mod(abs(V - vk), rows));
                D_k = hypot(du_k, dv_k);

                du_minus_k = min(mod(abs(U + uk), cols), cols - mod(abs(U + uk), cols));
                dv_minus_k = min(mod(abs(V + vk), rows), rows - mod(abs(V + vk), rows));
                D_minus_k = hypot(du_minus_k, dv_minus_k);

                switch filterType
                    case 'ideal'
                        H_k = double(D_k > D0 & D_minus_k > D0);

                    case 'butterworth'
                        H1 = zeros(rows, cols);
                        idx1 = (D_k > 0);
                        H1(idx1) = 1 ./ (1 + (D0 ./ D_k(idx1)).^(2 * order));

                        H2 = zeros(rows, cols);
                        idx2 = (D_minus_k > 0);
                        H2(idx2) = 1 ./ (1 + (D0 ./ D_minus_k(idx2)).^(2 * order));

                        H_k = H1 .* H2;

                    case 'gaussian'
                        H1 = 1 - exp(-(D_k.^2) / (2 * D0^2));
                        H2 = 1 - exp(-(D_minus_k.^2) / (2 * D0^2));
                        H_k = H1 .* H2;
                end

                H = H .* H_k;
            end
        end

        function notchCoords = matrixIndexToFrequencyCoord(rows, cols, rowIdx, colIdx)
            validateattributes(rows, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cols, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(rowIdx, {'numeric'}, ...
                {'real', 'finite', 'integer', '>=', 1, '<=', rows});
            validateattributes(colIdx, {'numeric'}, ...
                {'real', 'finite', 'integer', '>=', 1, '<=', cols});

            if numel(rowIdx) ~= numel(colIdx)
                error('rowIdx and colIdx must have the same number of elements.');
            end

            r0 = floor(rows / 2) + 1;
            c0 = floor(cols / 2) + 1;

            u = colIdx - c0;
            v = rowIdx - r0;
            notchCoords = [u(:), v(:)];
        end

        function [rowIdx, colIdx] = frequencyCoordToMatrixIndex(rows, cols, u, v)
            validateattributes(rows, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cols, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});

            r0 = floor(rows / 2) + 1;
            c0 = floor(cols / 2) + 1;

            validateattributes(u, {'numeric'}, ...
                {'real', 'finite', 'integer', '>=', 1 - c0, '<=', cols - c0});
            validateattributes(v, {'numeric'}, ...
                {'real', 'finite', 'integer', '>=', 1 - r0, '<=', rows - r0});

            if numel(u) ~= numel(v)
                error('u and v must have the same number of elements.');
            end

            colIdx = u + c0;
            rowIdx = v + r0;
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
