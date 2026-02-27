%% ================================================================
%  Minsk2020 Audio Inspector + Period Timestamps Overlay
%  ------------------------------------------------
%  Behavior:
%   - Filter (optional) by Status/Sex/Age/Vowel ("All" = no filter)
%   - Select ONE file
%   - Enter start time + window duration
%   - Plot waveform in that window
%   - Overlay vertical dashed lines at cycle timestamps computed by
%     your period detection (findFundamentalPeriodGroup)
%   - SCRIPT ENDS
%
%  Notes:
%   - No audio playback
%   - Your jitter/shimmer/PPQ5 functions are included at the bottom
%% ================================================================

clear; clc; close all;

%% ----------- PATHS (edit if needed) ----------------
audioDirAls = '/Users/hayden/Documents/Minsk2020_ALS_database/ALS';
audioDirHC  = '/Users/hayden/Documents/Minsk2020_ALS_database/HC';

if ~isfolder(audioDirAls), error('ALS folder not found: %s', audioDirAls); end
if ~isfolder(audioDirHC),  error('HC folder not found: %s', audioDirHC);  end

%% ----------- Read wav file lists (recursive) --------
filesAls = dir(fullfile(audioDirAls, '**', '*.wav'));
filesHC  = dir(fullfile(audioDirHC,  '**', '*.wav'));

if isempty(filesAls), error('No ALS wav files found in %s', audioDirAls); end
if isempty(filesHC),  error('No HC wav files found in %s',  audioDirHC);  end

% Deterministic ordering (closest to your original k/2 subject logic)
[~, ia] = sort({filesAls.name}); filesAls = filesAls(ia);
[~, ih] = sort({filesHC.name});  filesHC  = filesHC(ih);

%% ----------- Subject index lists (from your code) ----
ALS_maleIdx = [1, 5:12, 16:20, 22:25, 29, 30];
HC_maleIdx  = [3:10, 13, 21, 26, 29, 30];

ALS_ageIdx1 = [2:3, 6:8, 13, 17:20, 25:28, 31];
ALS_ageIdx2 = [1, 4:5, 9:12, 14:16, 21:24, 29:30];

HC_ageIdx1  = [2:4, 6:7, 9, 11:14, 16, 18:20, 22, 25:26, 29];
HC_ageIdx2  = [1, 5, 8, 10, 15, 17, 21, 27:28, 30:33];

%% ----------- Build a unified catalog of all files ----------
catalog = {};

% ---- ALS ----
for k = 1:numel(filesAls)
    fullpath = fullfile(filesAls(k).folder, filesAls(k).name);
    [x, fs] = audioread(fullpath);
    if size(x,2) > 1, x = mean(x,2); end
    x = x - mean(x);

    subj  = ceil(k/2);
    if mod(k,2)==1, vowel='A'; else, vowel='I'; end

    isMale = ismember(subj, ALS_maleIdx);
    isAge1 = ismember(subj, ALS_ageIdx1);
    isAge2 = ismember(subj, ALS_ageIdx2);

    item.audio    = x;
    item.fs       = fs;
    item.file     = filesAls(k).name;
    item.folder   = filesAls(k).folder;
    item.fullpath = fullpath;
    item.status   = 'ALS';
    item.subject  = subj;
    if isMale, item.sex='Male'; else, item.sex='Female'; end
    if isAge1, item.agegrp='Age1'; elseif isAge2, item.agegrp='Age2'; else, item.agegrp='(unassigned)'; end
    item.vowel    = vowel;

    catalog{end+1} = item; %#ok<SAGROW>
end

% ---- HC (nonALS) ----
for k = 1:numel(filesHC)
    fullpath = fullfile(filesHC(k).folder, filesHC(k).name);
    [x, fs] = audioread(fullpath);
    if size(x,2) > 1, x = mean(x,2); end
    x = x - mean(x);

    subj  = ceil(k/2);
    if mod(k,2)==1, vowel='A'; else, vowel='I'; end

    isMale = ismember(subj, HC_maleIdx);
    isAge1 = ismember(subj, HC_ageIdx1);
    isAge2 = ismember(subj, HC_ageIdx2);

    item.audio    = x;
    item.fs       = fs;
    item.file     = filesHC(k).name;
    item.folder   = filesHC(k).folder;
    item.fullpath = fullpath;
    item.status   = 'nonALS';
    item.subject  = subj;
    if isMale, item.sex='Male'; else, item.sex='Female'; end
    if isAge1, item.agegrp='Age1'; elseif isAge2, item.agegrp='Age2'; else, item.agegrp='(unassigned)'; end
    item.vowel    = vowel;

    catalog{end+1} = item; %#ok<SAGROW>
