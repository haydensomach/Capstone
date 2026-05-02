function out = extractPoincareData(folderPath, groupLabel)
% ChatGPT used for formatting the code.

% The function of this script is to extract the poincare plot data 

% Input: a single folder with ALS or non-ALS, and its label
% Output: a struct with the poincare data

if ~isfolder(folderPath)
    error('extractPoincareData:InputError', 'folderPath must be a valid folder.');
end

% ---------------------------------------------------------------------
% Use shared backend logic
% ---------------------------------------------------------------------
rawResults = analyzeVoiceMetrics(folderPath);

nFiles = numel(rawResults);

T_periods_all = cell(nFiles, 1);
A_pp_all      = cell(nFiles, 1);
PC_all        = cell(nFiles, 1);
fileNames_all = strings(nFiles, 1);

for n = 1:nFiles
    fileNames_all(n) = rawResults(n).fileName;

    % Raw pitch periods
    if isfield(rawResults, 'T_periods_raw') && ~isempty(rawResults(n).T_periods_raw)
        T_periods_all{n} = rawResults(n).T_periods_raw(:);
    end

    % Raw peak-to-peak amplitudes
    if isfield(rawResults, 'A_pp_raw') && ~isempty(rawResults(n).A_pp_raw)
        A_pp_all{n} = rawResults(n).A_pp_raw(:);
    end

    % Raw harmonic power contribution matrix
    if isfield(rawResults, 'PC_mat_raw') && ~isempty(rawResults(n).PC_mat_raw)
        PC_all{n} = rawResults(n).PC_mat_raw;
    end
end

out = struct();
out.groupLabel   = string(groupLabel);
out.folderPath   = string(folderPath);
out.nFiles       = nFiles;
out.fileNames_all = fileNames_all;
out.T_periods_all = T_periods_all;
out.A_pp_all      = A_pp_all;
out.PC_all        = PC_all;
end