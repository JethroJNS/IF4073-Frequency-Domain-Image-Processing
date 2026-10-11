% Model degradasi motion blur ranah frekuensi
classdef MotionBlurModel
    methods (Static)
        function H = create(rows, cols, L, theta, includePhase)
            if nargin < 5
                includePhase = false;
            end

            validateattributes(rows, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cols, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(L, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(theta, {'numeric'}, ...
                {'scalar', 'real', 'finite'});

            [U, V, ~] = createFrequencyCoordinates(rows, cols);

            rad = theta * pi / 180;
            a = L * cos(rad);
            b = L * sin(rad);

            s = (U / cols) * a - (V / rows) * b;
            H = sinc(s);

            if includePhase
                H = H .* exp(-1j * pi * s);
            end
        end

        function psf = createSpatialPSF(rows, cols, L, theta)
            validateattributes(rows, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(cols, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'integer', 'positive'});
            validateattributes(L, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(theta, {'numeric'}, ...
                {'scalar', 'real', 'finite'});

            rad = theta * pi / 180;
            halfL = (L - 1) / 2;
            dx = cos(rad);
            dy = -sin(rad);

            psf = zeros(rows, cols);
            r0 = floor(rows / 2) + 1;
            c0 = floor(cols / 2) + 1;

            numSamples = max(round(L * 4), 100);
            t = linspace(-halfL, halfL, numSamples);
            for i = 1:numSamples
                r = round(r0 + t(i) * dy);
                c = round(c0 + t(i) * dx);
                if r >= 1 && r <= rows && c >= 1 && c <= cols
                    psf(r, c) = psf(r, c) + 1;
                end
            end
            s = sum(psf(:));
            if s > 0
                psf = psf / s;
            end
        end
    end
end
