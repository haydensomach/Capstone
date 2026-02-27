clear; clc;
%% ----------- Read in audio files ----------------
audioDirAls = '/Users/hayden/Documents/Minsk2020_ALS_database/ALS';
audioDirHC  = '/Users/hayden/Documents/Minsk2020_ALS_database/HC';

filesAls = dir(fullfile(audioDirAls, '**', '*.wav'));
filesHC  = dir(fullfile(audioDirHC,  '**', '*.wav'));



%debug>>>>
%play file
playWavFile('/Users/hayden/Documents/Minsk2020_ALS_database/HC/004_a.wav');

[x, fs] = audioread('/Users/hayden/Documents/Minsk2020_ALS_database/HC/004_a.wav');

% Convert to mono if needed
if size(x,2) > 1
    x = mean(x,2);
end

% Remove DC offset (recommended for speech plots)
x = x - mean(x);

t = (0:length(x)-1)/fs;

figure;
plot(t, x);
xlabel('Time (s)');
xlim([0.4,0.6]);
ylabel('Amplitude');
title('004\_a.wav Waveform');
grid on;





% Preallocate
ALS_rawAudio_A = cell(length(filesAls)/2,1);
ALS_rawAudio_I = cell(length(filesAls)/2,1);

HC_rawAudio_A = cell(length(filesHC)/2,1);
HC_rawAudio_I = cell(length(filesHC)/2,1);

% Initialize
ALS_Male_A   = {};
ALS_Male_I   = {};
ALS_Female_A = {};
ALS_Female_I = {};

HC_Male_A    = {};
HC_Male_I    = {};
HC_Female_A  = {};
HC_Female_I  = {};

ALS_maleIdx = [1, 5:12, 16:20, 22:25, 29, 30];
HC_maleIdx  = [3:10, 13, 21, 26, 29, 30];

% NEW AGE GROUPS 
ALS_ageIdx1 = [2:3, 6:8, 13, 17:20, 25:28, 31]; 
ALS_ageIdx2 = [1, 4:5, 9:12, 14:16, 21:24, 29:30]; 
HC_ageIdx1 = [2:4, 6:7, 9, 11:14, 16, 18:20, 22, 25:26, 29]; 
HC_ageIdx2 = [1, 5, 8, 10, 15, 17, 21, 27:28, 30:33]; 

ALS_Age1_A   = {};
ALS_Age1_I   = {};
ALS_Age2_A   = {};
ALS_Age2_I   = {};

HC_Age1_A    = {};
HC_Age1_I    = {};
HC_Age2_A    = {};
HC_Age2_I    = {};

ALS_Male_Age1_A   = {};
ALS_Male_Age1_I   = {};
ALS_Male_Age2_A   = {};
ALS_Male_Age2_I   = {};

ALS_Female_Age1_A = {};
ALS_Female_Age1_I = {};
ALS_Female_Age2_A = {};
ALS_Female_Age2_I = {};

HC_Male_Age1_A    = {};
HC_Male_Age1_I    = {};
HC_Male_Age2_A    = {};
HC_Male_Age2_I    = {};

HC_Female_Age1_A  = {};
HC_Female_Age1_I  = {};
HC_Female_Age2_A  = {};
HC_Female_Age2_I  = {};


% Read in ALS files

idxMA = 1; idxMI = 1;
idxFA = 1; idxFI = 1;

idxA1A = 1; idxA1I = 1;
idxA2A = 1; idxA2I = 1;

idxMA1A = 1; idxMA1I = 1;
idxMA2A = 1; idxMA2I = 1;

idxFA1A = 1; idxFA1I = 1;
idxFA2A = 1; idxFA2I = 1;

