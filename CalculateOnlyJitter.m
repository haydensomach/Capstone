%% jitter_subgroup_runner.m
% • Purpose:
%   - Load Minsk2020 ALS + HC vowel files
%   - Split into subgroups (ALS/HC × Male/Female × Age1/Age2 × A/I)
%   - Compute jitter for each subgroup
%   - Store jitter vectors + summary stats in arrays/structs

clear; clc; close all;

%% ----------- Read in audio files ----------------
audioDirAls = '/Users/hayden/Documents/Minsk2020_ALS_database/ALS';
audioDirHC  = '/Users/hayden/Documents/Minsk2020_ALS_database/HC';

filesAls = dir(fullfile(audioDirAls, '**', '*.wav'));
filesHC  = dir(fullfile(audioDirHC,  '**', '*.wav'));

% Sampling rate (assumes consistent fs across files)
[~, fs] = audioread(fullfile(filesHC(1).folder, filesHC(1).name));

%% ----------- Index lists (your originals) ----------------
ALS_maleIdx = [1, 5:12, 16:20, 22:25, 29, 30];
HC_maleIdx  = [3:10, 13, 21, 26, 29, 30];

ALS_ageIdx1 = [2:3, 6:8, 13, 17:20, 25:28, 31];
ALS_ageIdx2 = [1, 4:5, 9:12, 14:16, 21:24, 29:30];
HC_ageIdx1  = [2:4, 6:7, 9, 11:14, 16, 18:20, 22, 25:26, 29];
HC_ageIdx2  = [1, 5, 8, 10, 15, 17, 21, 27:28, 30:33];

%% ----------- Initialize subgroup cell arrays ----------------
ALS_Male_Age1_A   = {}; ALS_Male_Age1_I   = {};
ALS_Male_Age2_A   = {}; ALS_Male_Age2_I   = {};
ALS_Female_Age1_A = {}; ALS_Female_Age1_I = {};
ALS_Female_Age2_A = {}; ALS_Female_Age2_I = {};

HC_Male_Age1_A    = {}; HC_Male_Age1_I    = {};
HC_Male_Age2_A    = {}; HC_Male_Age2_I    = {};
HC_Female_Age1_A  = {}; HC_Female_Age1_I  = {};
HC_Female_Age2_A  = {}; HC_Female_Age2_I  = {};

%% ------------------ Process ALS ------------------
idx = struct( ...
    'MA1A',1,'MA1I',1,'MA2A',1,'MA2I',1, ...
    'FA1A',1,'FA1I',1,'FA2A',1,'FA2I',1);

for k = 1:length(filesAls)

    [x, fs] = audioread(fullfile(filesAls(k).folder, filesAls(k).name));
    if size(x,2) > 1, x = mean(x,2); end

    subj   = ceil(k/2);
    isMale = ismember(subj, ALS_maleIdx);
    isAge1 = ismember(subj, ALS_ageIdx1);
    isAge2 = ismember(subj, ALS_ageIdx2);

    isA = (mod(k,2) == 1); % odd->A, even->I

    if isMale && isAge1 && isA
        ALS_Male_Age1_A{idx.MA1A}.audio = x; idx.MA1A = idx.MA1A + 1;
    elseif isMale && isAge1 && ~isA
        ALS_Male_Age1_I{idx.MA1I}.audio = x; idx.MA1I = idx.MA1I + 1;
    elseif isMale && isAge2 && isA
        ALS_Male_Age2_A{idx.MA2A}.audio = x; idx.MA2A = idx.MA2A + 1;
    elseif isMale && isAge2 && ~isA
        ALS_Male_Age2_I{idx.MA2I}.audio = x; idx.MA2I = idx.MA2I + 1;

    elseif ~isMale && isAge1 && isA
        ALS_Female_Age1_A{idx.FA1A}.audio = x; idx.FA1A = idx.FA1A + 1;
    elseif ~isMale && isAge1 && ~isA
        ALS_Female_Age1_I{idx.FA1I}.audio = x; idx.FA1I = idx.FA1I + 1;
    elseif ~isMale && isAge2 && isA
        ALS_Female_Age2_A{idx.FA2A}.audio = x; idx.FA2A = idx.FA2A + 1;
    elseif ~isMale && isAge2 && ~isA
        ALS_Female_Age2_I{idx.FA2I}.audio = x; idx.FA2I = idx.FA2I + 1;
    end
end

%% ------------------ Process HC ------------------
idx = struct( ...
    'MA1A',1,'MA1I',1,'MA2A',1,'MA2I',1, ...
    'FA1A',1,'FA1I',1,'FA2A',1,'FA2I',1);

