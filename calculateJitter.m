function out = calculateJitter(filepath)
% ChatGPT used for formatting the code.
% The function calculates Jitter

% Input: a file path to a folder/single file of .wave file/s
% Output: a struct of results that has HNR information
 
    results = analyzeVoiceMetrics(filepath);
    n = numel(results);

    files = repmat(struct( ...
        'fileName', "", ...
        'fullPath', "", ...
        'fs_Hz', NaN, ...
        'duration_s', NaN, ...
        'F0_Hz', NaN, ...
        'jitter_percent', NaN, ...
        'nPeriodsUsed', NaN), n, 1);

    for k = 1:n
        files(k).fileName       = results(k).fileName;
        files(k).fullPath       = results(k).fullPath;
        files(k).fs_Hz          = results(k).fs_Hz;
        files(k).duration_s     = results(k).duration_s;
        files(k).F0_Hz          = results(k).F0_Hz;
        files(k).jitter_percent = results(k).jitter_percent;
        files(k).nPeriodsUsed   = results(k).nPeriodsUsed;
    end

    out = struct();
    out.inputPath = string(filepath);
    out.metric    = "Jitter";
    out.nFiles    = n;
    out.files     = files;
end