for k = 1:length(filesAls)

    % Loop through ALS files, convert to mono
    [x, fs] = audioread(fullfile(filesAls(k).folder, filesAls(k).name));
    x = mean(x,2);


    % Subject index
    subj = ceil(k/2);
    isMale = ismember(subj, ALS_maleIdx);

    isAge1 = ismember(subj, ALS_ageIdx1);
    isAge2 = ismember(subj, ALS_ageIdx2);

    % A / I + Gender
    if mod(k,2) == 1   % A

        if isMale
            ALS_Male_A{idxMA}.audio = x;
            idxMA = idxMA + 1;
        else
            ALS_Female_A{idxFA}.audio = x;
            idxFA = idxFA + 1;
        end

        if isAge1
            ALS_Age1_A{idxA1A}.audio = x;
            idxA1A = idxA1A + 1;
        elseif isAge2
            ALS_Age2_A{idxA2A}.audio = x;
            idxA2A = idxA2A + 1;
        end

        if isMale && isAge1
            ALS_Male_Age1_A{idxMA1A}.audio = x;
            idxMA1A = idxMA1A + 1;
        elseif isMale && isAge2
            ALS_Male_Age2_A{idxMA2A}.audio = x;
            idxMA2A = idxMA2A + 1;
        elseif ~isMale && isAge1
            ALS_Female_Age1_A{idxFA1A}.audio = x;
            idxFA1A = idxFA1A + 1;
        elseif ~isMale && isAge2
            ALS_Female_Age2_A{idxFA2A}.audio = x;
            idxFA2A = idxFA2A + 1;
        end

    else              % I

        if isMale
            ALS_Male_I{idxMI}.audio = x;
            idxMI = idxMI + 1;
        else
            ALS_Female_I{idxFI}.audio = x;
            idxFI = idxFI + 1;
        end

        if isAge1
            ALS_Age1_I{idxA1I}.audio = x;
            idxA1I = idxA1I + 1;
        elseif isAge2
            ALS_Age2_I{idxA2I}.audio = x;
            idxA2I = idxA2I + 1;
        end

        if isMale && isAge1
            ALS_Male_Age1_I{idxMA1I}.audio = x;
            idxMA1I = idxMA1I + 1;
        elseif isMale && isAge2
            ALS_Male_Age2_I{idxMA2I}.audio = x;
            idxMA2I = idxMA2I + 1;
        elseif ~isMale && isAge1
            ALS_Female_Age1_I{idxFA1I}.audio = x;
            idxFA1I = idxFA1I + 1;
        elseif ~isMale && isAge2
            ALS_Female_Age2_I{idxFA2I}.audio = x;
            idxFA2I = idxFA2I + 1;
        end

    end

end



%% ------------------ Process HC ------------------



idxMA = 1; idxMI = 1;
idxFA = 1; idxFI = 1;

idxA1A = 1; idxA1I = 1;
idxA2A = 1; idxA2I = 1;

idxMA1A = 1; idxMA1I = 1;
idxMA2A = 1; idxMA2I = 1;

idxFA1A = 1; idxFA1I = 1;
idxFA2A = 1; idxFA2I = 1;

for k = 1:length(filesHC)

    [x, fs] = audioread(fullfile(filesHC(k).folder, filesHC(k).name));
    x = mean(x,2);


    % Subject index
    subj = ceil(k/2);
    isMale = ismember(subj, HC_maleIdx);

    isAge1 = ismember(subj, HC_ageIdx1);
    isAge2 = ismember(subj, HC_ageIdx2);

    % A / I + Gender
    if mod(k,2) == 1   % A

        if isMale
            HC_Male_A{idxMA}.audio = x;
            idxMA = idxMA + 1;
        else
            HC_Female_A{idxFA}.audio = x;
            idxFA = idxFA + 1;
        end

        if isAge1
            HC_Age1_A{idxA1A}.audio = x;
            idxA1A = idxA1A + 1;
        elseif isAge2
            HC_Age2_A{idxA2A}.audio = x;
            idxA2A = idxA2A + 1;
        end

        if isMale && isAge1
            HC_Male_Age1_A{idxMA1A}.audio = x;
            idxMA1A = idxMA1A + 1;
        elseif isMale && isAge2
            HC_Male_Age2_A{idxMA2A}.audio = x;
            idxMA2A = idxMA2A + 1;
        elseif ~isMale && isAge1
            HC_Female_Age1_A{idxFA1A}.audio = x;
            idxFA1A = idxFA1A + 1;
        elseif ~isMale && isAge2
            HC_Female_Age2_A{idxFA2A}.audio = x;
            idxFA2A = idxFA2A + 1;
        end

    else              % I

        if isMale
            HC_Male_I{idxMI}.audio = x;
            idxMI = idxMI + 1;
        else
            HC_Female_I{idxFI}.audio = x;
            idxFI = idxFI + 1;
        end

        if isAge1
            HC_Age1_I{idxA1I}.audio = x;
            idxA1I = idxA1I + 1;
        elseif isAge2
            HC_Age2_I{idxA2I}.audio = x;
            idxA2I = idxA2I + 1;
        end

        if isMale && isAge1
            HC_Male_Age1_I{idxMA1I}.audio = x;
            idxMA1I = idxMA1I + 1;
        elseif isMale && isAge2
            HC_Male_Age2_I{idxMA2I}.audio = x;
            idxMA2I = idxMA2I + 1;
        elseif ~isMale && isAge1
            HC_Female_Age1_I{idxFA1I}.audio = x;
            idxFA1I = idxFA1I + 1;
        elseif ~isMale && isAge2
            HC_Female_Age2_I{idxFA2I}.audio = x;
            idxFA2I = idxFA2I + 1;
        end

    end

