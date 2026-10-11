% Entry point to launch the IF4073 Frequency Domain Image Processing GUI
function app = runApp()
    repoRoot = fileparts(mfilename('fullpath'));
    addpath(genpath(fullfile(repoRoot, 'src')));
    addpath(fullfile(repoRoot, 'tests'));

    app = IntegratedGUI();
end
