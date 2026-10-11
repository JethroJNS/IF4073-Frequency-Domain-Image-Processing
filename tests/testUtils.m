% Test script for Utility Functions
function testUtils()
    fprintf('==============================================\n');
    fprintf('  Testing Frequency Domain Utilities\n');
    fprintf('==============================================\n\n');

    testDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(testDir);
    addpath(genpath(fullfile(repoRoot, 'src')));

    passedTests = 0;
    totalTests = 0;

    % 1. Test createFrequencyCoordinates - dimensi genap dan ganjil
    totalTests = totalTests + 1;
    fprintf('Test 1: createFrequencyCoordinates dimensi dasar... ');
    try
        testDims = [4, 4; 5, 5; 4, 7; 6, 3; 512, 512; 513, 513];
        for k = 1:size(testDims, 1)
            r = testDims(k, 1);
            c = testDims(k, 2);
            [U, V, D] = createFrequencyCoordinates(r, c);

            assert(isequal(size(U), [r, c]), 'Ukuran U salah');
            assert(isequal(size(V), [r, c]), 'Ukuran V salah');
            assert(isequal(size(D), [r, c]), 'Ukuran D salah');

            % Verifikasi DC berada tepat di tengah
            r0 = floor(r / 2) + 1;
            c0 = floor(c / 2) + 1;
            assert(U(r0, c0) == 0, 'U pada titik DC harus 0');
            assert(V(r0, c0) == 0, 'V pada titik DC harus 0');
            assert(D(r0, c0) == 0, 'D pada titik DC harus 0');

            % Verifikasi D non-negatif dan identik dengan hypot(U, V)
            assert(all(D(:) >= 0), 'D tidak boleh negatif');
            assert(max(abs(D(:) - hypot(U(:), V(:)))) < 1e-12, 'D harus bernilai hypot(U, V)');

            % Verifikasi kesesuaian dengan createFrequencyGrid eksisting
            D_legacy = createFrequencyGrid(r, c);
            assert(isequal(D, D_legacy), 'D harus identik dengan output createFrequencyGrid');
        end
        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 2. Test createFrequencyCoordinates - validasi input
    totalTests = totalTests + 1;
    fprintf('Test 2: createFrequencyCoordinates validasi input... ');
    try
        invalidInputs = {0, 5; -3, 4; 4.5, 4; [4, 4], 4; '4', 4};
        for k = 1:size(invalidInputs, 1)
            r = invalidInputs{k, 1};
            c = invalidInputs{k, 2};
            threw = false;
            try
                createFrequencyCoordinates(r, c);
            catch
                threw = true;
            end
            assert(threw, sprintf('Harus melempar error untuk input [%s, %s]', num2str(r), num2str(c)));
        end
        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 3. Test computeMagnitudeFromSpectrum - kebenaran komputasi
    totalTests = totalTests + 1;
    fprintf('Test 3: computeMagnitudeFromSpectrum kebenaran komputasi... ');
    try
        F_real = [3, -4; 0, 12];
        M_real = computeMagnitudeFromSpectrum(F_real);
        assert(isequal(size(M_real), size(F_real)), 'Ukuran output harus sama dengan input');
        assert(isequal(M_real, abs(F_real)), 'M harus bernilai abs(F)');

        F_complex = [3 + 4j, -5j; 1 - 1j, -8];
        M_complex = computeMagnitudeFromSpectrum(F_complex);
        assert(isequal(size(M_complex), size(F_complex)), 'Ukuran output harus sama dengan input');
        assert(max(abs(M_complex(:) - abs(F_complex(:)))) < 1e-12, 'M harus bernilai abs(F) untuk bilangan kompleks');

        % Verifikasi tidak ada log transformasi atau normalisasi otomatis
        assert(M_complex(1, 1) == 5, 'abs(3+4j) harus bernilai tepat 5');
        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    % 4. Test computeMagnitudeFromSpectrum - validasi input
    totalTests = totalTests + 1;
    fprintf('Test 4: computeMagnitudeFromSpectrum validasi input... ');
    try
        % 3D array harus ditolak
        threw3D = false;
        try
            computeMagnitudeFromSpectrum(zeros(4, 4, 3));
        catch
            threw3D = true;
        end
        assert(threw3D, 'Input 3D harus ditolak');

        % Input kosong harus ditolak
        threwEmpty = false;
        try
            computeMagnitudeFromSpectrum([]);
        catch
            threwEmpty = true;
        end
        assert(threwEmpty, 'Input kosong harus ditolak');

        % Input non-finite harus ditolak
        threwNonFinite = false;
        try
            computeMagnitudeFromSpectrum([1, NaN; 2, 3]);
        catch
            threwNonFinite = true;
        end
        assert(threwNonFinite, 'Input dengan NaN/Inf harus ditolak');

        passedTests = passedTests + 1;
        fprintf('PASS\n');
    catch err
        fprintf('FAIL (%s)\n', err.message);
    end

    fprintf('\n==============================================\n');
    fprintf('  Utility Tests Summary\n');
    fprintf('==============================================\n');
    fprintf('  Passed: %d/%d\n', passedTests, totalTests);
    fprintf('==============================================\n');
end
