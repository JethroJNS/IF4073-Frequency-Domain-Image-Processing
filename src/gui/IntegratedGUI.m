% Integrated GUI for IF4073 Frequency Domain Image Processing
classdef IntegratedGUI < handle
    properties (Access = private)
        fig
        layoutGrid
        controlLayout
        paramGrid

        % Data citra
        imgOriginal
        imgProcessed
        maskCurrent
        spectrumIn

        % Handle Axes
        axInput
        axOutput
        axSpectrum
        axMask

        % Handle Komponen UI Umum
        lblInfo
        btnLoad
        btnSave
        btnProcess
        dropCategory
        dropSubMethod
        chkAutoProcess
        pnlDynamicParams

        % Parameter Controls
        lblParam1; sldParam1; edtParam1
        lblParam2; sldParam2; edtParam2
        lblParam3; sldParam3; edtParam3
        lblParam4; sldParam4; edtParam4
        paramIsInteger = [false, false, false, false]

        % Komponen Notch Khusus
        pnlNotchControls
        edtNotchU; edtNotchV; btnAddNotch; btnClearNotch
        lblNotchList
        notchList = [] % Matriks K x 2 [u, v]

        % State Lock untuk Menghindari Pemrosesan Ganda
        isProcessing = false
    end

    methods
        function obj = IntegratedGUI()
            obj.createUI();
            obj.updateCategoryControls();
        end
    end

    methods (Access = private)
        function createUI(obj)
            obj.fig = uifigure('Name', 'IF4073 - Pemrosesan Citra Ranah Frekuensi', ...
                'Position', [50, 50, 1280, 800], ...
                'Color', [0.95, 0.95, 0.96]);

            obj.layoutGrid = uigridlayout(obj.fig, [1, 2]);
            obj.layoutGrid.ColumnWidth = {360, '1x'};
            obj.layoutGrid.Padding = [10, 10, 10, 10];
            obj.layoutGrid.ColumnSpacing = 10;

            % --- PANEL KIRI: KONTROL ---
            pnlControl = uipanel(obj.layoutGrid, 'Title', 'Panel Kontrol', ...
                'FontWeight', 'bold', 'FontSize', 12, 'Scrollable', 'on');

            % Tepat 9 baris untuk 9 komponen utama di panel kontrol
            obj.controlLayout = uigridlayout(pnlControl, [9, 1]);
            obj.controlLayout.RowHeight = {35, 18, 30, 30, 185, 130, 36, 24, 34};
            obj.controlLayout.Padding = [8, 8, 8, 8];
            obj.controlLayout.RowSpacing = 8;

            % Row 1: Tombol Muat & Simpan
            gridFile = uigridlayout(obj.controlLayout, [1, 2]);
            gridFile.ColumnWidth = {'1x', '1x'};
            gridFile.RowHeight = {'1x'};
            gridFile.Padding = [0, 0, 0, 0];
            gridFile.ColumnSpacing = 8;
            
            obj.btnLoad = uibutton(gridFile, 'Text', 'Muat Citra...', ...
                'Tooltip', 'Pilih berkas citra dari penyimpanan lokal', ...
                'ButtonPushedFcn', @(~, ~) obj.onLoadImage());
            obj.btnSave = uibutton(gridFile, 'Text', 'Simpan Hasil...', ...
                'Tooltip', 'Simpan citra hasil pemrosesan ke berkas lokal', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~, ~) obj.onSaveImage());

            % Row 2: Label Kategori
            uilabel(obj.controlLayout, 'Text', 'Kategori Pemrosesan:', ...
                'FontWeight', 'bold');

            % Row 3: Dropdown Kategori
            obj.dropCategory = uidropdown(obj.controlLayout, ...
                'Items', {'Low-Pass Filter (LPF)', ...
                          'High-Pass Filter (HPF)', ...
                          'Brightness Enhancement', ...
                          'Periodic Noise Restoration', ...
                          'Motion Blur Restoration'}, ...
                'ValueChangedFcn', @(~, ~) obj.onCategoryChanged());

            % Row 4: Dropdown Sub-metode
            obj.dropSubMethod = uidropdown(obj.controlLayout, ...
                'Items', {'Ideal', 'Butterworth', 'Gaussian'}, ...
                'ValueChangedFcn', @(~, ~) obj.onSubMethodChanged());

            % Row 5: Panel Parameter Dinamis (Tepat 4 baris kontrol)
            obj.pnlDynamicParams = uipanel(obj.controlLayout, 'Title', 'Parameter Filter');
            obj.paramGrid = uigridlayout(obj.pnlDynamicParams, [4, 3]);
            obj.paramGrid.ColumnWidth = {95, '1x', 52};
            obj.paramGrid.RowHeight = {32, 32, 32, 32};
            obj.paramGrid.Padding = [6, 6, 6, 6];
            obj.paramGrid.RowSpacing = 6;

            % Param 1
            obj.lblParam1 = uilabel(obj.paramGrid, 'Text', 'Cutoff (D0):');
            obj.sldParam1 = uislider(obj.paramGrid, 'Limits', [1, 200], 'Value', 30, ...
                'ValueChangedFcn', @(~, ~) obj.onSliderParam(1));
            obj.edtParam1 = uieditfield(obj.paramGrid, 'numeric', 'Value', 30, ...
                'ValueChangedFcn', @(~, ~) obj.onEditParam(1));

            % Param 2
            obj.lblParam2 = uilabel(obj.paramGrid, 'Text', 'Order (n):');
            obj.sldParam2 = uislider(obj.paramGrid, 'Limits', [1, 10], 'Value', 2, ...
                'ValueChangedFcn', @(~, ~) obj.onSliderParam(2));
            obj.edtParam2 = uieditfield(obj.paramGrid, 'numeric', 'Value', 2, ...
                'ValueChangedFcn', @(~, ~) obj.onEditParam(2));

            % Param 3
            obj.lblParam3 = uilabel(obj.paramGrid, 'Text', 'Bandwidth:');
            obj.sldParam3 = uislider(obj.paramGrid, 'Limits', [1, 100], 'Value', 10, ...
                'ValueChangedFcn', @(~, ~) obj.onSliderParam(3));
            obj.edtParam3 = uieditfield(obj.paramGrid, 'numeric', 'Value', 10, ...
                'ValueChangedFcn', @(~, ~) obj.onEditParam(3));

            % Param 4
            obj.lblParam4 = uilabel(obj.paramGrid, 'Text', 'Param 4:');
            obj.sldParam4 = uislider(obj.paramGrid, 'Limits', [0.001, 1], 'Value', 0.01, ...
                'ValueChangedFcn', @(~, ~) obj.onSliderParam(4));
            obj.edtParam4 = uieditfield(obj.paramGrid, 'numeric', 'Value', 0.01, ...
                'ValueChangedFcn', @(~, ~) obj.onEditParam(4));

            % Row 6: Panel Khusus Notch (Tepat 3 baris)
            obj.pnlNotchControls = uipanel(obj.controlLayout, 'Title', 'Daftar Notch [u, v]');
            notchGrid = uigridlayout(obj.pnlNotchControls, [3, 1]);
            notchGrid.RowHeight = {28, 28, '1x'};
            notchGrid.Padding = [6, 6, 6, 6];
            notchGrid.RowSpacing = 4;

            manualGrid = uigridlayout(notchGrid, [1, 5]);
            manualGrid.ColumnWidth = {18, 55, 18, 55, '1x'};
            manualGrid.RowHeight = {'1x'};
            manualGrid.Padding = [0, 0, 0, 0];
            uilabel(manualGrid, 'Text', 'u:');
            obj.edtNotchU = uieditfield(manualGrid, 'numeric', 'Value', 15);
            uilabel(manualGrid, 'Text', 'v:');
            obj.edtNotchV = uieditfield(manualGrid, 'numeric', 'Value', 10);
            obj.btnAddNotch = uibutton(manualGrid, 'Text', 'Tambah', ...
                'Tooltip', 'Tambahkan pasangan koordinat frekuensi [u, v] dan [-u, -v]', ...
                'ButtonPushedFcn', @(~, ~) obj.onAddManualNotch());

            notchBtnGrid = uigridlayout(notchGrid, [1, 2]);
            notchBtnGrid.ColumnWidth = {'1x', '1x'};
            notchBtnGrid.RowHeight = {'1x'};
            notchBtnGrid.Padding = [0, 0, 0, 0];
            obj.btnClearNotch = uibutton(notchBtnGrid, 'Text', 'Kosongkan', ...
                'Tooltip', 'Hapus seluruh titik notch yang telah dipilih', ...
                'ButtonPushedFcn', @(~, ~) obj.onClearNotches());
            uibutton(notchBtnGrid, 'Text', 'Info Klik', ...
                'Tooltip', 'Lihat petunjuk pemilihan titik notch langsung dari spektrum', ...
                'ButtonPushedFcn', @(~, ~) obj.onPromptSpectrumClick());

            obj.lblNotchList = uilabel(notchGrid, 'Text', 'Notch aktif: (belum ada - klik spektrum)', ...
                'FontSize', 10);

            % Row 7: Tombol Eksekusi Pemrosesan
            obj.btnProcess = uibutton(obj.controlLayout, 'Text', 'Jalankan Pemrosesan', ...
                'BackgroundColor', [0.12, 0.45, 0.85], ...
                'FontColor', [1, 1, 1], ...
                'FontWeight', 'bold', ...
                'FontSize', 12, ...
                'Tooltip', 'Jalankan filter dengan konfigurasi parameter saat ini', ...
                'ButtonPushedFcn', @(~, ~) obj.onProcessImage());

            % Row 8: Checkbox Auto-Process
            obj.chkAutoProcess = uicheckbox(obj.controlLayout, ...
                'Text', 'Proses Otomatis saat Parameter Berubah', ...
                'Value', false, ...
                'Tooltip', 'Jika aktif, hasil langsung diperbarui saat slider atau dropdown berubah', ...
                'ValueChangedFcn', @(~, ~) obj.onAutoProcessToggled());

            % Row 9: Label Status
            obj.lblInfo = uilabel(obj.controlLayout, ...
                'Text', 'Status: Siap. Muat citra untuk memulai.', ...
                'FontSize', 10, 'FontColor', [0.3, 0.3, 0.3]);

            % --- PANEL KANAN: DISPLAY 4 AXES ---
            pnlDisplay = uipanel(obj.layoutGrid, 'Title', 'Visualisasi Domain Spasial & Frekuensi', ...
                'FontWeight', 'bold', 'FontSize', 12);
            dispGrid = uigridlayout(pnlDisplay, [2, 2]);
            dispGrid.RowHeight = {'1x', '1x'};
            dispGrid.ColumnWidth = {'1x', '1x'};
            dispGrid.Padding = [8, 8, 8, 8];
            dispGrid.RowSpacing = 8;
            dispGrid.ColumnSpacing = 8;

            obj.axInput = uiaxes(dispGrid);
            obj.axInput.Layout.Row = 1; obj.axInput.Layout.Column = 1;
            title(obj.axInput, 'Citra Masukan');
            obj.axInput.XTick = []; obj.axInput.YTick = [];

            obj.axOutput = uiaxes(dispGrid);
            obj.axOutput.Layout.Row = 1; obj.axOutput.Layout.Column = 2;
            title(obj.axOutput, 'Citra Hasil (Belum Diproses)');
            obj.axOutput.XTick = []; obj.axOutput.YTick = [];

            obj.axSpectrum = uiaxes(dispGrid);
            obj.axSpectrum.Layout.Row = 2; obj.axSpectrum.Layout.Column = 1;
            title(obj.axSpectrum, 'Spektrum Magnitudo Masukan log(1+|F|)');
            obj.axSpectrum.XTick = []; obj.axSpectrum.YTick = [];

            obj.axMask = uiaxes(dispGrid);
            obj.axMask.Layout.Row = 2; obj.axMask.Layout.Column = 2;
            title(obj.axMask, 'Mask Fungsi Transfer Penapis H(u, v)');
            obj.axMask.XTick = []; obj.axMask.YTick = [];
        end

        function onLoadImage(obj)
            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Berkas Citra (*.png, *.jpg, *.bmp, *.tif)'}, ...
                'Pilih Citra Masukan');
            if isequal(file, 0)
                return;
            end
            try
                raw = imread(fullfile(path, file));
                obj.imgOriginal = im2double(raw);
                if size(obj.imgOriginal, 3) == 4
                    obj.imgOriginal = obj.imgOriginal(:,:,1:3);
                end
                obj.imgProcessed = [];
                obj.maskCurrent = [];
                obj.btnSave.Enable = 'off';

                % Tampilkan citra input proporsional tanpa distorsi
                cla(obj.axInput);
                imshow(obj.imgOriginal, 'Parent', obj.axInput);
                axis(obj.axInput, 'image');
                [rows, cols, ch] = size(obj.imgOriginal);
                modeStr = 'Grayscale';
                if ch == 3; modeStr = 'RGB'; end
                title(obj.axInput, sprintf('Citra Masukan (%dx%d %s)', rows, cols, modeStr));

                % Hitung spektrum magnitudo menggunakan utility
                if ch == 3
                    grayForFFT = 0.2989 * obj.imgOriginal(:,:,1) + 0.5870 * obj.imgOriginal(:,:,2) + 0.1140 * obj.imgOriginal(:,:,3);
                else
                    grayForFFT = obj.imgOriginal;
                end
                obj.spectrumIn = computeMagnitudeSpectrum(grayForFFT);
                
                obj.updateSpectrumPlot();

                % Reset tampilan hasil lama agar tidak keliru dianggap hasil gambar baru
                cla(obj.axOutput); 
                title(obj.axOutput, 'Citra Hasil (Belum Diproses)');
                cla(obj.axMask); 
                title(obj.axMask, 'Mask Fungsi Transfer Penapis H(u, v)');

                obj.lblInfo.FontColor = [0.2, 0.2, 0.2];
                obj.lblInfo.Text = sprintf('Citra berhasil dimuat: %s (%dx%d %s)', file, rows, cols, modeStr);
                
                if obj.chkAutoProcess.Value
                    obj.onProcessImage();
                end
            catch err
                uialert(obj.fig, sprintf('Gagal memuat citra: %s', err.message), 'Error');
                obj.lblInfo.FontColor = [0.8, 0.1, 0.1];
                obj.lblInfo.Text = 'Status: Gagal memuat citra.';
            end
        end

        function onSaveImage(obj)
            if isempty(obj.imgProcessed)
                uialert(obj.fig, 'Belum ada citra hasil yang diproses. Jalankan pemrosesan terlebih dahulu.', 'Peringatan');
                return;
            end
            [file, path] = uiputfile({'*.png', 'PNG Image (*.png)'; '*.jpg', 'JPEG Image (*.jpg)'}, ...
                'Simpan Hasil Pemrosesan');
            if isequal(file, 0)
                return;
            end
            try
                imwrite(obj.imgProcessed, fullfile(path, file));
                obj.lblInfo.FontColor = [0.1, 0.5, 0.1];
                obj.lblInfo.Text = sprintf('Hasil berhasil disimpan ke: %s', file);
            catch err
                uialert(obj.fig, sprintf('Gagal menyimpan citra: %s', err.message), 'Error');
                obj.lblInfo.FontColor = [0.8, 0.1, 0.1];
                obj.lblInfo.Text = 'Status: Gagal menyimpan citra.';
            end
        end

        function onCategoryChanged(obj)
            obj.updateCategoryControls();
            if obj.chkAutoProcess.Value && ~isempty(obj.imgOriginal)
                obj.onProcessImage();
            else
                if ~isempty(obj.imgOriginal)
                    obj.invalidateProcessedResult('Kategori pemrosesan berubah. Jalankan pemrosesan kembali.');
                end
            end
        end

        function onSubMethodChanged(obj)
            obj.updateSubMethodParams();
            obj.updateSpectrumPlot();
            if obj.chkAutoProcess.Value && ~isempty(obj.imgOriginal)
                obj.onProcessImage();
            else
                if ~isempty(obj.imgOriginal)
                    obj.invalidateProcessedResult('Metode penapis berubah. Jalankan pemrosesan kembali.');
                end
            end
        end

        function onAutoProcessToggled(obj)
            if obj.chkAutoProcess.Value && ~isempty(obj.imgOriginal)
                if isempty(obj.imgProcessed)
                    obj.onProcessImage();
                end
            end
        end

        function updateCategoryControls(obj)
            catVal = obj.dropCategory.Value;
            switch catVal
                case 'Low-Pass Filter (LPF)'
                    obj.dropSubMethod.Visible = 'on';
                    obj.dropSubMethod.Items = {'Ideal', 'Butterworth', 'Gaussian'};
                    obj.dropSubMethod.Value = 'Ideal';

                case 'High-Pass Filter (HPF)'
                    obj.dropSubMethod.Visible = 'on';
                    obj.dropSubMethod.Items = {'Ideal', 'Butterworth', 'Gaussian'};
                    obj.dropSubMethod.Value = 'Ideal';

                case 'Brightness Enhancement'
                    obj.dropSubMethod.Visible = 'on';
                    obj.dropSubMethod.Items = {'DC Boost', 'Low-Frequency Boost'};
                    obj.dropSubMethod.Value = 'DC Boost';

                case 'Periodic Noise Restoration'
                    obj.dropSubMethod.Visible = 'on';
                    obj.dropSubMethod.Items = {'Bandreject (Butterworth)', ...
                                               'Bandreject (Gaussian)', ...
                                               'Bandreject (Ideal)', ...
                                               'Notch Reject (Butterworth)', ...
                                               'Notch Reject (Gaussian)', ...
                                               'Notch Reject (Ideal)'};
                    obj.dropSubMethod.Value = 'Bandreject (Butterworth)';

                case 'Motion Blur Restoration'
                    obj.dropSubMethod.Visible = 'on';
                    obj.dropSubMethod.Items = {'Wiener Filter', 'Inverse Filter'};
                    obj.dropSubMethod.Value = 'Wiener Filter';
            end
            obj.updateSubMethodParams();
            obj.updateSpectrumPlot();
        end

        function updateSubMethodParams(obj)
            catVal = obj.dropCategory.Value;
            subVal = obj.dropSubMethod.Value;

            % Sembunyikan default seluruh parameter tanpa celah kosong
            obj.setParamVisible(1, false);
            obj.setParamVisible(2, false);
            obj.setParamVisible(3, false);
            obj.setParamVisible(4, false);

            % Atur panel notch
            if strcmp(catVal, 'Periodic Noise Restoration') && startsWith(subVal, 'Notch Reject')
                obj.pnlNotchControls.Visible = 'on';
                obj.controlLayout.RowHeight{6} = 130;
                if isempty(obj.notchList)
                    obj.lblInfo.FontColor = [0.2, 0.4, 0.8];
                    obj.lblInfo.Text = 'Petunjuk: Klik pada spektrum masukan (kiri bawah) untuk memilih titik notch.';
                end
            else
                obj.pnlNotchControls.Visible = 'off';
                obj.controlLayout.RowHeight{6} = 0;
            end

            switch catVal
                case {'Low-Pass Filter (LPF)', 'High-Pass Filter (HPF)'}
                    obj.setParamVisible(1, true, 'Cutoff (D0):', [1, 250], 30, false);
                    if strcmp(subVal, 'Butterworth')
                        obj.setParamVisible(2, true, 'Order (n):', [1, 10], 2, true);
                    end

                case 'Brightness Enhancement'
                    obj.setParamVisible(1, true, 'Gain:', [0.1, 5.0], 1.8, false);
                    if strcmp(subVal, 'Low-Frequency Boost')
                        obj.setParamVisible(2, true, 'Cutoff (D0):', [1, 100], 30, false);
                    end

                case 'Periodic Noise Restoration'
                    if startsWith(subVal, 'Bandreject')
                        obj.setParamVisible(1, true, 'Cutoff (D0):', [2, 200], 35, false);
                        obj.setParamVisible(2, true, 'Bandwidth (W):', [1, 50], 10, false);
                        if contains(subVal, 'Butterworth')
                            obj.setParamVisible(3, true, 'Order (n):', [1, 10], 2, true);
                        end
                    else
                        obj.setParamVisible(1, true, 'Radius (D0):', [1, 50], 5, false);
                        if contains(subVal, 'Butterworth')
                            obj.setParamVisible(2, true, 'Order (n):', [1, 10], 2, true);
                        end
                    end

                case 'Motion Blur Restoration'
                    obj.setParamVisible(1, true, 'Length (L):', [1, 50], 19, false);
                    obj.setParamVisible(2, true, 'Angle (\theta):', [-180, 180], 20, false);
                    if strcmp(subVal, 'Wiener Filter')
                        obj.setParamVisible(3, true, 'K (NSR):', [0.0001, 1.0], 0.01, false);
                    else
                        obj.setParamVisible(3, true, 'Cutoff (Rc):', [5, 200], 70, false);
                        obj.setParamVisible(4, true, 'Threshold (\epsilon):', [0.001, 0.2], 0.01, false);
                    end
            end
        end

        function setParamVisible(obj, idx, vis, labelText, lims, val, isInteger)
            if nargin < 7; isInteger = false; end
            obj.paramIsInteger(idx) = isInteger;

            if idx == 1
                lbl = obj.lblParam1; sld = obj.sldParam1; edt = obj.edtParam1;
            elseif idx == 2
                lbl = obj.lblParam2; sld = obj.sldParam2; edt = obj.edtParam2;
            elseif idx == 3
                lbl = obj.lblParam3; sld = obj.sldParam3; edt = obj.edtParam3;
            else
                lbl = obj.lblParam4; sld = obj.sldParam4; edt = obj.edtParam4;
            end

            if vis
                lbl.Visible = 'on'; sld.Visible = 'on'; edt.Visible = 'on';
                obj.paramGrid.RowHeight{idx} = 32;
                lbl.Text = labelText;
                sld.Limits = lims;
                if isInteger
                    val = round(val);
                end
                sld.Value = val;
                edt.Value = val;
            else
                lbl.Visible = 'off'; sld.Visible = 'off'; edt.Visible = 'off';
                obj.paramGrid.RowHeight{idx} = 0;
            end
        end

        function onSliderParam(obj, idx)
            if idx == 1
                sld = obj.sldParam1; edt = obj.edtParam1;
            elseif idx == 2
                sld = obj.sldParam2; edt = obj.edtParam2;
            elseif idx == 3
                sld = obj.sldParam3; edt = obj.edtParam3;
            else
                sld = obj.sldParam4; edt = obj.edtParam4;
            end

            val = sld.Value;
            if obj.paramIsInteger(idx)
                val = round(val);
                sld.Value = val;
            end
            edt.Value = val;

            % Interaktif penjagaan constraint Bandreject: W < 2*D0
            if startsWith(obj.dropSubMethod.Value, 'Bandreject')
                obj.enforceBandrejectConstraints();
            end

            if obj.chkAutoProcess.Value && ~isempty(obj.imgOriginal)
                obj.onProcessImage();
            else
                if ~isempty(obj.imgOriginal)
                    obj.invalidateProcessedResult('Parameter penapis berubah. Jalankan pemrosesan kembali.');
                end
            end
        end

        function onEditParam(obj, idx)
            if idx == 1
                sld = obj.sldParam1; edt = obj.edtParam1;
            elseif idx == 2
                sld = obj.sldParam2; edt = obj.edtParam2;
            elseif idx == 3
                sld = obj.sldParam3; edt = obj.edtParam3;
            else
                sld = obj.sldParam4; edt = obj.edtParam4;
            end

            val = edt.Value;
            val = max(sld.Limits(1), min(sld.Limits(2), val));
            if obj.paramIsInteger(idx)
                val = round(val);
            end
            edt.Value = val;
            sld.Value = val;

            % Interaktif penjagaan constraint Bandreject: W < 2*D0
            if startsWith(obj.dropSubMethod.Value, 'Bandreject')
                obj.enforceBandrejectConstraints();
            end

            if obj.chkAutoProcess.Value && ~isempty(obj.imgOriginal)
                obj.onProcessImage();
            else
                if ~isempty(obj.imgOriginal)
                    obj.invalidateProcessedResult('Parameter penapis berubah. Jalankan pemrosesan kembali.');
                end
            end
        end

        function enforceBandrejectConstraints(obj)
            d0 = obj.sldParam1.Value;
            maxBw = max(1, 2 * d0 - 2);
            if obj.sldParam2.Value > maxBw
                obj.sldParam2.Value = maxBw;
                obj.edtParam2.Value = maxBw;
            end
        end

        function invalidateProcessedResult(obj, reasonMsg)
            if nargin < 2 || isempty(reasonMsg)
                reasonMsg = 'Konfigurasi berubah. Jalankan pemrosesan kembali untuk melihat hasil.';
            end
            obj.imgProcessed = [];
            obj.maskCurrent = [];
            obj.btnSave.Enable = 'off';

            cla(obj.axOutput);
            title(obj.axOutput, 'Citra Hasil (Konfigurasi Berubah - Belum Diproses)');

            cla(obj.axMask);
            title(obj.axMask, 'Mask Fungsi Transfer Penapis H(u, v)');

            obj.lblInfo.FontColor = [0.85, 0.45, 0.0];
            obj.lblInfo.Text = sprintf('Status: %s', reasonMsg);
        end

        function resetProcessingFlag(obj)
            obj.isProcessing = false;
        end

        function onAddManualNotch(obj)
            uVal = round(obj.edtNotchU.Value);
            vVal = round(obj.edtNotchV.Value);
            obj.addNotchCoord(uVal, vVal);
        end

        function onClearNotches(obj)
            obj.notchList = [];
            obj.updateNotchDisplay();
            obj.updateSpectrumPlot();
            if ~isempty(obj.imgOriginal)
                obj.invalidateProcessedResult('Daftar notch dikosongkan. Tentukan notch baru.');
            else
                obj.lblInfo.FontColor = [0.2, 0.2, 0.2];
                obj.lblInfo.Text = 'Status: Daftar notch berhasil dikosongkan.';
            end
        end

        function onPromptSpectrumClick(obj)
            msg = sprintf(['Panduan Pemilihan Notch:\n\n', ...
                '1. Klik langsung pada spike frekuensi di tampilan Spektrum Magnitudo (kiri bawah).\n', ...
                '2. Atau ketik koordinat [u, v] pada kotak input lalu klik tombol "Tambah".\n', ...
                '3. Pasangan frekuensi simetris konjugat [-u, -v] akan otomatis disertakan oleh filter.\n', ...
                '4. Titik DC [0, 0] dilindungi agar intensitas rata-rata citra tidak terhapus.']);
            uialert(obj.fig, msg, 'Panduan Pemilihan Notch');
        end

        function onSpectrumClicked(obj, evt)
            if ~strcmp(obj.dropCategory.Value, 'Periodic Noise Restoration') || ...
               ~startsWith(obj.dropSubMethod.Value, 'Notch Reject') || isempty(obj.imgOriginal)
                return;
            end
            [rows, cols, ~] = size(obj.imgOriginal);

            % Dukung evt.IntersectionPoint maupun axSpectrum.CurrentPoint
            if isprop(evt, 'IntersectionPoint') && ~isempty(evt.IntersectionPoint)
                x = evt.IntersectionPoint(1);
                y = evt.IntersectionPoint(2);
            elseif isprop(obj.axSpectrum, 'CurrentPoint')
                cp = obj.axSpectrum.CurrentPoint;
                x = cp(1, 1);
                y = cp(1, 2);
            else
                return;
            end

            cClicked = round(x);
            rClicked = round(y);

            if cClicked >= 1 && cClicked <= cols && rClicked >= 1 && rClicked <= rows
                coords = NotchRejectFilter.matrixIndexToFrequencyCoord(rows, cols, rClicked, cClicked);
                obj.addNotchCoord(coords(1), coords(2));
            end
        end

        function addNotchCoord(obj, u, v)
            if u == 0 && v == 0
                uialert(obj.fig, 'Koordinat (0, 0) adalah komponen DC. Notch pada DC akan merusak intensitas rata-rata citra.', 'Peringatan');
                return;
            end
            % Cegah duplikasi
            if ~isempty(obj.notchList)
                existing = any(obj.notchList(:,1) == u & obj.notchList(:,2) == v);
                if existing
                    return;
                end
            end
            obj.notchList = [obj.notchList; u, v];
            obj.updateNotchDisplay();
            obj.updateSpectrumPlot();
            obj.lblInfo.FontColor = [0.1, 0.5, 0.1];
            obj.lblInfo.Text = sprintf('Notch ditambahkan: [%d, %d]. Total pasang notch: %d.', u, v, size(obj.notchList, 1));
            
            if obj.chkAutoProcess.Value && ~isempty(obj.imgOriginal)
                obj.onProcessImage();
            else
                if ~isempty(obj.imgOriginal)
                    obj.invalidateProcessedResult('Titik notch diperbarui. Jalankan pemrosesan kembali.');
                end
            end
        end

        function updateNotchDisplay(obj)
            if isempty(obj.notchList)
                obj.lblNotchList.Text = 'Notch aktif: (belum ada - klik spektrum)';
            else
                k = size(obj.notchList, 1);
                strList = '';
                for i = 1:min(k, 3)
                    strList = sprintf('%s [%d,%d]', strList, obj.notchList(i,1), obj.notchList(i,2));
                end
                if k > 3
                    strList = sprintf('%s ... (+%d)', strList, k - 3);
                end
                obj.lblNotchList.Text = sprintf('Notch aktif (%d):%s', k, strList);
            end
        end

        function updateSpectrumPlot(obj)
            if isempty(obj.spectrumIn)
                return;
            end
            cla(obj.axSpectrum);
            hSpec = imshow(obj.spectrumIn, [], 'Parent', obj.axSpectrum);
            axis(obj.axSpectrum, 'image');
            colormap(obj.axSpectrum, 'gray');
            hSpec.ButtonDownFcn = @(~, evt) obj.onSpectrumClicked(evt);

            % Tampilkan marker visual titik notch aktif pada spektrum
            if ~isempty(obj.notchList) && ~isempty(obj.imgOriginal)
                [rows, cols, ~] = size(obj.imgOriginal);
                r0 = floor(rows / 2) + 1;
                c0 = floor(cols / 2) + 1;
                hold(obj.axSpectrum, 'on');
                for i = 1:size(obj.notchList, 1)
                    u = obj.notchList(i, 1);
                    v = obj.notchList(i, 2);
                    c1 = u + c0;
                    r1 = v + r0;
                    if c1 >= 1 && c1 <= cols && r1 >= 1 && r1 <= rows
                        plot(obj.axSpectrum, c1, r1, 'ro', 'MarkerSize', 6, 'LineWidth', 1.5);
                    end
                    c2 = -u + c0;
                    r2 = -v + r0;
                    if c2 >= 1 && c2 <= cols && r2 >= 1 && r2 <= rows
                        plot(obj.axSpectrum, c2, r2, 'rx', 'MarkerSize', 6, 'LineWidth', 1.5);
                    end
                end
                hold(obj.axSpectrum, 'off');
            end

            % Judul spektrum informatif sesuai mode aktif
            if strcmp(obj.dropCategory.Value, 'Periodic Noise Restoration') && ...
               startsWith(obj.dropSubMethod.Value, 'Notch Reject')
                title(obj.axSpectrum, 'Spektrum Magnitudo (Klik untuk Tambah Notch)');
            else
                title(obj.axSpectrum, 'Spektrum Magnitudo Masukan log(1+|F|)');
            end
        end

        function onProcessImage(obj)
            if isempty(obj.imgOriginal)
                uialert(obj.fig, 'Silakan muat citra terlebih dahulu.', 'Peringatan');
                return;
            end

            % Cegah pemrosesan ganda / re-entrancy
            if obj.isProcessing
                return;
            end
            obj.isProcessing = true;
            cleanupObj = onCleanup(@() obj.resetProcessingFlag());

            catVal = obj.dropCategory.Value;
            subVal = obj.dropSubMethod.Value;
            img = obj.imgOriginal;
            [rows, cols, ~] = size(img);

            % Validasi awal sebelum eksekusi: periksa kesiapan notch
            if strcmp(catVal, 'Periodic Noise Restoration') && startsWith(subVal, 'Notch Reject')
                if isempty(obj.notchList)
                    obj.invalidateProcessedResult('Daftar notch masih kosong. Tentukan titik notch terlebih dahulu.');
                    if ~obj.chkAutoProcess.Value
                        uialert(obj.fig, 'Daftar koordinat notch masih kosong. Tambahkan notch terlebih dahulu.', 'Peringatan');
                    end
                    return;
                end
            end

            % Nonaktifkan simpan sementara selama proses berjalan
            obj.btnSave.Enable = 'off';
            obj.lblInfo.FontColor = [0.2, 0.2, 0.2];
            obj.lblInfo.Text = 'Status: Sedang memproses citra...';
            drawnow limitrate;

            tStart = tic;
            try
                switch catVal
                    case 'Low-Pass Filter (LPF)'
                        d0 = obj.sldParam1.Value;
                        if strcmp(subVal, 'Ideal')
                            filterFunc = @(chan) IdealLowPassFilter.apply(chan, d0);
                            obj.maskCurrent = IdealLowPassFilter.create(rows, cols, d0);
                        elseif strcmp(subVal, 'Butterworth')
                            n = round(obj.sldParam2.Value);
                            filterFunc = @(chan) ButterworthLowPassFilter.apply(chan, d0, n);
                            obj.maskCurrent = ButterworthLowPassFilter.create(rows, cols, d0, n);
                        else
                            filterFunc = @(chan) GaussianLowPassFilter.apply(chan, d0);
                            obj.maskCurrent = GaussianLowPassFilter.create(rows, cols, d0);
                        end
                        obj.imgProcessed = obj.applyChannelwise(img, filterFunc);

                    case 'High-Pass Filter (HPF)'
                        d0 = obj.sldParam1.Value;
                        if strcmp(subVal, 'Ideal')
                            filterFunc = @(chan) IdealHighPassFilter.apply(chan, d0);
                            obj.maskCurrent = IdealHighPassFilter.create(rows, cols, d0);
                        elseif strcmp(subVal, 'Butterworth')
                            n = round(obj.sldParam2.Value);
                            filterFunc = @(chan) ButterworthHighPassFilter.apply(chan, d0, n);
                            obj.maskCurrent = ButterworthHighPassFilter.create(rows, cols, d0, n);
                        else
                            filterFunc = @(chan) GaussianHighPassFilter.apply(chan, d0);
                            obj.maskCurrent = GaussianHighPassFilter.create(rows, cols, d0);
                        end
                        obj.imgProcessed = obj.applyChannelwise(img, filterFunc);

                    case 'Brightness Enhancement'
                        gain = obj.sldParam1.Value;
                        if strcmp(subVal, 'DC Boost')
                            filterFunc = @(chan) BrightnessEnhancement.enhanceDC(chan, gain);
                            obj.maskCurrent = ones(rows, cols);
                            centerRow = floor(rows / 2) + 1;
                            centerCol = floor(cols / 2) + 1;
                            obj.maskCurrent(centerRow, centerCol) = gain;
                        else
                            d0 = obj.sldParam2.Value;
                            filterFunc = @(chan) BrightnessEnhancement.enhanceLowFrequency(chan, gain, d0);
                            if size(img, 3) == 3
                                [~, obj.maskCurrent] = BrightnessEnhancement.enhanceLowFrequency(img(:,:,1), gain, d0);
                            else
                                [~, obj.maskCurrent] = BrightnessEnhancement.enhanceLowFrequency(img, gain, d0);
                            end
                        end
                        obj.imgProcessed = obj.applyChannelwise(img, filterFunc);

                    case 'Periodic Noise Restoration'
                        if startsWith(subVal, 'Bandreject')
                            d0 = obj.sldParam1.Value;
                            bw = obj.sldParam2.Value;
                            % Validasi konsistensi cutoff dan bandwidth (cutoff > bandwidth/2)
                            if d0 - (bw / 2) <= 0
                                bw = max(1, 2 * d0 - 2);
                                obj.sldParam2.Value = bw;
                                obj.edtParam2.Value = bw;
                            end

                            if contains(subVal, 'Ideal')
                                typeStr = 'ideal';
                                n = 1;
                            elseif contains(subVal, 'Gaussian')
                                typeStr = 'gaussian';
                                n = 1;
                            else
                                typeStr = 'butterworth';
                                n = round(obj.sldParam3.Value);
                            end
                            filt = BandrejectFilter.create(rows, cols, typeStr, d0, bw, n);
                            [obj.imgProcessed, obj.maskCurrent] = filt.applyWithFilter(img);
                            obj.imgProcessed = max(0, min(1, obj.imgProcessed));
                        else
                            if isempty(obj.notchList)
                                obj.invalidateProcessedResult('Daftar notch masih kosong. Tentukan titik notch terlebih dahulu.');
                                if ~obj.chkAutoProcess.Value
                                    uialert(obj.fig, 'Daftar koordinat notch masih kosong. Tambahkan notch terlebih dahulu.', 'Peringatan');
                                end
                                return;
                            end
                            d0 = obj.sldParam1.Value;
                            if contains(subVal, 'Ideal')
                                typeStr = 'ideal';
                                n = 1;
                            elseif contains(subVal, 'Gaussian')
                                typeStr = 'gaussian';
                                n = 1;
                            else
                                typeStr = 'butterworth';
                                n = round(obj.sldParam2.Value);
                            end
                            filt = NotchRejectFilter.create(rows, cols, typeStr, obj.notchList, d0, n);
                            [obj.imgProcessed, obj.maskCurrent] = filt.applyWithFilter(img);
                            obj.imgProcessed = max(0, min(1, obj.imgProcessed));
                        end

                    case 'Motion Blur Restoration'
                        L = obj.sldParam1.Value;
                        theta = obj.sldParam2.Value;
                        H = MotionBlurModel.create(rows, cols, L, theta);

                        if strcmp(subVal, 'Wiener Filter')
                            K = obj.sldParam3.Value;
                            [obj.imgProcessed, W] = WienerFilter.applyWithFilter(img, H, K);
                            obj.maskCurrent = abs(W);
                        else
                            rc = obj.sldParam3.Value;
                            epsVal = obj.sldParam4.Value;
                            [obj.imgProcessed, M_inv] = InverseFilter.applyWithFilter(img, H, rc, epsVal);
                            obj.maskCurrent = abs(M_inv);
                        end
                end

                tElapsed = toc(tStart);

                % Perbarui tampilan output dan mask tanpa distorsi
                cla(obj.axOutput);
                imshow(obj.imgProcessed, 'Parent', obj.axOutput);
                axis(obj.axOutput, 'image');
                title(obj.axOutput, sprintf('Hasil: %s (%s)', catVal, subVal));

                cla(obj.axMask);
                imshow(obj.maskCurrent, [], 'Parent', obj.axMask);
                axis(obj.axMask, 'image');
                colormap(obj.axMask, 'gray');
                title(obj.axMask, 'Mask Fungsi Transfer Penapis H(u, v)');

                % Aktifkan tombol simpan hanya bila hasil valid
                obj.btnSave.Enable = 'on';

                obj.lblInfo.FontColor = [0.1, 0.5, 0.1];
                obj.lblInfo.Text = sprintf('Selesai dalam %.2f detik. Dimensi citra: %dx%d.', tElapsed, rows, cols);
            catch err
                % Bersihkan state agar hasil gagal tidak dianggap valid
                obj.imgProcessed = [];
                obj.maskCurrent = [];
                obj.btnSave.Enable = 'off';
                cla(obj.axOutput);
                title(obj.axOutput, 'Citra Hasil (Pemrosesan Gagal)');
                cla(obj.axMask);
                title(obj.axMask, 'Mask Penapis H(u, v)');

                if ~obj.chkAutoProcess.Value
                    uialert(obj.fig, sprintf('Terjadi kesalahan pemrosesan: %s', err.message), 'Error Pemrosesan');
                end
                obj.lblInfo.FontColor = [0.8, 0.1, 0.1];
                obj.lblInfo.Text = sprintf('Status: Error pemrosesan (%s)', err.message);
            end
        end

        function out = applyChannelwise(~, img, func)
            if ndims(img) == 3 && size(img, 3) == 3
                out = zeros(size(img));
                for c = 1:3
                    out(:,:,c) = func(img(:,:,c));
                end
            else
                out = func(img);
            end
        end
    end
end
