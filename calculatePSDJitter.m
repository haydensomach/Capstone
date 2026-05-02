function out = calculatePSDJitter(filepath)
% ChatGPT used for formatting the code.

% The function only calculates per second harmoinc contribution

% Input: a file path to a folder/single file of .wave file/s
% Ouptut: a struct of results that has per second harmoinc contribution information

    results = analyzeVoiceMetrics(filepath);
    n = numel(results);

    files = repmat(struct( ...
        'fileName', "", ...
        'fullPath', "", ...
        'fs_Hz', NaN, ...
        'duration_s', NaN, ...
        'F0_Hz', NaN, ...
        'PSD_jitter_percent', NaN, ...
        'nSecondsUsed', NaN), n, 1);

    for k = 1:n
        files(k).fileName           = results(k).fileName;
        files(k).fullPath           = results(k).fullPath;
        files(k).fs_Hz              = results(k).fs_Hz;
        files(k).duration_s         = results(k).duration_s;
        files(k).F0_Hz              = results(k).F0_Hz;
        files(k).PSD_jitter_percent = results(k).PSD_jitter_percent;
        files(k).nSecondsUsed       = results(k).nSecondsUsed;
    end

    out = struct();
    out.inputPath = string(filepath);
    out.metric    = "PSD Jitter";
    out.nFiles    = n;
    out.files     = files;
end