end

%% ----------- FILTER SELECTION (each can be "All") ----------
statusChoice = listdlg('PromptString','Filter: Status', 'SelectionMode','single', ...
    'ListString',{'All','ALS','nonALS'}, 'ListSize',[250 120]);
if isempty(statusChoice), return; end
statusStr = {'All','ALS','nonALS'}; statusStr = statusStr{statusChoice};

sexChoice = listdlg('PromptString','Filter: Sex', 'SelectionMode','single', ...
    'ListString',{'All','Male','Female'}, 'ListSize',[250 120]);
if isempty(sexChoice), return; end
sexStr = {'All','Male','Female'}; sexStr = sexStr{sexChoice};

ageChoice = listdlg('PromptString','Filter: Age Group', 'SelectionMode','single', ...
    'ListString',{'All','Age1','Age2'}, 'ListSize',[250 120]);
if isempty(ageChoice), return; end
ageStr = {'All','Age1','Age2'}; ageStr = ageStr{ageChoice};

vowelChoice = listdlg('PromptString','Filter: Vowel', 'SelectionMode','single', ...
    'ListString',{'All','A','I'}, 'ListSize',[250 120]);
if isempty(vowelChoice), return; end
vowelStr = {'All','A','I'}; vowelStr = vowelStr{vowelChoice};

%% ----------- APPLY FILTERS ----------
keepIdx = true(1,numel(catalog));
for i = 1:numel(catalog)
    it = catalog{i};
    if ~strcmp(statusStr,'All') && ~strcmp(it.status,statusStr), keepIdx(i)=false; continue; end
    if ~strcmp(sexStr,'All')    && ~strcmp(it.sex,sexStr),       keepIdx(i)=false; continue; end
    if ~strcmp(ageStr,'All')    && ~strcmp(it.agegrp,ageStr),    keepIdx(i)=false; continue; end
    if ~strcmp(vowelStr,'All')  && ~strcmp(it.vowel,vowelStr),   keepIdx(i)=false; continue; end
end

filtered = catalog(keepIdx);
if isempty(filtered)
    uiwait(warndlg('No files match those filters.','No matches'));
    return;
end

%% ----------- SELECT ONE FILE ----------
listStr = cell(numel(filtered),1);
for i = 1:numel(filtered)
    it = filtered{i};
    dur = numel(it.audio)/it.fs;
    listStr{i} = sprintf('%03d) %s | subj %d | %s %s %s %s | %.2fs', ...
        i, it.file, it.subject, it.status, it.sex, it.agegrp, it.vowel, dur);
end

fileChoice = listdlg('PromptString',sprintf('Select a file to view (%d matches)', numel(filtered)), ...
    'SelectionMode','single', 'ListString',listStr, 'ListSize',[780 420]);
if isempty(fileChoice), return; end

it = filtered{fileChoice};

%% ----------- SELECT WINDOW ----------
prompt = {'Start time (sec):','Window duration (sec):'};
def    = {'1.00','0.05'};
answ = inputdlg(prompt, 'Time Window', [1 40], def);
if isempty(answ), return; end

startSec = str2double(answ{1});
durSec   = str2double(answ{2});
if isnan(startSec) || isnan(durSec) || durSec <= 0
    error('Invalid start/duration.');
end

x  = it.audio(:);
fs = it.fs;
t  = (0:numel(x)-1)/fs;

startSec = max(0, startSec);
endSec   = min(t(end), startSec + durSec);

i1 = max(1, floor(startSec*fs)+1);
i2 = min(numel(x), floor(endSec*fs)+1);

%% ----------- GET CYCLE TIMESTAMPS USING YOUR PERIOD FUNCTION ----------
% Make a "single-file group" so we can call your group-based function as-is.
singleCell = {struct('audio', x)};

