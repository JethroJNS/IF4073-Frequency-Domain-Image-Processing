% Test script for High-Pass Filters
% Tests IHPF, GHPF, and BHPF using official test images
% Menampilkan hasil raw + normalized untuk mengatasi visualisasi HPF yang gelap

function testHighPassFilters()
    fprintf('==============================================\n');
    fprintf('  Testing High-Pass Filters\n');
    fprintf('==============================================\n\n');

    testDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testDir);
    addpath(genpath(fullfile(repoRoot, 'src')));

    basePath = fullfile(repoRoot, 'data', 'C_high_pass_filtering_frequency', 'input');

    testImages = {
        'coins_gray.png', 'grayscale';
        'text_gray.png', 'grayscale';
        'hubble_color.png', 'color';
        'retina_color.png', 'color'
    };

    cutoff = 30;
    order = 2;
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

            % Apply filters (raw = clipped)
            if isColor
                ihpf = zeros(size(img)); ghpf = zeros(size(img)); bhpf = zeros(size(img));
                for ch = 1:3
                    ihpf(:, :, ch) = IdealHighPassFilter.apply(img(:, :, ch), cutoff);
                    ghpf(:, :, ch) = GaussianHighPassFilter.apply(img(:, :, ch), cutoff);
                    bhpf(:, :, ch) = ButterworthHighPassFilter.apply(img(:, :, ch), cutoff, order);
                end
            else
                ihpf = IdealHighPassFilter.apply(img, cutoff);
                ghpf = GaussianHighPassFilter.apply(img, cutoff);
                bhpf = ButterworthHighPassFilter.apply(img, cutoff, order);
            end

            % Normalisasi untuk visualisasi
            ihpf_disp = normalizeForDisplay(ihpf);
            ghpf_disp = normalizeForDisplay(ghpf);
            bhpf_disp = normalizeForDisplay(bhpf);

            % RAW (clipped)
            figure('Name', ['HPF Raw (Clipped): ' imgName], ...
                'Position', [50, 50, 1100, 700]);
            colormap gray;

            subplot(2, 4, 1); imshow(img);
            title('Original', 'FontSize', 10);
            xlabel(sprintf('Size: %dx%d', rows, cols));

            subplot(2, 4, 2); imshow(ihpf);
            title('IHPF (raw)', 'FontSize', 10);

            subplot(2, 4, 3); imshow(ghpf);
            title('GHPF (raw)', 'FontSize', 10);

            subplot(2, 4, 4); imshow(bhpf);
            title('BHPF (raw)', 'FontSize', 10);

            H_ihpf = IdealHighPassFilter.create(rows, cols, cutoff);
            H_ghpf = GaussianHighPassFilter.create(rows, cols, cutoff);
            H_bhpf = ButterworthHighPassFilter.create(rows, cols, cutoff, order);

            subplot(2, 4, 5); imshow(H_ihpf, []);
            title('IHPF Mask', 'FontSize', 10);

            subplot(2, 4, 6); imshow(H_ghpf, []);
            title('GHPF Mask', 'FontSize', 10);

            subplot(2, 4, 7); imshow(H_bhpf, []);
            title('BHPF Mask', 'FontSize', 10);

            subplot(2, 4, 8);
            grayImg = img;
            if isColor
                grayImg = 0.2989 * img(:, :, 1) + 0.5870 * img(:, :, 2) + 0.1140 * img(:, :, 3);
            end
            F = fftshift(fft2(grayImg));
            spectrum = log(1 + abs(F));
            imshow(spectrum, []);
            title('Spectrum', 'FontSize', 10);

            % NORMALIZED (untuk visualisasi)
            figure('Name', ['HPF Normalized (Display): ' imgName], ...
                'Position', [100, 100, 1100, 500]);
            colormap gray;

            subplot(1, 4, 1); imshow(img);
            title('Original', 'FontSize', 10);

            subplot(1, 4, 2); imshow(ihpf_disp);
            title('IHPF (min-max normalized)', 'FontSize', 10);

            subplot(1, 4, 3); imshow(ghpf_disp);
            title('GHPF (min-max normalized)', 'FontSize', 10);

            subplot(1, 4, 4); imshow(bhpf_disp);
            title('BHPF (min-max normalized)', 'FontSize', 10);

            fprintf('  - Testing IHPF... ');
            assert(size(H_ihpf, 1) == rows, 'IHPF: Incorrect row size');
            assert(size(H_ihpf, 2) == cols, 'IHPF: Incorrect column size');
            assert(min(ihpf(:)) >= 0, 'IHPF: Negative values in output');
            assert(max(ihpf(:)) <= 1, 'IHPF: Values exceed 1');
            fprintf('PASS\n');

            fprintf('  - Testing GHPF... ');
            assert(size(H_ghpf, 1) == rows, 'GHPF: Incorrect row size');
            assert(size(H_ghpf, 2) == cols, 'GHPF: Incorrect column size');
            assert(min(ghpf(:)) >= 0, 'GHPF: Negative values in output');
            assert(max(ghpf(:)) <= 1, 'GHPF: Values exceed 1');
            fprintf('PASS\n');

            fprintf('  - Testing BHPF... ');
            assert(size(H_bhpf, 1) == rows, 'BHPF: Incorrect row size');
            assert(size(H_bhpf, 2) == cols, 'BHPF: Incorrect column size');
            assert(min(bhpf(:)) >= 0, 'BHPF: Negative values in output');
            assert(max(bhpf(:)) <= 1, 'BHPF: Values exceed 1');
            fprintf('PASS\n');

            fprintf('  - Testing edge preservation... ');
            variance_orig = var(img(:));
            variance_ihpf = var(ihpf(:));
            assert(variance_ihpf ~= variance_orig, 'HPF should change image variance');
            fprintf('PASS\n');

            fprintf('  - Testing different cutoffs... ');
            for c = [10, 20, 50, 80]
                if isColor
                    filtered = zeros(size(img));
                    for ch = 1:3
                        filtered(:, :, ch) = IdealHighPassFilter.apply(img(:, :, ch), c);
                    end
                else
                    filtered = IdealHighPassFilter.apply(img, c);
                end
                assert(min(filtered(:)) >= 0 && max(filtered(:)) <= 1, ...
                    'HPF with cutoff %d: Invalid output range', c);
            end
            fprintf('PASS\n');

            fprintf('  - Testing different Butterworth orders... ');
            for n = [1, 2, 3, 4]
                if isColor
                    filtered = zeros(size(img));
                    for ch = 1:3
                        filtered(:, :, ch) = ButterworthHighPassFilter.apply(img(:, :, ch), cutoff, n);
                    end
                else
                    filtered = ButterworthHighPassFilter.apply(img, cutoff, n);
                end
                assert(min(filtered(:)) >= 0 && max(filtered(:)) <= 1, ...
                    'BHPF with order %d: Invalid output range', n);
            end
            fprintf('PASS\n');

            fprintf('  - Testing HPF-LPF relationship... ');
            H_lpf = IdealLowPassFilter.create(rows, cols, cutoff);
            H_hpf = IdealHighPassFilter.create(rows, cols, cutoff);
            combined = H_lpf + H_hpf;
            assert(sum(abs(combined(:) - 1) < 0.01) == numel(combined), ...
                'HPF and LPF should be complementary');
            fprintf('PASS\n');

            passedTests = passedTests + 1;
            fprintf('  [RESULT] All HPF tests passed for %s!\n', imgName);

        catch err
            fprintf('  [FAIL] %s\n', err.message);
        end

        fprintf('\n');
    end

    fprintf('==============================================\n');
    fprintf('  High-Pass Filter Tests Summary\n');
    fprintf('==============================================\n');
    fprintf('  Passed: %d/%d\n', passedTests, totalTests);
    fprintf('==============================================\n');
end

function out = normalizeForDisplay(img)
    % Normalisasi min-max untuk visualisasi
    if size(img, 3) == 3
        out = zeros(size(img));
        for ch = 1:3
            ch_data = img(:, :, ch);
            mn = min(ch_data(:));
            mx = max(ch_data(:));
            if mx > mn
                out(:, :, ch) = (ch_data - mn) / (mx - mn);
            else
                out(:, :, ch) = ch_data;
            end
        end
    else
        mn = min(img(:));
        mx = max(img(:));
        if mx > mn
            out = (img - mn) / (mx - mn);
        else
            out = img;
        end
    end
end