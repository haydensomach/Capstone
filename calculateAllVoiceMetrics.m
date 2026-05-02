function out = calculateAllVoiceMetrics(filepath)
% ChatGPT used for formatting the code.

% The function of this script is to actually calculate the values for each metric
% by calling the local toolbox functions to do the math. This script is 
% used for creating a large excel sheet.

% Input: a file path to a folder/single file of .wave file/s
% Output: write to excel the metrics values.

J = calculateJitter(filepath);
S = calculateShimmer(filepath);
H = calculateHNR(filepath);
P = calculatePSDJitter(filepath);

% -------------------------------------------------
% Basic consistency check
% -------------------------------------------------
nJ = J.nFiles;
nS = S.nFiles;
nH = H.nFiles;
nP = P.nFiles;

if ~(nJ == nS && nS == nH && nH == nP)
    error('Metric outputs do not contain the same number of files.');
end

nFiles = nJ;

% -------------------------------------------------
% Preallocate combined output
% -------------------------------------------------
files = repmat(struct( ...
    'fileName', "", ...
    'fullPath', "", ...
    'fs_Hz', NaN, ...
    'duration_s', NaN, ...
    'F0_Hz', NaN, ...
    'jitter_percent', NaN, ...
    'shimmer_percent', NaN, ...
    'HNR_dB', NaN, ...
    'PSD_jitter_percent', NaN, ...
    'nPeriodsUsed', NaN, ...
    'nAmplitudesUsed', NaN, ...
    'nSecondsUsed', NaN), nFiles, 1);

% -------------------------------------------------
% Merge file-by-file
% -------------------------------------------------
for k = 1:nFiles
    files(k).fileName = J.files(k).fileName;
    files(k).fullPath = J.files(k).fullPath;
    files(k).fs_Hz    = J.files(k).fs_Hz;
    files(k).duration_s = J.files(k).duration_s;
    files(k).F0_Hz    = J.files(k).F0_Hz;

    files(k).jitter_percent    = J.files(k).jitter_percent;
    files(k).nPeriodsUsed      = J.files(k).nPeriodsUsed;

    files(k).shimmer_percent   = S.files(k).shimmer_percent;
    files(k).nAmplitudesUsed   = S.files(k).nAmplitudesUsed;

    files(k).HNR_dB            = H.files(k).HNR_dB;

    files(k).PSD_jitter_percent = P.files(k).PSD_jitter_percent;
    files(k).nSecondsUsed       = P.files(k).nSecondsUsed;
end

% -------------------------------------------------
% Final output struct
% -------------------------------------------------
out = struct();
out.inputPath = string(filepath);
out.nFiles    = nFiles;
out.files     = files;

% -------------------------------------------------
% Post-processing: flag outliers and write to Excel
% -------------------------------------------------

% Collect per-file scalar metrics into flat arrays for statistics
fileNames_all = {files.fileName}';
fullPaths_all = {files.fullPath}';
fs_all        = [files.fs_Hz]';
duration_all  = [files.duration_s]';
F0_all        = [files.F0_Hz]';
HNR_all       = [files.HNR_dB]';
jitter_all    = [files.jitter_percent]';
shimmer_all   = [files.shimmer_percent]';
PSD_all       = [files.PSD_jitter_percent]';
nPeriods_all    = [files.nPeriodsUsed]';
nAmplitudes_all = [files.nAmplitudesUsed]';
nSeconds_all    = [files.nSecondsUsed]';

% Global statistics
mu_F0      = mean(F0_all,      'omitnan');  sigma_F0      = std(F0_all,      'omitnan');
mu_HNR     = mean(HNR_all,     'omitnan');  sigma_HNR     = std(HNR_all,     'omitnan');
mu_jitter  = mean(jitter_all,  'omitnan');  sigma_jitter  = std(jitter_all,  'omitnan');
mu_shimmer = mean(shimmer_all, 'omitnan');  sigma_shimmer = std(shimmer_all, 'omitnan');
mu_PSD     = mean(PSD_all,     'omitnan');  sigma_PSD     = std(PSD_all,     'omitnan');

% Flag suspects (>2 sigma from mean)
suspectF0_all      = abs(F0_all      - mu_F0)      > 2*sigma_F0;
suspectHNR_all     = abs(HNR_all     - mu_HNR)     > 2*sigma_HNR;
suspectJitter_all  = abs(jitter_all  - mu_jitter)  > 2*sigma_jitter;
suspectShimmer_all = abs(shimmer_all - mu_shimmer) > 2*sigma_shimmer;
suspectPSD_all     = abs(PSD_all     - mu_PSD)     > 2*sigma_PSD;

% Clear suspect flags on NaN rows (no data = no flag) 
suspectF0_all(isnan(F0_all))           = false;
suspectHNR_all(isnan(HNR_all))         = false;
suspectJitter_all(isnan(jitter_all))   = false;
suspectShimmer_all(isnan(shimmer_all)) = false;
suspectPSD_all(isnan(PSD_all))         = false;

% Build results table
resultsTable = table( ...
    fileNames_all, fullPaths_all, fs_all, duration_all, ...
    F0_all, HNR_all, PSD_all, jitter_all, shimmer_all, ...
    nPeriods_all, nAmplitudes_all, nSeconds_all, ...
    suspectF0_all, suspectHNR_all, suspectPSD_all, suspectJitter_all, suspectShimmer_all, ...
    'VariableNames', { ...
    'FileName', 'FullPath', 'Fs_Hz', 'Duration_s', ...
    'F0_Hz', 'HNR_dB', 'PSD_Jitter_percent', 'Jitter_percent', 'Shimmer_percent', ...
    'NPeriodsUsed', 'NAmplitudesUsed', 'NSecondsUsed', ...
    'Suspect_F0', 'Suspect_HNR', 'Suspect_PSD', 'Suspect_Jitter', 'Suspect_Shimmer'});

% Resolve output folder (same location as input)
filepath_char = char(filepath);
if isfolder(filepath_char)
    folderPath = filepath_char;
else
    folderPath = fileparts(filepath_char);
end

% Write to Excel
excelFileName = fullfile(folderPath, 'audio_metrics_results.xlsx');
writetable(resultsTable, excelFileName);
fprintf('\nResults written to:\n%s\n', excelFileName);
end