% Test script for Motion Blur Restoration (Inverse Filter & Wiener Filter)
function testMotionBlurRestoration()
    fprintf('==============================================\n');
    fprintf('  Testing Motion Blur Restoration Filters\n');
    fprintf('==============================================\n\n');

    testDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testDir);
    addpath(genpath(fullfile(repoRoot, 'src')));

    passedTests = 0;
    skippedTests = 0;
    totalTests = 0;

    % 1. Test MotionBlurModel - degradasi dan nilai DC
    totalTests = totalTests + 1;
    fprintf('Test 1: MotionBlurModel nilai DC & dimensi... ');
    try
        testSizes = [32, 32; 33, 33; 30, 45];
        for s = 1:size(testSizes, 1)
            r = testSizes(s, 1);
            c = testSizes(s, 2);
            r0 = floor(r / 2) + 1;
            c0 = floor(c / 2) + 1;

            H = MotionBlurModel.create(r, c, 19, 20);
            assert(isequal(size(H), [r, c]), 'Ukuran H tidak sesuai');
            assert(~any(isnan(H(:))), 'H mengandung NaN');
            assert(~any(isinf(H(:))), 'H mengandung Inf');
            assert(abs(H(r0, c0) - 1.0) < 1e-10, 'DC harus bernilai 1.0');

            psf = MotionBlurModel.createSpatialPSF(r, c, 19, 20);
            assert(isequal(size(psf), [r, c]), 'Ukuran PSF tidak sesuai');
            assert(abs(sum(psf(:)) - 1.0) < 1e-6, 'Total energi PSF harus 1.0');
        end
        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 2. Test InverseFilter - mask numerik & stabilisasi
    totalTests = totalTests + 1;
    fprintf('Test 2: InverseFilter stabilitas numerik & threshold... ');
    try
        r = 64; c = 64;
        H = MotionBlurModel.create(r, c, 15, 0);
        M_inv = InverseFilter.createFilterMask(H, 20, 0.05);

        assert(isequal(size(M_inv), [r, c]), 'Ukuran M_inv tidak sesuai');
        assert(~any(isnan(M_inv(:))), 'M_inv tidak boleh mengandung NaN');
        assert(~any(isinf(M_inv(:))), 'M_inv tidak boleh mengandung Inf');

        % Frekuensi dengan |H| < threshold harus dinolkan
        magH = abs(H);
        assert(all(M_inv(magH < 0.05) == 0), 'Frekuensi di bawah threshold harus 0');

        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 3. Test WienerFilter - mask numerik & batas K
    totalTests = totalTests + 1;
    fprintf('Test 3: WienerFilter stabilitas numerik & parameter K... ');
    try
        r = 64; c = 64;
        H = MotionBlurModel.create(r, c, 15, 30);
        W = WienerFilter.createFilterMask(H, 0.01);

        assert(isequal(size(W), [r, c]), 'Ukuran W tidak sesuai');
        assert(~any(isnan(W(:))), 'W tidak boleh mengandung NaN');
        assert(~any(isinf(W(:))), 'W tidak boleh mengandung Inf');

        % Ketika K=0 dan H=0 harus bernilai 0 tanpa error
        W_zero = WienerFilter.createFilterMask(H, 0);
        assert(~any(isnan(W_zero(:))), 'W(K=0) tidak boleh mengandung NaN');

        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 4. Test apply, applyRaw, dan applyWithFilter pada Grayscale dan RGB
    totalTests = totalTests + 1;
    fprintf('Test 4: apply, applyRaw, dan applyWithFilter (Gray & RGB)... ');
    try
        grayImg = repmat(linspace(0, 1, 64), 64, 1);
        rgbImg = cat(3, grayImg, grayImg', flipud(grayImg));

        H = MotionBlurModel.create(64, 64, 11, 15);

        % Inverse Grayscale & RGB
        invGray = InverseFilter.apply(grayImg, H, 25, 0.02);
        invRGB = InverseFilter.apply(rgbImg, H, 25, 0.02);
        assert(min(invGray(:)) >= 0 && max(invGray(:)) <= 1, 'Inverse gray harus dalam [0, 1]');
        assert(isequal(size(invRGB), [64, 64, 3]), 'Inverse RGB harus 3 kanal');

        % Wiener Grayscale & RGB
        wnrGray = WienerFilter.apply(grayImg, H, 0.02);
        wnrRGB = WienerFilter.apply(rgbImg, H, 0.02);
        assert(min(wnrGray(:)) >= 0 && max(wnrGray(:)) <= 1, 'Wiener gray harus dalam [0, 1]');
        assert(isequal(size(wnrRGB), [64, 64, 3]), 'Wiener RGB harus 3 kanal');

        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 5. Test dataset resmi data/F_motion_blur_restoration
    totalTests = totalTests + 1;
    fprintf('Test 5: Uji dataset resmi data/F_motion_blur_restoration... ');
    try
        baseData = fullfile(repoRoot, 'data', 'F_motion_blur_restoration', 'input');
        datasetFiles = { ...
            'brick_gray_motion_L17_A0.png', 17, 0; ...
            'coins_gray_motion_L23_A35.png', 23, 35; ...
            'astronaut_color_motion_L19_A20.png', 19, 20; ...
            'astronaut_color_motion_L19_A20_gaussian_noise.png', 19, 20; ...
            'retina_color_motion_L15_A-25.png', 15, -25; ...
            'retina_color_motion_L15_A-25_gaussian_noise.png', 15, -25 ...
        };
        testedCount = 0;

        for i = 1:size(datasetFiles, 1)
            fname = datasetFiles{i, 1};
            L = datasetFiles{i, 2};
            theta = datasetFiles{i, 3};
            p = fullfile(baseData, fname);

            if exist(p, 'file')
                img = imread(p);
                [rows, cols, ~] = size(img);
                H = MotionBlurModel.create(rows, cols, L, theta);

                resInv = InverseFilter.apply(img, H, min(rows, cols)/3, 0.01);
                resWnr = WienerFilter.apply(img, H, 0.01);

                assert(min(resInv(:)) >= 0 && max(resInv(:)) <= 1, 'Inverse out of range');
                assert(min(resWnr(:)) >= 0 && max(resWnr(:)) <= 1, 'Wiener out of range');
                testedCount = testedCount + 1;
            end
        end

        if testedCount == 0
            skippedTests = skippedTests + 1;
            fprintf('SKIP (tidak ada citra dataset resmi ditemukan)\n');
        else
            passedTests = passedTests + 1;
            fprintf('PASS (%d citra resmi teruji)\n', testedCount);
        end
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    fprintf('\n==============================================\n');
    fprintf('  Motion Blur Restoration Tests Summary\n');
    fprintf('==============================================\n');
    fprintf('  Passed : %d/%d\n', passedTests, totalTests);
    fprintf('  Skipped: %d/%d\n', skippedTests, totalTests);
    fprintf('==============================================\n');
end