end

%{
% Plot specific audio files
testAudio = ALS_Female_A{1}.audio; 
t = (0:length(testAudio)-1)/fs;

figure;
plot(t, testAudio);
xlabel('Time');
xlim([1,1.05]);
ylabel('Amplitude');
title('non-ALS A Male Waveform');
%}

%{
%% ===== DROP-IN: Plot a waveform from any subgroup =====
% Example: first file from (ALS, Male, Age1, vowel A)
group = ALS_Male_Age1_A;   % <-- change this to any subgroup cell array you made
vowelLabel = 'A';          % just for title
groupLabel = 'ALS Male Age1';  % just for title

fileIdx = 1;               % which file within that subgroup
startSec = 0;           % where to start plotting (seconds)
durSec   = 0.01;           % duration of plot window (seconds)

% --- Safety checks ---
if isempty(group)
    error('Selected group is empty. Check your subgroup indexing.');
end
if fileIdx > numel(group) || isempty(group{fileIdx}) || ~isfield(group{fileIdx}, 'audio')
    error('fileIdx invalid, or group{fileIdx} has no .audio field.');
end

x = group{fileIdx}.audio;
x = x(:);                  % ensure column
x = x - mean(x);

N = numel(x);
t = (0:N-1)/fs;

% Compute indices for the requested window
i1 = max(1, floor(startSec*fs) + 1);
i2 = min(N, i1 + floor(durSec*fs));

figure;
plot(t(i1:i2), x(i1:i2));
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title(sprintf('%s | Vowel %s | file #%d | window %.2f–%.2fs', ...
    groupLabel, vowelLabel, fileIdx, t(i1), t(i2)));
%}



%% ---- FIND FUNDEMENTAL PERIOD -------
% --- ALS ---
    % Age group 1 % 
[ALS_Male_A_out,   ALS_Male_A_cycleTS]   = findFundamentalPeriodGroup('ALS','Male','A', ALS_Male_Age1_A, ALS_Male_Age1_I, fs);
[ALS_Male_I_out,   ALS_Male_I_cycleTS]   = findFundamentalPeriodGroup('ALS','Male','I', ALS_Male_Age1_A, ALS_Male_Age1_I, fs);

[ALS_Female_A_out, ALS_Female_A_cycleTS] = findFundamentalPeriodGroup('ALS','Female','A', ALS_Female_Age1_A, ALS_Female_Age1_I, fs);
[ALS_Female_I_out, ALS_Female_I_cycleTS] = findFundamentalPeriodGroup('ALS','Female','I', ALS_Female_Age1_A, ALS_Female_Age1_I, fs);

    % Age group 2 % 
[ALS_Male_A_out,   ALS_Male_A_cycleTS]   = findFundamentalPeriodGroup('ALS','Male','A', ALS_Male_Age2_A, ALS_Male_Age2_I, fs);
[ALS_Male_I_out,   ALS_Male_I_cycleTS]   = findFundamentalPeriodGroup('ALS','Male','I', ALS_Male_Age2_A, ALS_Male_Age2_I, fs);

[ALS_Female_A_out, ALS_Female_A_cycleTS] = findFundamentalPeriodGroup('ALS','Female','A', ALS_Female_Age2_A, ALS_Female_Age2_I, fs);
[ALS_Female_I_out, ALS_Female_I_cycleTS] = findFundamentalPeriodGroup('ALS','Female','I', ALS_Female_Age2_A, ALS_Female_Age2_I, fs);

%HC_Male_Age1_A
% --- non-ALS (HC) ---
    % Age group 1 % 
