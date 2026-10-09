function testLowPassFilters()
    fprintf('==============================================\n');
    fprintf('  Testing Low-Pass Filters\n');
    fprintf('==============================================\n\n');

    testDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testDir);
    addpath(genpath(fullfile(repoRoot, 'src')));

    basePath = fullfile(repoRoot, 'data', 'B_smoothing_blurring_frequency', 'input');

    testImages = {
        'grass_gray_gaussian_noise.png', 'grayscale';
        'gravel_gray_gaussian_noise.png', 'grayscale';
        'astronaut_color_gaussian_noise.png', 'color';
        'rocket_color_gaussian_noise.png', 'color'
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

            % Apply filters (raw = untuk test, display = untuk visualisasi)
            if isColor
                ilpf = zeros(size(img)); glpf = zeros(size(img)); blpf = zeros(size(img));
                for ch = 1:3
                    ilpf(:, :, ch) = IdealLowPassFilter.apply(img(:, :, ch), cutoff);
                    glpf(:, :, ch) = GaussianLowPassFilter.apply(img(:, :, ch), cutoff);
                    blpf(:, :, ch) = ButterworthLowPassFilter.apply(img(:, :, ch), cutoff, order);
                end
            else
                ilpf = IdealLowPassFilter.apply(img, cutoff);
                glpf = GaussianLowPassFilter.apply(img, cutoff);
                blpf = ButterworthLowPassFilter.apply(img, cutoff, order);
            end

            % Buat versi normalized untuk visualisasi
            ilpf_disp = normalizeForDisplay(ilpf);
            glpf_disp = normalizeForDisplay(glpf);
            blpf_disp = normalizeForDisplay(blpf);

            % RAW (clipped)
            figure('Name', ['LPF Raw (Clipped): ' imgName], ...
                'Position', [50, 50, 1100, 700]);
            colormap gray;

            subplot(2, 4, 1); imshow(img);
            title('Original', 'FontSize', 10);
            xlabel(sprintf('Size: %dx%d', rows, cols));

            subplot(2, 4, 2); imshow(ilpf);
            title('ILPF (raw)', 'FontSize', 10);

            subplot(2, 4, 3); imshow(glpf);
            title('GLPF (raw)', 'FontSize', 10);

            subplot(2, 4, 4); imshow(blpf);
            title('BLPF (raw)', 'FontSize', 10);

            H_ilpf = IdealLowPassFilter.create(rows, cols, cutoff);
            H_glpf = GaussianLowPassFilter.create(rows, cols, cutoff);
            H_blpf = ButterworthLowPassFilter.create(rows, cols, cutoff, order);

            subplot(2, 4, 5); imshow(H_ilpf, []);
            title('ILPF Mask', 'FontSize', 10);

            subplot(2, 4, 6); imshow(H_glpf, []);
            title('GLPF Mask', 'FontSize', 10);

            subplot(2, 4, 7); imshow(H_blpf, []);
            title('BLPF Mask', 'FontSize', 10);

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
            figure('Name', ['LPF Normalized (Display): ' imgName], ...
                'Position', [100, 100, 1100, 500]);
            colormap gray;

            subplot(1, 4, 1); imshow(img);
            title('Original', 'FontSize', 10);

            subplot(1, 4, 2); imshow(ilpf_disp);
            title('ILPF (min-max normalized)', 'FontSize', 10);

            subplot(1, 4, 3); imshow(glpf_disp);
            title('GLPF (min-max normalized)', 'FontSize', 10);

            subplot(1, 4, 4); imshow(blpf_disp);
            title('BLPF (min-max normalized)', 'FontSize', 10);

            fprintf('  - Testing ILPF... ');
            assert(size(H_ilpf, 1) == rows, 'ILPF: Incorrect row size');
            assert(size(H_ilpf, 2) == cols, 'ILPF: Incorrect column size');
            assert(H_ilpf(floor(rows/2)+1, floor(cols/2)+1) == 1, 'ILPF: Center should be 1');
            assert(min(ilpf(:)) >= 0, 'ILPF: Negative values in output');
            assert(max(ilpf(:)) <= 1, 'ILPF: Values exceed 1');
            fprintf('PASS\n');

            fprintf('  - Testing GLPF... ');
            assert(size(H_glpf, 1) == rows, 'GLPF: Incorrect row size');
            assert(size(H_glpf, 2) == cols, 'GLPF: Incorrect column size');
            assert(max(H_glpf(:)) - 1 < 0.01, 'GLPF: Center should be ~1');
            assert(min(glpf(:)) >= 0, 'GLPF: Negative values in output');
            assert(max(glpf(:)) <= 1, 'GLPF: Values exceed 1');
            fprintf('PASS\n');

            fprintf('  - Testing BLPF... ');
            assert(size(H_blpf, 1) == rows, 'BLPF: Incorrect row size');
            assert(size(H_blpf, 2) == cols, 'BLPF: Incorrect column size');
            assert(abs(H_blpf(floor(rows/2)+1, floor(cols/2)+1) - 1) < 0.01, ...
                'BLPF: Center should be ~1');
            assert(min(blpf(:)) >= 0, 'BLPF: Negative values in output');
            assert(max(blpf(:)) <= 1, 'BLPF: Values exceed 1');
            fprintf('PASS\n');

            fprintf('  - Testing different cutoffs... ');
            for c = [10, 20, 50, 80]
                if isColor
                    filtered = zeros(size(img));
                    for ch = 1:3
                        filtered(:, :, ch) = IdealLowPassFilter.apply(img(:, :, ch), c);
                    end
                else
                    filtered = IdealLowPassFilter.apply(img, c);
                end
                assert(min(filtered(:)) >= 0 && max(filtered(:)) <= 1, ...
                    'LPF with cutoff %d: Invalid output range', c);
            end
            fprintf('PASS\n');

            fprintf('  - Testing different Butterworth orders... ');
            for n = [1, 2, 3, 4]
                if isColor
                    filtered = zeros(size(img));
                    for ch = 1:3
                        filtered(:, :, ch) = ButterworthLowPassFilter.apply(img(:, :, ch), cutoff, n);
                    end
                else
                    filtered = ButterworthLowPassFilter.apply(img, cutoff, n);
                end
                assert(min(filtered(:)) >= 0 && max(filtered(:)) <= 1, ...
                    'BLPF with order %d: Invalid output range', n);
            end
            fprintf('PASS\n');

            passedTests = passedTests + 1;
            fprintf('  [RESULT] All LPF tests passed for %s!\n', imgName);

        catch err
            fprintf('  [FAIL] %s\n', err.message);
        end

        fprintf('\n');
    end

    fprintf('==============================================\n');
    fprintf('  Low-Pass Filter Tests Summary\n');
    fprintf('==============================================\n');
    fprintf('  Passed: %d/%d\n', passedTests, totalTests);
    fprintf('==============================================\n');
end

function out = normalizeForDisplay(img)
    % Normalisasi min-max untuk visualisasi
    % Tidak mengubah hasil test, hanya untuk tampilan
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