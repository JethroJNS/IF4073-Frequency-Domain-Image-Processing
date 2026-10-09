classdef ButterworthHighPassFilter
    methods (Static)

        function H = create(rows, cols, cutoff, order)
            % create - Create Butterworth High-Pass Filter mask
            %
            % Rumus: H(D) = 1 / (1 + (cutoff/D)^(2n))
            % Sigmoid stabil secara numerik (hindari overflow).

            if nargin < 4
                order = 2;
            end

            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(order, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive', 'integer'});

            D = createFrequencyGrid(rows, cols);

            H = zeros(rows, cols);
            nonzero = D > 0;

            logRatio = log(cutoff) - log(D(nonzero));
            x = 2 * order .* logRatio;

            h = zeros(size(x));

            idxPos = x >= 0;
            expNeg = exp(-x(idxPos));
            h(idxPos) = expNeg ./ (1 + expNeg);

            idxNeg = ~idxPos;
            expPos = exp(x(idxNeg));
            h(idxNeg) = 1 ./ (1 + expPos);

            H(nonzero) = h;
        end

        function filtered = apply(img, cutoff, order)
            if nargin < 3
                order = 2;
            end
            [filtered, ~] = ButterworthHighPassFilter.applyWithFilter(img, cutoff, order);
            filtered = max(0, min(1, filtered));
        end

        function filtered = applyRaw(img, cutoff, order)
            if nargin < 3
                order = 2;
            end
            [filtered, ~] = ButterworthHighPassFilter.applyWithFilter(img, cutoff, order);
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
            H = ButterworthHighPassFilter.create(rows, cols, cutoff, order);

            filtered = real(ifft2(ifftshift(F .* H)));
        end
    end
end