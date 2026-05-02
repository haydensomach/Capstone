function out = calculateShimmer(filepath)
% ChatGPT was used to format this code

% The function only calculates Shimmer

% Input: a file path to a folder/single file of .wave file/s
% Output: a struct of results that has shimmer information

    results = analyzeVoiceMetrics(filepath);
    n = numel(results);

    files = repmat(struct( ...
        'fileName', "", ...
        'fullPath', "", ...
        'fs_Hz', NaN, ...
        'duration_s', NaN, ...
        'F0_Hz', NaN, ...
        'shimmer_percent', NaN, ...
        'nAmplitudesUsed', NaN), n, 1);

    for k = 1:n
        files(k).fileName          = results(k).fileName;
        files(k).fullPath          = results(k).fullPath;
        files(k).fs_Hz             = results(k).fs_Hz;
        files(k).duration_s        = results(k).duration_s;
        files(k).F0_Hz             = results(k).F0_Hz;
        files(k).shimmer_percent   = results(k).shimmer_percent;
        files(k).nAmplitudesUsed   = results(k).nAmplitudesUsed;
    end

    out = struct();
    out.inputPath = string(filepath);
    out.metric    = "Shimmer";
    out.nFiles    = n;
    out.files     = files;
end