[nonALS_Male_A_out,   nonALS_Male_A_cycleTS]   = findFundamentalPeriodGroup('nonALS','Male','A', HC_Male_Age1_A, HC_Male_Age1_I, fs);
[nonALS_Male_I_out,   nonALS_Male_I_cycleTS]   = findFundamentalPeriodGroup('nonALS','Male','I', ALS_Male_Age1_A, ALS_Male_Age1_I, fs);

[nonALS_Female_A_out, nonALS_Female_A_cycleTS] = findFundamentalPeriodGroup('nonALS','Female','A', HC_Female_Age1_A, HC_Female_Age1_I, fs);
[nonALS_Female_I_out, nonALS_Female_I_cycleTS] = findFundamentalPeriodGroup('nonALS','Female','I', HC_Female_Age1_A, HC_Female_Age1_I, fs);

    % Age group 2 % 
[nonALS_Male_A_out,   nonALS_Male_A_cycleTS]   = findFundamentalPeriodGroup('nonALS','Male','A', HC_Male_Age2_A, HC_Male_Age2_I, fs);
[nonALS_Male_I_out,   nonALS_Male_I_cycleTS]   = findFundamentalPeriodGroup('nonALS','Male','I', HC_Male_Age2_A, HC_Male_Age2_I, fs);

[nonALS_Female_A_out, nonALS_Female_A_cycleTS] = findFundamentalPeriodGroup('nonALS','Female','A', HC_Female_Age2_A, HC_Female_Age2_I, fs);
[nonALS_Female_I_out, nonALS_Female_I_cycleTS] = findFundamentalPeriodGroup('nonALS','Female','I', HC_Female_Age2_A, HC_Female_Age2_I, fs);


%% ---- FIND JITTER -------
% --- ALS --- 
    % Age group 1
[vector1] = findJitter('ALS','Male','A', ALS_Male_Age1_A, ALS_Male_Age1_I, fs, 0); 
[vector2] = findJitter('ALS','Male','I', ALS_Male_Age1_A, ALS_Male_Age1_I, fs, 0); 
[vector3] = findJitter('ALS','Female','A', ALS_Female_Age1_A, ALS_Female_Age1_I, fs, 0); 
[vector4] = findJitter('ALS','Female','I', ALS_Female_Age1_A, ALS_Female_Age1_I, fs, 0);
    % Age group 2
[vector5] = findJitter('ALS','Male','A', ALS_Male_Age2_A, ALS_Male_Age2_I, fs, 0); 
[vector6] = findJitter('ALS','Male','I', ALS_Male_Age2_A, ALS_Male_Age2_I, fs, 0); 
[vector7] = findJitter('ALS','Female','A', ALS_Female_Age2_A, ALS_Female_Age2_I, fs, 0); 
[vector8] = findJitter('ALS','Female','I', ALS_Female_Age2_A, ALS_Female_Age2_I, fs, 0);




% --- non-ALS (HC) --- 
    % Age group 1
[vector9] = findJitter('nonALS','Male','A', HC_Male_Age1_A, HC_Male_Age1_I, fs, 0);
[vector10] = findJitter('nonALS','Male','I', ALS_Male_Age1_A, ALS_Male_Age1_I, fs, 0); 
[vector11] = findJitter('nonALS','Female','A', HC_Female_Age1_A, HC_Female_Age1_I, fs, 1); 
[vector12] = findJitter('nonALS','Female','I', HC_Female_Age1_A, HC_Female_Age1_I, fs, 0);
    % Age group 2
[vector13] = findJitter('nonALS','Male','A', HC_Male_Age2_A, HC_Male_Age2_I, fs, 0); 
[vector14] = findJitter('nonALS','Male','I', ALS_Male_Age2_A, ALS_Male_Age2_I, fs, 0); 
[vector15] = findJitter('nonALS','Female','A', HC_Female_Age2_A, HC_Female_Age2_I, fs, 0); 
[vector16] = findJitter('nonALS','Female','I', HC_Female_Age2_A, HC_Female_Age2_I, fs, 0);