% Call your period detection to get cycle timestamps
[~, cycleTS] = findFundamentalPeriodGroup(it.status, it.sex, it.vowel, singleCell, singleCell, fs);

if strcmpi(it.vowel,'A')
    ts_list = cycleTS.A{1};
else
    ts_list = cycleTS.I{1};
end

%% ----------- PLOT + OVERLAY TIMESTAMP LINES ----------
figure;
plot(t(i1:i2), x(i1:i2));
xlim([t(i1) t(i2)]);   % <-- add this
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title(sprintf('%s | %s %s %s %s | subj %d | window %.3f–%.3fs', ...
    it.file, it.status, it.sex, it.agegrp, it.vowel, it.subject, t(i1), t(i2)));
hold on;

% Only draw lines that fall inside the visible window
if ~isempty(ts_list)
    ts_vis = ts_list(ts_list >= t(i1) & ts_list <= t(i2));
    for k = 1:numel(ts_vis)
        xline(ts_vis(k), 'k--', 'LineWidth', 1.0);
    end
end

hold off;

%% ================================================================
%% ------------ FUNCTION PPQ5 --------------------
function [localPPQ] = findPPQ5(statusStr, sexStr, vowelStr, dataA, dataI, fs)

[~, cycleTS] = findFundamentalPeriodGroup(statusStr,sexStr,vowelStr, dataA, dataI, fs);

if strcmpi(vowelStr,'A')
    temp_cycleTS = cycleTS.A;
else
    temp_cycleTS = cycleTS.I;
end

numFiles = length(temp_cycleTS);
localPPQ = NaN(numFiles,1);

for i = 1:numFiles

    ts = temp_cycleTS{i};

    % Need at least 6 timestamps -> 5 periods -> PPQ5 defined
    if length(ts) < 6
        continue
    end

    T = diff(ts);           % periods
    N = length(T);

    % Remove the first element
    T(1) = [];

    deviations = zeros(N-4,1);

    for k = 3:N-3
        localMean = (T(k-2) + T(k-1) + T(k) + T(k+1) + T(k+2)) / 5;
        deviations(k-2) = abs(T(k) - localMean);
    end

    numerator = (1/(N-4)) * sum(deviations);
    denominator = (1/N) * sum(T);

    localPPQ(i) = numerator / denominator;

end

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

    T = diff(ts);           % periods (T_i)
    N = length(T);

    % Remove the first element
    T(1) = [];

    % -------- Optional Plot --------
    if plotBool
        figure;
        plot(T, '-o');
        xlabel('Cycle Index');
        ylabel('Period Length (samples)');
        title(sprintf('File %d Period Array', i));
        grid on;
    end
    % --------------------------------

    % Numerator: (1/(N-1)) * sum |T_{i+1} - T_i|
    num = (1/(N-1)) * sum(abs(diff(T)));

    % Denominator: (1/N) * sum T_i
    den = (1/N) * sum(T);

    % Local jitter
    localJitter(i) = num / den;

end

end

%% ------------ FUNCTION Fundemental period --------------------
function [out, cycleTS] = findFundamentalPeriodGroup(statusStr, sexStr, vowelStr, dataA, dataI, fs)
% findFundamentalPeriodGroup
% Inputs:
%   statusStr: 'ALS' or 'nonALS'
%   sexStr:    'Male' or 'Female'
%   vowelStr:  'A' or 'I'
%   dataA:     cell array of structs with .audio
%   dataI:     cell array of structs with .audio
% Outputs:
%   out:    struct with per-file F0 estimates + group averages
%   cycleTS: struct with cycle timestamps for A and I (cell arrays)

% Select which vowel data to process
if strcmpi(vowelStr,'A')
    groups = {dataA, sprintf('%s %s A', statusStr, sexStr)};
elseif strcmpi(vowelStr,'I')
    groups = {dataI, sprintf('%s %s I', statusStr, sexStr)};
else
    error('vowelStr must be ''A'' or ''I''.');
end

% ---- Settings  ----
frameDur = 0.040;
hopDur   = 0.010;
frameLen = round(frameDur*fs);
hopLen   = round(hopDur*fs);

f0Min = 60;
f0Max = 400;
lagMin = round(fs/f0Max);
lagMax = round(fs/f0Min);

out = struct();
cycleTS = struct();