for k = 1:length(filesHC)

    [x, fs] = audioread(fullfile(filesHC(k).folder, filesHC(k).name));
    if size(x,2) > 1, x = mean(x,2); end

    subj   = ceil(k/2);
    isMale = ismember(subj, HC_maleIdx);
    isAge1 = ismember(subj, HC_ageIdx1);
    isAge2 = ismember(subj, HC_ageIdx2);

    isA = (mod(k,2) == 1); % odd->A, even->I

    if isMale && isAge1 && isA
        HC_Male_Age1_A{idx.MA1A}.audio = x; idx.MA1A = idx.MA1A + 1;
    elseif isMale && isAge1 && ~isA
        HC_Male_Age1_I{idx.MA1I}.audio = x; idx.MA1I = idx.MA1I + 1;
    elseif isMale && isAge2 && isA
        HC_Male_Age2_A{idx.MA2A}.audio = x; idx.MA2A = idx.MA2A + 1;
    elseif isMale && isAge2 && ~isA
        HC_Male_Age2_I{idx.MA2I}.audio = x; idx.MA2I = idx.MA2I + 1;

    elseif ~isMale && isAge1 && isA
        HC_Female_Age1_A{idx.FA1A}.audio = x; idx.FA1A = idx.FA1A + 1;
    elseif ~isMale && isAge1 && ~isA
        HC_Female_Age1_I{idx.FA1I}.audio = x; idx.FA1I = idx.FA1I + 1;
    elseif ~isMale && isAge2 && isA
        HC_Female_Age2_A{idx.FA2A}.audio = x; idx.FA2A = idx.FA2A + 1;
    elseif ~isMale && isAge2 && ~isA
        HC_Female_Age2_I{idx.FA2I}.audio = x; idx.FA2I = idx.FA2I + 1;
    end
end

%% ----------- Compute jitter for each subgroup + store -----------
% • Jitter.(key) stores the raw jitter vector (fractional units)
% • JitterStats.(key) stores mean/std in percent + count of valid values

jitterSpecs = { ...
    'ALS','Male','A', ALS_Male_Age1_A,   ALS_Male_Age1_I,   'ALS_Male_Age1_A';
    'ALS','Male','I', ALS_Male_Age1_A,   ALS_Male_Age1_I,   'ALS_Male_Age1_I';
    'ALS','Female','A', ALS_Female_Age1_A, ALS_Female_Age1_I, 'ALS_Female_Age1_A';
    'ALS','Female','I', ALS_Female_Age1_A, ALS_Female_Age1_I, 'ALS_Female_Age1_I';

    'ALS','Male','A', ALS_Male_Age2_A,   ALS_Male_Age2_I,   'ALS_Male_Age2_A';
    'ALS','Male','I', ALS_Male_Age2_A,   ALS_Male_Age2_I,   'ALS_Male_Age2_I';
    'ALS','Female','A', ALS_Female_Age2_A, ALS_Female_Age2_I, 'ALS_Female_Age2_A';
    'ALS','Female','I', ALS_Female_Age2_A, ALS_Female_Age2_I, 'ALS_Female_Age2_I';

    'nonALS','Male','A', HC_Male_Age1_A,   HC_Male_Age1_I,   'HC_Male_Age1_A';
    'nonALS','Male','I', HC_Male_Age1_A,   HC_Male_Age1_I,   'HC_Male_Age1_I';
    'nonALS','Female','A', HC_Female_Age1_A, HC_Female_Age1_I, 'HC_Female_Age1_A';
    'nonALS','Female','I', HC_Female_Age1_A, HC_Female_Age1_I, 'HC_Female_Age1_I';

    'nonALS','Male','A', HC_Male_Age2_A,   HC_Male_Age2_I,   'HC_Male_Age2_A';
    'nonALS','Male','I', HC_Male_Age2_A,   HC_Male_Age2_I,   'HC_Male_Age2_I';
    'nonALS','Female','A', HC_Female_Age2_A, HC_Female_Age2_I, 'HC_Female_Age2_A';
    'nonALS','Female','I', HC_Female_Age2_A, HC_Female_Age2_I, 'HC_Female_Age2_I';
};

Jitter = struct();
JitterStats = struct();

for s = 1:size(jitterSpecs,1)
    statusStr = jitterSpecs{s,1};
    sexStr    = jitterSpecs{s,2};
    vowelStr  = jitterSpecs{s,3};
    dataA     = jitterSpecs{s,4};
    dataI     = jitterSpecs{s,5};
    key       = jitterSpecs{s,6};

    v = findJitter(statusStr, sexStr, vowelStr, dataA, dataI, fs, 0);

    Jitter.(key) = v;

    v_pct = 100*v;
    JitterStats.(key).mean_pct = mean(v_pct,'omitnan');
    JitterStats.(key).sd_pct   = std(v_pct,'omitnan');
    JitterStats.(key).N_valid  = sum(~isnan(v));
end

% ===== PRINT FULL JITTER VECTORS (entire arrays) =====
fprintf('\n========== FULL JITTER VECTORS (FRACTIONAL) ==========\n\n');

keys = fieldnames(Jitter);