%% ---- FIND JITTER -------
% --- ALS ---
shimmer1  = findShimmer('ALS','Male','A', ALS_Male_Age1_A, ALS_Male_Age1_I, fs);
shimmer2  = findShimmer('ALS','Male','I', ALS_Male_Age1_A, ALS_Male_Age1_I, fs); 
shimmer3  = findShimmer('ALS','Female','A', ALS_Female_Age1_A, ALS_Female_Age1_I, fs); 
shimmer4  = findShimmer('ALS','Female','I', ALS_Female_Age1_A, ALS_Female_Age1_I, fs);

shimmer5  = findShimmer('ALS','Male','A', ALS_Male_Age2_A, ALS_Male_Age2_I, fs); 
shimmer6  = findShimmer('ALS','Male','I', ALS_Male_Age2_A, ALS_Male_Age2_I, fs); 
shimmer7  = findShimmer('ALS','Female','A', ALS_Female_Age2_A, ALS_Female_Age2_I, fs); 
shimmer8  = findShimmer('ALS','Female','I', ALS_Female_Age2_A, ALS_Female_Age2_I, fs);

% --- non-ALS ---
shimmer9  = findShimmer('nonALS','Male','A', HC_Male_Age1_A, HC_Male_Age1_I, fs); 
shimmer10 = findShimmer('nonALS','Male','I', HC_Male_Age1_A, HC_Male_Age1_I, fs); 
shimmer11 = findShimmer('nonALS','Female','A', HC_Female_Age1_A, HC_Female_Age1_I, fs); 
shimmer12 = findShimmer('nonALS','Female','I', HC_Female_Age1_A, HC_Female_Age1_I, fs);

shimmer13 = findShimmer('nonALS','Male','A', HC_Male_Age2_A, HC_Male_Age2_I, fs); 
shimmer14 = findShimmer('nonALS','Male','I', HC_Male_Age2_A, HC_Male_Age2_I, fs); 
shimmer15 = findShimmer('nonALS','Female','A', HC_Female_Age2_A, HC_Female_Age2_I, fs); 
shimmer16 = findShimmer('nonALS','Female','I', HC_Female_Age2_A, HC_Female_Age2_I, fs);

labels = {
    "ALS Male A, Group 1"
    "ALS Male I, Group 1"
    "ALS Female A, Group 1"
    "ALS Female I, Group 1"
    "ALS Male A, Group 2"
    "ALS Male I, Group 2"
    "ALS Female A, Group 2"
    "ALS Female I, Group 2"
    "non-ALS Male A, Group 1"
    "non-ALS Male I, Group 1"
    "non-ALS Female A, Group 1"
    "non-ALS Female I, Group 1"
    "non-ALS Male A, Group 2"
    "non-ALS Male I, Group 2"
    "non-ALS Female A, Group 2"
    "non-ALS Female I, Group 2"
};

vectors = {shimmer1, shimmer2, shimmer3, shimmer4, ...
           shimmer5, shimmer6, shimmer7, shimmer8, ...
           shimmer9, shimmer10, shimmer11, shimmer12, ...
           shimmer13, shimmer14, shimmer15, shimmer16};

fprintf('\n========== SHIMMER RESULTS ==========\n\n')

for k = 1:length(vectors)

    data_percent = 100 * vectors{k};

    mean_val = mean(data_percent,'omitnan');
    sd_val   = std(data_percent,'omitnan');

    fprintf('%s Shimmer: %.3f %% ± %.3f %%\n', ...
            labels{k}, mean_val, sd_val);
end

vectors = {vector1, vector2, vector3, vector4, ...
           vector5, vector6, vector7, vector8, vector9, ...
           vector10, vector11, vector12, vector13, vector14, vector15, vector16};

for k = 1:length(vectors)

    data_percent = 100 * vectors{k};

    mean_val = mean(data_percent,'omitnan');
    sd_val   = std(data_percent,'omitnan');

    fprintf('%s Jitter: %.3f %% ± %.3f %%\n', labels{k}, mean_val, sd_val);

end

%Keep here to plot Jitter values using
plotMeanHistogram(vector1, 'ALS Male A, Group 1', 'Jitter');
plotMeanHistogram(vector2, 'ALS Male I, Group 1', 'Jitter');
plotMeanHistogram(vector3, 'ALS Female A, Group 1', 'Jitter');
plotMeanHistogram(vector4, 'ALS Female I, Group 1', 'Jitter');
plotMeanHistogram(vector5, 'ALS Male A, Group 2', 'Jitter');
plotMeanHistogram(vector6, 'ALS Male I, Group 2', 'Jitter');
plotMeanHistogram(vector7, 'ALS Female A, Group 2', 'Jitter');
plotMeanHistogram(vector8, 'ALS Female I, Group 2', 'Jitter');