for g = 1:size(groups,1)

    data  = groups{g,1};
    label = groups{g,2};

    f0_all_acf  = zeros(length(data),1);

    % Number of columns = number of audio files
    cycleTimestamps = cell(length(data),1);

    for n = 1:length(data)
        x = data{n}.audio;
        x = x - mean(x);
        N = length(x);

        numFrames = floor((N - frameLen)/hopLen) + 1;
        f0_frames = NaN(numFrames,1);

        for m = 1:numFrames
            idx1 = (m-1)*hopLen + 1;
            idx2 = idx1 + frameLen - 1;

            frame = x(idx1:idx2);
            frame = frame - mean(frame);

            [r,lags] = xcorr(frame, frame);
            r = r(frameLen:end);
            r = r / (r(1) + eps);
            lags = lags(frameLen:end); %#ok<NASGU>

            search = r(lagMin:lagMax);
            [pk, idxPk] = max(search);
            bestLag = lagMin + idxPk - 1;

            if pk > 0.3
                f0_frames(m) = fs / bestLag;
            else
                f0_frames(m) = NaN;
            end
        end

        if all(isnan(f0_frames))
            f0_all_acf(n) = NaN;
        else
            f0_all_acf(n) = median(f0_frames,'omitnan');
        end

        % >>> iterative cycle timestamp extraction using same ACF lag logic
        % NOTE: I changed your original fixed start index (44100) to start at the beginning,
        % so timestamps exist regardless of what window you choose to plot.
        ts_samples = 1;                  % sample index of current "start" (1-based)
        ts_list = 0;                     % timestamps in seconds, starts with 0

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
                break;  % stop when periodicity is weak
            end

            ts_samples = ts_samples + bestLag2;
            if ts_samples > N
                break;
            end

            tSamp = (ts_samples - 1) / fs;     % convert sample index to seconds
            ts_list(end+1) = tSamp; %#ok<AGROW>

            % safety stop if we're too close to the end to measure another period
            if (ts_samples + lagMax) > N
                break;
            end
        end

        cycleTimestamps{n} = ts_list;
        % <<<

    end

    % Average across group (printed if you ever call this on many files)
    avgF0_acf = mean(f0_all_acf,'omitnan');
    fprintf('%s Average F0 (ACF): %.2f Hz\n', label, avgF0_acf);

    % Store outputs
    if contains(label, ' A')
        out.F0_A = f0_all_acf;
        out.avgF0_A = avgF0_acf;
        cycleTS.A = cycleTimestamps;
    else
        out.F0_I = f0_all_acf;
        out.avgF0_I = avgF0_acf;
        cycleTS.I = cycleTimestamps;
    end
end

end

%% ------------ FUNCTION SHIMMER --------------------
function [localShimmer] = findShimmer(statusStr, sexStr, vowelStr, dataA, dataI, fs)

[~, cycleTS] = findFundamentalPeriodGroup(statusStr,sexStr,vowelStr, dataA, dataI, fs);

if strcmpi(vowelStr,'A')
    temp_cycleTS = cycleTS.A;
    data = dataA;
else
    temp_cycleTS = cycleTS.I;
    data = dataI;
end

numFiles = length(temp_cycleTS);
localShimmer = NaN(numFiles,1);

for i = 1:numFiles

    ts = temp_cycleTS{i};

    % Need at least 3 timestamps -> 2 amplitude periods
    if length(ts) < 3
        continue
    end

    x = data{i}.audio;
    x = x - mean(x);

    % Convert timestamps to sample indices
    ts_samples = round(ts * fs) + 1;

    numPeriods = length(ts_samples) - 1;
    A = zeros(numPeriods,1);

    % ---- Compute peak-to-peak amplitude per period ----
    for k = 1:numPeriods
        idx1 = ts_samples(k);
        idx2 = ts_samples(k+1) - 1;

        if idx2 > length(x)
            idx2 = length(x);
        end

        segment = x(idx1:idx2);
        A(k) = max(segment) - min(segment);
    end

    % Remove first amplitude (consistent with jitter removing first T)
    A(1) = [];

    N = length(A);
    if N < 2
        continue
    end

    numerator = (1/(N-1)) * sum(abs(diff(A)));
    denominator = (1/N) * sum(A);

    localShimmer(i) = numerator / denominator;

end

end