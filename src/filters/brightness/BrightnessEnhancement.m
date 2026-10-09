classdef BrightnessEnhancement
    methods (Static)

        % DC boost
        function filtered = enhanceDC(img, gain)
            % enhanceDC - Boost DC component (versi ter-clip)
            filtered = BrightnessEnhancement.enhanceDCRaw(img, gain);
            filtered = max(0, min(1, filtered));
        end

        function filtered = enhanceDCRaw(img, gain)
            % enhanceDCRaw - Respons matematis murni DC boost
            validateattributes(img, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});
            validateattributes(gain, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});

            img = im2double(img);
            [rows, cols] = size(img);

            F = fftshift(fft2(img));
            centerRow = floor(rows / 2) + 1;
            centerCol = floor(cols / 2) + 1;

            F(centerRow, centerCol) = F(centerRow, centerCol) * gain;

            filtered = real(ifft2(ifftshift(F)));
        end

        % Low-frequency boost
        function [filtered, H] = enhanceLowFrequency(img, gain, cutoff)
            % enhanceLowFrequency - Boost low frequencies (versi ter-clip)
            [filtered, H] = BrightnessEnhancement.enhanceLowFrequencyRaw(img, gain, cutoff);
            filtered = max(0, min(1, filtered));
        end

        function [filtered, H] = enhanceLowFrequencyRaw(img, gain, cutoff)
            % enhanceLowFrequencyRaw - Respons matematis murni
            validateattributes(img, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});
            validateattributes(gain, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});
            validateattributes(cutoff, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'nonnegative'});

            img = im2double(img);
            [rows, cols] = size(img);
            F = fftshift(fft2(img));
            D = createFrequencyGrid(rows, cols);

            H = BrightnessEnhancement.buildLowFreqMask(D, gain, cutoff);

            filtered = real(ifft2(ifftshift(F .* H)));
        end

        % Generic enhance (with mask)
        function [filtered, H] = enhanceWithMask(img, params)
            % enhanceWithMask - Generic brightness enhancement (versi ter-clip)
            [filtered, H] = BrightnessEnhancement.enhanceWithMaskRaw(img, params);
            filtered = max(0, min(1, filtered));
        end

        function [filtered, H] = enhanceWithMaskRaw(img, params)
            % enhanceWithMaskRaw - Generic brightness enhancement (respons murni)
            [filtered, H] = BrightnessEnhancement.applyInternal(img, params);
        end

        % Main API

        function [enhanced, H] = apply(img, params)
            % apply - Main method (versi ter-clip ke [0,1])
            [enhanced, H] = BrightnessEnhancement.applyInternal(img, params);
            enhanced = max(0, min(1, enhanced));
        end

        function [enhanced, H] = applyRaw(img, params)
            % applyRaw - Respons matematis murni tanpa clipping
            [enhanced, H] = BrightnessEnhancement.applyInternal(img, params);
        end

        % Spatial gamma
        function enhanced = applySpatialGamma(img, gamma)
            % applySpatialGamma - Gamma correction SPASIAL standar
            %   g(x,y) = f(x,y)^gamma
            % Ini BUKAN metode power law frekuensi.
            validateattributes(img, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});
            validateattributes(gamma, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});

            img = im2double(img);
            img = max(0, min(1, img));
            enhanced = img .^ gamma;
        end
    end

    methods (Static, Access = private)

        function [enhanced, H] = applyInternal(img, params)
            % applyInternal - Satu-satunya implementasi inti. Semua method
            % publik (apply/applyRaw/enhanceWithMask/enhanceWithMaskRaw)
            % memanggil fungsi ini agar tidak ada duplikasi kode.
            validateattributes(img, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});

            if ~isstruct(params) || ~isfield(params, 'method')
                error('params harus berupa struct dengan field method.');
            end

            img = im2double(img);
            [rows, cols] = size(img);
            F = fftshift(fft2(img));

            method = params.method;

            switch method
                case 'dc'
                    validateattributes(params.gain, {'numeric'}, ...
                        {'scalar', 'real', 'finite', 'positive'});

                    H = ones(rows, cols);
                    centerRow = floor(rows / 2) + 1;
                    centerCol = floor(cols / 2) + 1;
                    H(centerRow, centerCol) = params.gain;

                    G = F .* H;

                case 'lowfreq'
                    validateattributes(params.gain, {'numeric'}, ...
                        {'scalar', 'real', 'finite', 'positive'});
                    validateattributes(params.cutoff, {'numeric'}, ...
                        {'scalar', 'real', 'finite', 'nonnegative'});

                    D = createFrequencyGrid(rows, cols);
                    H = BrightnessEnhancement.buildLowFreqMask(D, params.gain, params.cutoff);
                    G = F .* H;

                case 'selective'
                    validateattributes(params.cutoffLow, {'numeric'}, ...
                        {'scalar', 'real', 'finite', 'nonnegative'});
                    validateattributes(params.cutoffHigh, {'numeric'}, ...
                        {'scalar', 'real', 'finite', 'positive'});
                    validateattributes(params.gainLow, {'numeric'}, ...
                        {'scalar', 'real', 'finite', 'positive'});
                    validateattributes(params.gainHigh, {'numeric'}, ...
                        {'scalar', 'real', 'finite', 'positive'});

                    cutoffLow = params.cutoffLow;
                    cutoffHigh = params.cutoffHigh;
                    gainLow = params.gainLow;
                    gainHigh = params.gainHigh;

                    if cutoffHigh <= cutoffLow
                        error('cutoffHigh harus lebih besar dari cutoffLow.');
                    end

                    D = createFrequencyGrid(rows, cols);
                    H = ones(rows, cols);

                    H(D <= cutoffLow) = gainLow;
                    H(D > cutoffLow & D <= cutoffHigh) = gainHigh;

                    G = F .* H;

                case 'power'
                    validateattributes(params.gamma, {'numeric'}, ...
                        {'scalar', 'real', 'finite', 'positive'});

                    [G, H] = BrightnessEnhancement.applyPower(F, params.gamma, rows, cols);

                otherwise
                    error('Unknown method: %s', method);
            end

            enhanced = real(ifft2(ifftshift(G)));
        end

        function H = buildLowFreqMask(D, gain, cutoff)
            [rows, cols] = size(D);
            H = ones(rows, cols);

            if cutoff == 0
                centerRow = floor(rows / 2) + 1;
                centerCol = floor(cols / 2) + 1;
                H(centerRow, centerCol) = gain;
            else
                sigma = cutoff / 3;
                H = 1 + (gain - 1) .* exp(-(D.^2) ./ (2 * sigma^2));
            end
        end

        function [G, H] = applyPower(F, gamma, rows, cols)
            % applyPower - Power law pada magnitudo spektrum, mempertahankan
            % fase. Normalisasi mempertahankan magnitudo maksimum.
            %
            % CATATAN: BUKAN gamma correction spasial g(x,y) = f(x,y)^gamma.
            magnitude = abs(F);
            phase = angle(F);

            originalMax = max(magnitude(:));
            transformed = magnitude .^ gamma;
            transformedMax = max(transformed(:));

            if transformedMax > 0
                transformed = transformed .* (originalMax / transformedMax);
            end

            G = transformed .* exp(1i * phase);
            H = ones(rows, cols);
        end
    end
end