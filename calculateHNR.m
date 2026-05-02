function out = calculateHNR(filepath)
% ChatGPT used for formatting the code.

% The function calculates HNR

% Input: a file path to a folder/single file of .wave file/s
% Output: a struct of results that has the HNR information

    results = analyzeVoiceMetrics(filepath);
    n = numel(results);

    files = repmat(struct( ...
        'fileName', "", ...
        'fullPath', "", ...
        'fs_Hz', NaN, ...
        'duration_s', NaN, ...
        'F0_Hz', NaN, ...
        'HNR_dB', NaN), n, 1);

    for k = 1:n
        files(k).fileName   = results(k).fileName;
        files(k).fullPath   = results(k).fullPath;
        files(k).fs_Hz      = results(k).fs_Hz;
        files(k).duration_s = results(k).duration_s;
        files(k).F0_Hz      = results(k).F0_Hz;
        files(k).HNR_dB     = results(k).HNR_dB;
    end

    out = struct();
    out.inputPath = string(filepath);
    out.metric    = "HNR";
    out.nFiles    = n;
    out.files     = files;
end