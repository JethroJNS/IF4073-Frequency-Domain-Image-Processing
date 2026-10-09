% Test script for Brightness Enhancement in Frequency Domain

function testBrightnessEnhancement()
    fprintf('==============================================\n');
    fprintf('  Testing Brightness Enhancement\n');
    fprintf('==============================================\n\n');

    testDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testDir);
    addpath(genpath(fullfile(repoRoot, 'src')));

    basePath = fullfile(repoRoot, 'data', 'D_brightness_frequency', 'input');

    testImages = {
        'cell_gray_dark.png', 'grayscale';
        'coins_gray_dark.png', 'grayscale';
        'ihc_color_dark.png', 'color';
        'retina_color_dark.png', 'color'
    };

    gain = 2.0;
    cutoff = 30;
    passedTests = 0;
    totalTests = 0;

    for i = 1:size(testImages, 1)
        imgName = testImages{i, 1};
        imgType = testImages{i, 2};
        imgPath = fullfile(basePath, imgName);

        fprintf('Testing: %s (%s)\n', imgName, imgType);
        totalTests = totalTests + 1;

        if ~exist(imgPath, 'file')
            fprintf('  [SKIP] Image not found: %s\n', imgPath);
            continue;
        end

        try
            img = imread(imgPath);
            img = im2double(img);
            isColor = size(img, 3) == 3;
            [rows, cols] = size(img);

            mean_orig = mean(img(:));

            if isColor
                dc = zeros(size(img)); lowfreq = zeros(size(img));
                for ch = 1:3
                    dc(:, :, ch) = BrightnessEnhancement.enhanceDC(img(:, :, ch), gain);
                    lowfreq(:, :, ch) = BrightnessEnhancement.enhanceLowFrequency(img(:, :, ch), gain, cutoff);
                end
            else
                dc = BrightnessEnhancement.enhanceDC(img, gain);
                lowfreq = BrightnessEnhancement.enhanceLowFrequency(img, gain, cutoff);
            end

            mean_dc = mean(dc(:));
            mean_low = mean(lowfreq(:));

            figure('Name', ['Brightness Results: ' imgName], ...
                'Position', [100, 100, 1100, 600]);

            subplot(2, 3, 1);
            imshow(img);
            title(sprintf('Original\nMean: %.4f', mean_orig), 'FontSize', 10);
            xlabel(sprintf('Size: %dx%d', rows, cols));

            subplot(2, 3, 2);
            imshow(dc);
            title(sprintf('DC Boost (gain=%.1f)\nMean: %.4f (%.2fx)', ...
                gain, mean_dc, mean_dc/mean_orig), 'FontSize', 10);

            subplot(2, 3, 3);
            imshow(lowfreq);
            title(sprintf('Low Freq Boost\nMean: %.4f (%.2fx)', ...
                mean_low, mean_low/mean_orig), 'FontSize', 10);

            subplot(2, 3, 4);
            H_dc = ones(rows, cols);
            imshow(H_dc);
            title('DC Boost Mask', 'FontSize', 10);

            subplot(2, 3, 5);
            grayImg = img;
            if isColor
                grayImg = 0.2989 * img(:, :, 1) + 0.5870 * img(:, :, 2) + 0.1140 * img(:, :, 3);
            end
            D = createFrequencyGrid(rows, cols);
            H_lowfreq = ones(rows, cols);
            H_lowfreq(D <= cutoff) = gain;
            imshow(H_lowfreq, []);
            title(sprintf('Low Freq Mask\n(cutoff=%d, gain=%.1f)', cutoff, gain), 'FontSize', 10);

            subplot(2, 3, 6);
            grayDc = dc;
            if isColor
                grayDc = 0.2989 * dc(:, :, 1) + 0.5870 * dc(:, :, 2) + 0.1140 * dc(:, :, 3);
            end
            F_orig = fftshift(fft2(grayImg));
            F_dc = fftshift(fft2(grayDc));
            spectrum_orig = log(1 + abs(F_orig));
            spectrum_dc = log(1 + abs(F_dc));
            combined_spectrum = cat(2, ...
                spectrum_orig / max(spectrum_orig(:)), ...
                spectrum_dc / max(spectrum_dc(:)));
            imshow(combined_spectrum, []);
            title('Original (L) vs DC Boost (R) Spectrum', 'FontSize', 10);

            fprintf('  - Testing DC Component Boost... ');
            assert(mean_dc > mean_orig, 'DC enhancement should increase brightness');
            assert(min(dc(:)) >= 0, 'Output should have no negative values');
            assert(max(dc(:)) <= 1, 'Output should not exceed 1');
            fprintf('PASS (%.4f -> %.4f, %.2fx)\n', mean_orig, mean_dc, mean_dc/mean_orig);

            fprintf('  - Testing Low Frequency Boost... ');
            assert(mean_low > mean_orig, 'Low freq enhancement should increase brightness');
            assert(min(lowfreq(:)) >= 0, 'Output should have no negative values');
            assert(max(lowfreq(:)) <= 1, 'Output should not exceed 1');
            fprintf('PASS (%.4f -> %.4f, %.2fx)\n', mean_orig, mean_low, mean_low/mean_orig);

            fprintf('  - Testing Power Law Enhancement... ');
            params.method = 'power';
            params.gamma = 1.5;
            params.gain = gain;
            if isColor
                filtered_power = zeros(size(img));
                for ch = 1:3
                    [filtered_power(:, :, ch), H_power] = BrightnessEnhancement.apply(img(:, :, ch), params);
                end
            else
                [filtered_power, H_power] = BrightnessEnhancement.apply(img, params);
            end
            mean_power = mean(filtered_power(:));

            assert(min(filtered_power(:)) >= 0, 'Power law: Negative values in output');
            assert(max(filtered_power(:)) <= 1, 'Power law: Values exceed 1');
            fprintf('PASS (%.4f -> %.4f)\n', mean_orig, mean_power);

            fprintf('  - Testing different gain values... ');
            for g = [1.5, 2.0, 2.5, 3.0]
                if isColor
                    filtered = zeros(size(img));
                    for ch = 1:3
                        filtered(:, :, ch) = BrightnessEnhancement.enhanceDC(img(:, :, ch), g);
                    end
                else
                    filtered = BrightnessEnhancement.enhanceDC(img, g);
                end
                mean_filtered = mean(filtered(:));
                assert(mean_filtered > mean_orig, 'Gain %.1f: Brightness should increase', g);
                assert(max(filtered(:)) <= 1, 'Gain %.1f: Values should not exceed 1', g);
            end
            fprintf('PASS\n');

            fprintf('  - Testing different cutoffs... ');
            for c = [10, 20, 50, 80]
                if isColor
                    filtered = zeros(size(img));
                    for ch = 1:3
                        filtered(:, :, ch) = BrightnessEnhancement.enhanceLowFrequency(img(:, :, ch), gain, c);
                    end
                else
                    filtered = BrightnessEnhancement.enhanceLowFrequency(img, gain, c);
                end
                assert(min(filtered(:)) >= 0 && max(filtered(:)) <= 1, ...
                    'Cutoff %d: Invalid output range', c);
            end
            fprintf('PASS\n');

            % Test Selective Enhancement (grayscale only) + visualisasi
            if ~isColor
                fprintf('  - Testing Selective Enhancement... ');
                params.method = 'selective';
                params.cutoffLow = 20;
                params.cutoffHigh = 60;
                params.gainLow = 2.5;
                params.gainHigh = 1.5;
                [filtered_sel, H_sel] = BrightnessEnhancement.apply(img, params);

                assert(min(filtered_sel(:)) >= 0, 'Selective: Negative values');
                assert(max(filtered_sel(:)) <= 1, 'Selective: Values exceed 1');

                mean_sel = mean(filtered_sel(:));
                fprintf('PASS (mean %.4f -> %.4f)\n', mean_orig, mean_sel);

                % Visualisasi tambahan untuk selective
                figure('Name', ['Selective Enhancement: ' imgName], ...
                    'Position', [150, 150, 900, 400]);

                subplot(1, 4, 1); imshow(img);
                title(sprintf('Original\nMean: %.4f', mean_orig));

                subplot(1, 4, 2); imshow(filtered_sel);
                title(sprintf('Selective\nMean: %.4f', mean_sel));

                subplot(1, 4, 3); imshow(H_sel, []);
                title(sprintf('Mask\n[%d, %d] gL=%.1f gH=%.1f', ...
                    params.cutoffLow, params.cutoffHigh, ...
                    params.gainLow, params.gainHigh));
                colorbar;

                subplot(1, 4, 4);
                plot(H_sel(floor(rows/2)+1, :), 'LineWidth', 1.5);
                title('Mask Cross-section (row center)');
                xlabel('Column'); ylabel('H(u,v)');
                grid on;
            end

            % Test frequency domain properties
            fprintf('  - Testing frequency domain properties... ');
            F_orig = fftshift(fft2(grayImg));
            centerRow = floor(size(grayImg, 1) / 2) + 1;
            centerCol = floor(size(grayImg, 2) / 2) + 1;
            dc_orig = abs(F_orig(centerRow, centerCol));

            grayFiltered = dc;
            if isColor
                grayFiltered = 0.2989 * dc(:, :, 1) + 0.5870 * dc(:, :, 2) + 0.1140 * dc(:, :, 3);
            end
            F_filtered = fftshift(fft2(grayFiltered));
            dc_filtered = abs(F_filtered(centerRow, centerCol));

            ratio = dc_filtered / dc_orig;
            assert(abs(ratio - gain) < 0.5, ...
                'DC ratio mismatch: expected %.2f, got %.2f', gain, ratio);
            fprintf('PASS (DC ratio: %.2f)\n', ratio);

            passedTests = passedTests + 1;
            fprintf('  [RESULT] All brightness tests passed for %s!\n', imgName);

        catch err
            fprintf('  [FAIL] %s\n', err.message);
        end

        fprintf('\n');
    end

    fprintf('==============================================\n');
    fprintf('  Brightness Enhancement Tests Summary\n');
    fprintf('==============================================\n');
    fprintf('  Passed: %d/%d\n', passedTests, totalTests);
    fprintf('==============================================\n');
end