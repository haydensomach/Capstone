% ============================
% JITTER ANALYSIS SCRIPT
% ============================

clear; clc; close all;

%% ----------- Paths ----------------
audioDirAls = '/Users/hayden/Documents/Minsk2020_ALS_database/ALS';
audioDirHC  = '/Users/hayden/Documents/Minsk2020_ALS_database/HC';

filesAls = dir(fullfile(audioDirAls,'**','*.wav'));
filesHC  = dir(fullfile(audioDirHC,'**','*.wav'));

% Get sampling rate
[~,fs] = audioread(fullfile(filesHC(1).folder,filesHC(1).name));

%% ----------- Subject Index Lists ----------------
ALS_maleIdx = [1 5:12 16:20 22:25 29 30];
HC_maleIdx  = [3:10 13 21 26 29 30];

ALS_ageIdx1 = [2:3 6:8 13 17:20 25:28 31];
ALS_ageIdx2 = [1 4:5 9:12 14:16 21:24 29:30];

HC_ageIdx1  = [2:4 6:7 9 11:14 16 18:20 22 25:26 29];
HC_ageIdx2  = [1 5 8 10 15 17 21 27:28 30:33];

%% ----------- Initialize Containers ----------------

groups = struct();

names = { ...
    'ALS_Male_Age1_A','ALS_Male_Age1_I', ...
    'ALS_Male_Age2_A','ALS_Male_Age2_I', ...
    'ALS_Female_Age1_A','ALS_Female_Age1_I', ...
    'ALS_Female_Age2_A','ALS_Female_Age2_I', ...
    'HC_Male_Age1_A','HC_Male_Age1_I', ...
    'HC_Male_Age2_A','HC_Male_Age2_I', ...
    'HC_Female_Age1_A','HC_Female_Age1_I', ...
    'HC_Female_Age2_A','HC_Female_Age2_I' };

for i = 1:numel(names)
    groups.(names{i}) = {};
end


%% ----------- Function: Process Group ----------------

processGroup = @(files,maleIdx,age1Idx,age2Idx,prefix) ...
    processAudio(files,maleIdx,age1Idx,age2Idx,prefix,groups);


%% ----------- Process ALS ----------------
groups = processAudio( ...
    filesAls, ...
    ALS_maleIdx, ...
    ALS_ageIdx1, ...
    ALS_ageIdx2, ...
    'ALS', ...
    groups);


%% ----------- Process HC ----------------
groups = processAudio( ...
    filesHC, ...
    HC_maleIdx, ...
    HC_ageIdx1, ...
    HC_ageIdx2, ...
    'HC', ...
    groups);


%% ----------- Compute Jitter ----------------

Jitter      = struct();
JitterStats = struct();

groupKeys = fieldnames(groups);

for i = 1:numel(groupKeys)

    key  = groupKeys{i};
    data = groups.(key);

    if isempty(data)
        Jitter.(key) = [];
        continue
    end

    % Determine labels
    if contains(key,'ALS')
        status = 'ALS';
    else
        status = 'nonALS';
    end

    if contains(key,'Male')
        sex = 'Male';
    else
        sex = 'Female';
    end

    if contains(key,'_A')
        vowel = 'A';
    else
        vowel = 'I';
    end

    v = findJitterGroup(status,sex,vowel,data,[],fs,0);

    Jitter.(key) = v;

    vPct = 100*v;

    JitterStats.(key).mean_pct = mean(vPct,'omitnan');
    JitterStats.(key).sd_pct   = std(vPct,'omitnan');
    JitterStats.(key).N_valid  = sum(~isnan(v));

end


%% ----------- Print Full Vectors ----------------

fprintf('\n========== FULL JITTER VECTORS (PERCENT) ==========\n\n');

keys = fieldnames(Jitter);

for i = 1:numel(keys)

    k = keys{i};
    v = 100*Jitter.(k);

    fprintf('%s:\n',k);

    if isempty(v)
        fprintf('  [empty]\n\n');
        continue
    end

    fprintf('  [');
    fprintf(' %.6f',v);
    fprintf(' ]\n\n');

end


%% ----------- Print Statistics ----------------

fprintf('\n========== JITTER RESULTS ==========\n\n');

statKeys = fieldnames(JitterStats);

for i = 1:numel(statKeys)

    k = statKeys{i};

    fprintf('%s Jitter: %.3f %% ± %.3f %%  (N=%d)\n', ...
        k, ...
        JitterStats.(k).mean_pct, ...
        JitterStats.(k).sd_pct, ...
        JitterStats.(k).N_valid);

end



%% ======================================================
%%                HELPER FUNCTION
%% ======================================================

function groups = processAudio(files,maleIdx,age1Idx,age2Idx,prefix,groups)

idx = struct();

for k = 1:length(files)

    [x,~] = audioread(fullfile(files(k).folder,files(k).name));

    if size(x,2)>1
        x = mean(x,2);
    end

    subj   = ceil(k/2);

    isMale = ismember(subj,maleIdx);
    isAge1 = ismember(subj,age1Idx);
    isAge2 = ismember(subj,age2Idx);

    isA = mod(k,2)==1;

    % Labels
    if isMale
        sex = 'Male';
    else
        sex = 'Female';
    end

    if isAge1
        age = 'Age1';
    else
        age = 'Age2';
    end

    if isA
        vowel = 'A';
    else
        vowel = 'I';
    end

    key = sprintf('%s_%s_%s_%s',prefix,sex,age,vowel);

    if ~isfield(idx,key)
        idx.(key)=1;
    end

    groups.(key){idx.(key)}.audio = x;

    idx.(key) = idx.(key)+1;

end

end