plotMeanHistogram(vector9, 'non-ALS Male A, Group 1', 'Jitter');
plotMeanHistogram(vector10, 'non-ALS Male I, Group 1', 'Jitter');
plotMeanHistogram(vector11, 'non-ALS Female A, Group 1', 'Jitter');
plotMeanHistogram(vector12, 'non-ALS Female I, Group 1', 'Jitter');
plotMeanHistogram(vector13, 'non-ALS Male A, Group 2', 'Jitter');
plotMeanHistogram(vector14, 'non-ALS Male I, Group 2', 'Jitter');
plotMeanHistogram(vector15, 'non-ALS Female A, Group 2', 'Jitter');
plotMeanHistogram(vector16, 'non-ALS Female I, Group 2', 'Jitter');

[vector1] = findPPQ5('ALS','Male','A', ALS_Male_A, ALS_Male_I, fs); 
[vector2] = findPPQ5('ALS','Male','I', ALS_Male_A, ALS_Male_I, fs);
[vector3] = findPPQ5('ALS','Female','A', ALS_Female_A, ALS_Female_I, fs); 
[vector4] = findPPQ5('ALS','Female','I', ALS_Female_A, ALS_Female_I, fs);
% --- non-ALS (HC) --- 
[vector5] = findPPQ5('nonALS','Male','A', HC_Male_A, HC_Male_I, fs);
[vector6] = findPPQ5('nonALS','Male','I', HC_Male_A, HC_Male_I, fs);
[vector7] = findPPQ5('nonALS','Female','A', HC_Female_A, HC_Female_I, fs); 
[vector8] = findPPQ5('nonALS','Female','I', HC_Female_A, HC_Female_I, fs);

[vector9] = findPPQ5('ALS','Male','I', ALS_Male_Age1_A, ALS_Male_Age1_I, fs);

%% ---- PPQ5 (Percent + SD) ----

labels = {
    "ALS Male A"
    "ALS Male I"
    "ALS Female A"
    "ALS Female I"
    "non-ALS Male A"
    "non-ALS Male I"
    "non-ALS Female A"
    "non-ALS Female I"
    "ALS Male Age1 I"
};

vectors = {vector1, vector2, vector3, vector4, ...
           vector5, vector6, vector7, vector8, vector9};

for k = 1:length(vectors)

    data_percent = 100 * vectors{k};

    mean_val = mean(data_percent,'omitnan');
    sd_val   = std(data_percent,'omitnan');

    fprintf('%s PPQ5: %.3f %% ± %.3f %%\n', labels{k}, mean_val, sd_val);

end



%{
%Call bandpass filter and plot the new
%waveform
[~, t0Test] = findFundamentalPeriodSingle(ALS_Female_A{1}.audio, fs);
testBandPass = bandpassAroundF0(ALS_Female_A{1}.audio, fs, t0Test); 

t_test = (0:length(testBandPass)-1)/fs;
t_noFilter = (0:length(ALS_Female_A{1}.audio)-1)/fs;



figure;
plot(t_test, testBandPass);
xlabel('Time');
xlim([0,0.1])
ylabel('Amplitude');
title('Bandpass filtered waveform');

figure;
plot(t_noFilter, ALS_Female_A{1}.audio);
xlabel('Time');
xlim([0,0.1])
ylabel('Amplitude');
title('NoBandpass filtered waveform');
%}



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
%   statusStr: 'ALS' or 'HC'
%   sexStr:    'Male' or 'Female'
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
            lags = lags(frameLen:end);

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
        tSamp = 0;                      % first timestamp is 0 seconds
        ts_samples = 44100;             % sample index of current "start" (1-based)
       
        ts_list = 0;                    % timestamps in seconds (row vector), starts with 0

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

            ts_samples = ts_samples + bestLag2;     % "get rid of" data before this
            if ts_samples > N
                break;
            end

            tSamp = (ts_samples - 1) / fs;          % convert sample index to seconds
            ts_list(end+1) = tSamp; %#ok<AGROW>

            % safety stop if we're too close to the end to measure another period
            if (ts_samples + lagMax) > N
                break;
            end
        end

        cycleTimestamps{n} = ts_list;
        % <<<

    end

    % Average across group
    avgF0_acf = mean(f0_all_acf,'omitnan');
    fprintf('%s Average F0 (ACF): %.2f Hz\n', label, avgF0_acf);

    % Store outputs in a structured way
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