for i = 1:numel(keys)
    k = keys{i};
    v = Jitter.(k);

    fprintf('%s:\n', k);

    if isempty(v)
        fprintf('  [empty]\n\n');
        continue
    end

    % Print entire vector on one line (scientific notation is nice for small values)
    fprintf('  [');
    fprintf(' %.6e', v);   % prints every element
    fprintf(' ]\n\n');
end

% (Optional) also print in percent units:
fprintf('\n========== FULL JITTER VECTORS (PERCENT) ==========\n\n');
for i = 1:numel(keys)
    k = keys{i};
    v = 100 * Jitter.(k);

    fprintf('%s:\n', k);

    if isempty(v)
        fprintf('  [empty]\n\n');
        continue
    end

    fprintf('  [');
    fprintf(' %.6f', v);   % percent values
    fprintf(' ]\n\n');
end

%% ----------- Print summary (optional) -----------
fprintf('\n========== JITTER RESULTS ==========\n\n')
keys = fieldnames(JitterStats);
for i = 1:numel(keys)
    k = keys{i};
    fprintf('%s Jitter: %.3f %% ± %.3f %%  (N=%d)\n', ...
        k, JitterStats.(k).mean_pct, JitterStats.(k).sd_pct, JitterStats.(k).N_valid);
end

%% ------------ FUNCTION JITTER --------------------
function [localJitter] = findJitter(statusStr, sexStr, vowelStr, dataA, dataI, fs, plotBool)

[~, cycleTS] = findFundamentalPeriodGroup(statusStr,sexStr,vowelStr, dataA, dataI, fs);

if strcmpi(vowelStr,'A')
    temp_cycleTS = cycleTS.A;
else
    temp_cycleTS = cycleTS.I;
end

numFiles = length(temp_cycleTS);
localJitter = NaN(numFiles,1);

for i = 1:numFiles

    ts = temp_cycleTS{i};

    % Need at least 3 timestamps -> 2 periods -> jitter defined
    if length(ts) < 3
        continue
    end

    T = diff(ts);           % periods (seconds)
    N = length(T);

    % Remove the first element (keep consistent with your pipeline)
    T(1) = [];
    N = length(T);

    if N < 2
        continue
    end

    % -------- Optional Plot --------
    if plotBool
        figure;
        plot(T, '-o');
        xlabel('Cycle Index');
        ylabel('Period Length (s)');
        title(sprintf('File %d Period Array', i));
        grid on;
    end
    % --------------------------------

    % Numerator: (1/(N-1)) * sum |T_{i+1} - T_i|
    num = (1/(N-1)) * sum(abs(diff(T)));

    % Denominator: (1/N) * sum T_i
    den = (1/N) * sum(T);

    localJitter(i) = num / den;

end

end

%% ------------ FUNCTION Fundamental period --------------------
function [out, cycleTS] = findFundamentalPeriodGroup(statusStr, sexStr, vowelStr, dataA, dataI, fs)

if strcmpi(vowelStr,'A')
    groups = {dataA, sprintf('%s %s A', statusStr, sexStr)};
elseif strcmpi(vowelStr,'I')
    groups = {dataI, sprintf('%s %s I', statusStr, sexStr)};
else
    error('vowelStr must be ''A'' or ''I''.');
end

frameDur = 0.040;
frameLen = round(frameDur*fs);

f0Min = 60;
f0Max = 400;
lagMin = round(fs/f0Max);
lagMax = round(fs/f0Min);

out = struct();
cycleTS = struct();

for g = 1:size(groups,1)

    data  = groups{g,1};
    label = groups{g,2};

    cycleTimestamps = cell(length(data),1);

    for n = 1:length(data)
        x = data{n}.audio;
        x = x - mean(x);
        N = length(x);

        % >>> iterative cycle timestamp extraction using same ACF lag logic
        ts_samples = 44100;   % start index (1-based)
        ts_list = 0;          % timestamps in seconds, starts with 0

        while (ts_samples + frameLen - 1) <= N
            frame2 = x(ts_samples : ts_samples + frameLen - 1);
            frame2 = frame2 - mean(frame2);

            r2 = xcorr(frame2, frame2);
            r2 = r2(frameLen:end);
            r2 = r2 / (r2(1) + eps);

            search2 = r2(lagMin:lagMax);
            [pk2, idxPk2] = max(search2);
            bestLag2 = lagMin + idxPk2 - 1;

            if pk2 <= 0.3
                break;
            end

            ts_samples = ts_samples + bestLag2;
            if ts_samples > N
                break;
            end

            tSamp = (ts_samples - 1) / fs;
            ts_list(end+1) = tSamp; %#ok<AGROW>

            if (ts_samples + lagMax) > N
                break;
            end
        end

        cycleTimestamps{n} = ts_list;
        % <<<
    end

    if contains(label, ' A')
        cycleTS.A = cycleTimestamps;
    else
        cycleTS.I = cycleTimestamps;
    end
end

end