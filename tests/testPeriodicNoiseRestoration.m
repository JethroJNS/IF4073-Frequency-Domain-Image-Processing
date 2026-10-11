% Test script for Periodic Noise Restoration (Bandreject & Notch Reject)
function testPeriodicNoiseRestoration()
    fprintf('==============================================\n');
    fprintf('  Testing Periodic Noise Restoration Filters\n');
    fprintf('==============================================\n\n');

    testDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testDir);
    addpath(genpath(fullfile(repoRoot, 'src')));

    passedTests = 0;
    skippedTests = 0;
    totalTests = 0;

    % 1. Test BandrejectFilter mask numerik & nilai DC
    totalTests = totalTests + 1;
    fprintf('Test 1: BandrejectFilter mask numerik & DC... ');
    try
        testSizes = [32, 32; 33, 33; 30, 45];
        filterTypes = {'ideal', 'butterworth', 'gaussian'};
        cutoff = 10;
        bw = 4;
        order = 2;

        for s = 1:size(testSizes, 1)
            r = testSizes(s, 1);
            c = testSizes(s, 2);
            r0 = floor(r / 2) + 1;
            c0 = floor(c / 2) + 1;

            for t = 1:length(filterTypes)
                ft = filterTypes{t};
                filt = BandrejectFilter.create(r, c, ft, cutoff, bw, order);
                H = filt.mask;

                assert(isequal(size(H), [r, c]), 'Ukuran mask Bandreject tidak sesuai');
                assert(~any(isnan(H(:))), 'Mask Bandreject mengandung NaN');
                assert(~any(isinf(H(:))), 'Mask Bandreject mengandung Inf');
                assert(min(H(:)) >= 0 && max(H(:)) <= 1, 'Nilai mask di luar rentang [0, 1]');

                % Verifikasi DC selalu bernilai 1.0
                assert(abs(H(r0, c0) - 1.0) < 1e-10, sprintf('DC pada %s harus bernilai 1.0', ft));
            end
        end
        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 2. Test simetri konjugat spektrum frekuensi (odd, even, even-by-odd, odd-by-even, Nyquist)
    totalTests = totalTests + 1;
    fprintf('Test 2: Simetri frekuensi konjugat (odd, even, non-square, Nyquist)... ');
    try
        testSizes = [33, 33; 32, 32; 32, 33; 33, 32];
        filterTypes = {'ideal', 'butterworth', 'gaussian'};

        for s = 1:size(testSizes, 1)
            r = testSizes(s, 1);
            c = testSizes(s, 2);

            % Uji simetri Bandreject
            for t = 1:length(filterTypes)
                filtBR = BandrejectFilter.create(r, c, filterTypes{t}, 8, 4, 2);
                assertConjugateSymmetry(filtBR.mask);
            end

            % Uji simetri Notch Reject titik umum
            for t = 1:length(filterTypes)
                filtNotch = NotchRejectFilter.create(r, c, filterTypes{t}, [5, 7], 3, 2);
                assertConjugateSymmetry(filtNotch.mask);
            end

            % Uji simetri Notch Reject di dekat frekuensi Nyquist
            u_nyq = -floor(c / 2);
            v_nyq = -floor(r / 2);
            for t = 1:length(filterTypes)
                filtNyq = NotchRejectFilter.create(r, c, filterTypes{t}, [u_nyq, v_nyq], 3, 2);
                assertConjugateSymmetry(filtNyq.mask);
            end
        end

        % Verifikasi helper mendeteksi mask asimetris
        filtSample = BandrejectFilter.create(32, 32, 'ideal', 8, 4);
        H_asym = filtSample.mask;
        H_asym(1, 2) = H_asym(1, 2) + 0.5;
        threwAsym = false;
        try
            assertConjugateSymmetry(H_asym);
        catch
            threwAsym = true;
        end
        assert(threwAsym, 'assertConjugateSymmetry harus mendeteksi mask asimetris');

        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 3. Test BandrejectFilter validasi input
    totalTests = totalTests + 1;
    fprintf('Test 3: BandrejectFilter validasi input... ');
    try
        threw = false;
        try
            BandrejectFilter.create(32, 32, 'ideal', 5, 12, 2);
        catch
            threw = true;
        end
        assert(threw, 'Harus error jika cutoff <= bw/2');

        threw = false;
        try
            BandrejectFilter.create(32, 32, 'invalid_filter', 10, 4, 2);
        catch
            threw = true;
        end
        assert(threw, 'Harus error jika filterType invalid');

        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 4. Test NotchRejectFilter mask & pasangan simetris
    totalTests = totalTests + 1;
    fprintf('Test 4: NotchRejectFilter mask & pasangan simetris... ');
    try
        r = 64; c = 64;
        r0 = floor(r / 2) + 1;
        c0 = floor(c / 2) + 1;
        u_k = 15; v_k = 10;
        D0 = 5;
        order = 2;

        filterTypes = {'ideal', 'butterworth', 'gaussian'};
        for t = 1:length(filterTypes)
            ft = filterTypes{t};
            filt = NotchRejectFilter.create(r, c, ft, [u_k, v_k], D0, order);
            H = filt.mask;

            assert(isequal(size(H), [r, c]), 'Ukuran mask Notch tidak sesuai');
            assert(~any(isnan(H(:))), 'Mask Notch mengandung NaN');
            assert(~any(isinf(H(:))), 'Mask Notch mengandung Inf');
            assert(min(H(:)) >= 0 && max(H(:)) <= 1, 'Nilai mask di luar [0, 1]');

            colPos = c0 + u_k; rowPos = r0 + v_k;
            colNeg = c0 - u_k; rowNeg = r0 - v_k;

            assert(H(rowPos, colPos) == 0, sprintf('Pusat notch positif %s harus 0', ft));
            assert(H(rowNeg, colNeg) == 0, sprintf('Pusat notch negatif %s harus 0', ft));
            assert(H(r0, c0) > 0.9, 'DC tidak boleh teredam signifikan oleh notch jauh');
        end
        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 5. Test NotchRejectFilter konversi koordinat & validasi batas
    totalTests = totalTests + 1;
    fprintf('Test 5: NotchRejectFilter konversi koordinat & validasi... ');
    try
        r = 100; c = 80;
        r0 = floor(r / 2) + 1;
        c0 = floor(c / 2) + 1;

        % Valid DC mapping
        [rowDC, colDC] = NotchRejectFilter.frequencyCoordToMatrixIndex(r, c, 0, 0);
        assert(rowDC == r0 && colDC == c0, 'DC harus memetakan ke pusat matriks');

        % Valid round-trip
        testU = [-35, 0, 20];
        testV = [-40, 0, 25];
        [rowIdx, colIdx] = NotchRejectFilter.frequencyCoordToMatrixIndex(r, c, testU, testV);
        coords = NotchRejectFilter.matrixIndexToFrequencyCoord(r, c, rowIdx, colIdx);
        assert(isequal(coords, [testU(:), testV(:)]), 'Konversi koordinat harus bijektif');

        % Validasi matrixIndexToFrequencyCoord: index di luar batas
        invalidIndices = {[0, 10], [r + 1, 10], [10, 0], [10, c + 1], [10.5, 10], [10, 10.5]};
        for k = 1:length(invalidIndices)
            pair = invalidIndices{k};
            threw = false;
            try
                NotchRejectFilter.matrixIndexToFrequencyCoord(r, c, pair(1), pair(2));
            catch
                threw = true;
            end
            assert(threw, sprintf('Harus melempar error untuk indeks matriks [%f, %f]', pair(1), pair(2)));
        end

        % Validasi frequencyCoordToMatrixIndex: koordinat fraksional dan di luar batas
        u_min = 1 - c0; u_max = c - c0;
        v_min = 1 - r0; v_max = r - r0;
        invalidCoords = { ...
            [u_min - 1, 0], [u_max + 1, 0], ...
            [0, v_min - 1], [0, v_max + 1], ...
            [1.5, 0], [0, -2.3] ...
        };
        for k = 1:length(invalidCoords)
            pair = invalidCoords{k};
            threw = false;
            try
                NotchRejectFilter.frequencyCoordToMatrixIndex(r, c, pair(1), pair(2));
            catch
                threw = true;
            end
            assert(threw, sprintf('Harus melempar error untuk koordinat frekuensi [%f, %f]', pair(1), pair(2)));
        end

        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 6. Test apply, applyRaw, dan applyWithFilter pada Grayscale dan RGB
    totalTests = totalTests + 1;
    fprintf('Test 6: apply, applyRaw, dan applyWithFilter (Gray & RGB)... ');
    try
        grayImg = repmat(linspace(0, 1, 64), 64, 1);
        rgbImg = cat(3, grayImg, grayImg', flipud(grayImg));

        filt = BandrejectFilter.create(64, 64, 'butterworth', 15, 6, 2);

        resClipped = filt.apply(grayImg);
        resRaw = filt.applyRaw(grayImg);
        [resWithFilt, maskRet] = filt.applyWithFilter(grayImg);

        assert(min(resClipped(:)) >= 0 && max(resClipped(:)) <= 1, 'apply harus ter-clip [0, 1]');
        assert(isequal(resRaw, resWithFilt), 'applyRaw harus sama dengan output pertama applyWithFilter');
        assert(isequal(maskRet, filt.mask), 'mask yang dikembalikan harus sesuai');

        resRGB = filt.apply(rgbImg);
        assert(isequal(size(resRGB), [64, 64, 3]), 'Output RGB harus 3 kanal');
        assert(min(resRGB(:)) >= 0 && max(resRGB(:)) <= 1, 'Output RGB apply harus ter-clip [0, 1]');

        notchFilt = NotchRejectFilter.create(64, 64, 'gaussian', [10, 12], 4);
        resNotchRGB = notchFilt.apply(rgbImg);
        assert(isequal(size(resNotchRGB), [64, 64, 3]), 'Notch RGB harus 3 kanal');

        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 7. Test dataset resmi data/E_periodic_noise_restoration
    totalTests = totalTests + 1;
    fprintf('Test 7: Uji dataset resmi data/E_periodic_noise_restoration... ');
    try
        baseData = fullfile(repoRoot, 'data', 'E_periodic_noise_restoration', 'input');
        testImgs = { ...
            'brick_gray_periodic_noise.png', ...
            'grass_gray_periodic_noise.png', ...
            'hubble_color_periodic_noise.png', ...
            'rocket_color_periodic_noise.png' ...
        };
        testedCount = 0;

        for i = 1:length(testImgs)
            p = fullfile(baseData, testImgs{i});
            if exist(p, 'file')
                img = imread(p);
                [rows, cols, ~] = size(img);
                filt = BandrejectFilter.create(rows, cols, 'butterworth', 30, 10, 2);
                out = filt.apply(img);
                assert(min(out(:)) >= 0 && max(out(:)) <= 1, 'Hasil restorasi harus dalam [0, 1]');
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
    fprintf('  Periodic Noise Filter Tests Summary\n');
    fprintf('==============================================\n');
    fprintf('  Passed : %d/%d\n', passedTests, totalTests);
    fprintf('  Skipped: %d/%d\n', skippedTests, totalTests);
    fprintf('==============================================\n');
end

% Verifikasi simetri konjugat terhadap DC dengan wrap-around periodik DFT
function assertConjugateSymmetry(H)
    [rows, cols] = size(H);
    r0 = floor(rows / 2) + 1;
    c0 = floor(cols / 2) + 1;

    r_sym = 2 * r0 - (1:rows);
    if mod(rows, 2) == 0
        r_sym(1) = 1;
    end

    c_sym = 2 * c0 - (1:cols);
    if mod(cols, 2) == 0
        c_sym(1) = 1;
    end

    H_sym = H(r_sym, c_sym);
    diffVal = max(abs(H(:) - H_sym(:)));
    assert(diffVal < 1e-10, sprintf('Mask tidak simetris konjugat terhadap DC: max diff = %e', diffVal));
end