%% ------------ FUNCTION: Bandpass Around Fundamental ------------
function x_bp = bandpassAroundF0(x, fs, avgPeriod)

% Convert period to frequency
f0 = 1 / avgPeriod;

% Safety check
if isnan(f0) || f0 <= 0
    x_bp = x;
    return
end

% Define bandwidth (±30% of F0 is a good starting point)
bw = 0.3 * f0;

fLow  = max(50,  f0 - bw);        % avoid going too low
fHigh = min(fs/2 - 100, f0 + bw); % avoid Nyquist

% Design 4th-order Butterworth bandpass
[b,a] = butter(4, [fLow fHigh] / (fs/2), 'bandpass');

% Zero-phase filtering (important for jitter work)
x_bp = filtfilt(b, a, x);

end

function [F0, T0] = findFundamentalPeriodSingle(x, fs)
% findFundamentalPeriodSingle
% Input:
%   x  - audio vector (single file)
%   fs - sampling rate
%
% Outputs:
%   F0 - estimated fundamental frequency (Hz)
%   T0 - estimated fundamental period (seconds)

% Remove DC
x = x - mean(x);

% ---- Settings ----
frameDur = 0.040;   % 40 ms
hopDur   = 0.010;   % 10 ms
frameLen = round(frameDur*fs);
hopLen   = round(hopDur*fs);

f0Min = 60;
f0Max = 400;

lagMin = round(fs/f0Max);
lagMax = round(fs/f0Min);

N = length(x);
numFrames = floor((N - frameLen)/hopLen) + 1;

f0_frames = NaN(numFrames,1);

for m = 1:numFrames
    idx1 = (m-1)*hopLen + 1;
    idx2 = idx1 + frameLen - 1;

    frame = x(idx1:idx2);
    frame = frame - mean(frame);

    [r,~] = xcorr(frame, frame);
    r = r(frameLen:end);
    r = r / (r(1) + eps);

    search = r(lagMin:lagMax);
    [pk, idxPk] = max(search);
    bestLag = lagMin + idxPk - 1;

    if pk > 0.3
        f0_frames(m) = fs / bestLag;
    else
        f0_frames(m) = NaN;
    end
end

% Robust estimate using median
if all(isnan(f0_frames))
    F0 = NaN;
    T0 = NaN;
else
    F0 = median(f0_frames,'omitnan');
    T0 = 1 / F0;
end

end

function plotMeanHistogram(dataVector, groupName, metricName)

% dataVector  -> vector of jitter or PPQ5 values (fractional form)
% groupName   -> string (e.g., 'ALS Male A')
% metricName  -> string (e.g., 'Jitter' or 'PPQ5')

% Remove NaNs
dataVector = dataVector(~isnan(dataVector));

% Convert to percent
dataPercent = 100 * dataVector;

% Compute statistics
meanVal = mean(dataPercent);
sdVal   = std(dataPercent);

% Plot histogram
figure;
histogram(dataPercent, 20, 'Normalization', 'probability');
hold on;

xlabel([metricName ' (%)']);
ylabel('Percent of Group');
title([groupName ' - ' metricName ' Distribution']);

legend('Distribution', ...
       sprintf('Mean = %.3f%% ± %.3f%%', meanVal, sdVal));

grid on;

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

    % Local shimmer formula
    numerator = (1/(N-1)) * sum(abs(diff(A)));
    denominator = (1/N) * sum(A);

    localShimmer(i) = numerator / denominator;

end

end

function playWavFile(filename)
% playWavFile
% Input:
%   filename - string containing path to .wav file
%
% Example:
%   playWavFile('sample.wav')

    % Check file exists
    if ~isfile(filename)
        error('File does not exist.');
    end

    % Read audio
    [x, fs] = audioread(filename);

    % If stereo, convert to mono (optional)
    if size(x,2) > 1
        x = mean(x,2);
    end

    % Normalize to avoid clipping
    x = x ./ max(abs(x) + eps);

    % Play audio
    sound(x, fs);

end