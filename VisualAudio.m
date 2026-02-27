%% ================================================================
%  Minsk2020 Audio Inspector (BRAND NEW SCRIPT)
%  ------------------------------------------------
%  What it does:
%   1) Reads ALL wav files from your ALS + HC folders (recursive)
%   2) Recreates your subgroup cell arrays (ALS/HC, Male/Female, Age1/Age2, A/I)
%   3) Interactive selector:
%        - You can filter by ANY subset (e.g., only Sex=Male and Status=nonALS)
%        - You do NOT have to pick something from every category (choose "All")
%   4) Pick a file -> choose a time window -> view waveform
%
%  What it does NOT do (yet):
%   - No audio playback
%   - No jitter/shimmer/PPQ5 calling
%
%  Requirements:
%   - Folder structure and filenames consistent with your current setup
%   - Uses your same hard-coded subject index lists for male + age groups
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

% Sort by filename for deterministic ordering (matches your "k/2 subject" logic best)
[~, ia] = sort({filesAls.name}); filesAls = filesAls(ia);
[~, ih] = sort({filesHC.name});  filesHC  = filesHC(ih);

%% ----------- Subject index lists (from your code) ----
ALS_maleIdx = [1, 5:12, 16:20, 22:25, 29, 30];
HC_maleIdx  = [3:10, 13, 21, 26, 29, 30];

ALS_ageIdx1 = [2:3, 6:8, 13, 17:20, 25:28, 31];
ALS_ageIdx2 = [1, 4:5, 9:12, 14:16, 21:24, 29:30];

HC_ageIdx1  = [2:4, 6:7, 9, 11:14, 16, 18:20, 22, 25:26, 29];
HC_ageIdx2  = [1, 5, 8, 10, 15, 17, 21, 27:28, 30:33];

%% ----------- Initialize subgroup cell arrays ----------
% ALS
ALS_Male_Age1_A   = {}; ALS_Male_Age1_I   = {};
ALS_Male_Age2_A   = {}; ALS_Male_Age2_I   = {};
ALS_Female_Age1_A = {}; ALS_Female_Age1_I = {};
ALS_Female_Age2_A = {}; ALS_Female_Age2_I = {};

% nonALS (HC)
HC_Male_Age1_A    = {}; HC_Male_Age1_I    = {};
HC_Male_Age2_A    = {}; HC_Male_Age2_I    = {};
HC_Female_Age1_A  = {}; HC_Female_Age1_I  = {};
HC_Female_Age2_A  = {}; HC_Female_Age2_I  = {};

%% ----------- Build ALS groups ----------
idx = struct();
idx.ALS_Male_Age1_A=1; idx.ALS_Male_Age1_I=1; idx.ALS_Male_Age2_A=1; idx.ALS_Male_Age2_I=1;
idx.ALS_Female_Age1_A=1; idx.ALS_Female_Age1_I=1; idx.ALS_Female_Age2_A=1; idx.ALS_Female_Age2_I=1;

for k = 1:numel(filesAls)
    fullpath = fullfile(filesAls(k).folder, filesAls(k).name);
    [x, fs_k] = audioread(fullpath);
    if size(x,2) > 1, x = mean(x,2); end
    x = x - mean(x);

    subj  = ceil(k/2);
    if mod(k,2)==1, vowel='A'; else, vowel='I'; end

    isMale = ismember(subj, ALS_maleIdx);
    isAge1 = ismember(subj, ALS_ageIdx1);
    isAge2 = ismember(subj, ALS_ageIdx2);

    item.audio   = x;
    item.fs      = fs_k;
    item.file    = filesAls(k).name;
    item.folder  = filesAls(k).folder;
    item.fullpath= fullpath;
    item.status  = 'ALS';
    item.subject = subj;
    if isMale, item.sex='Male'; else, item.sex='Female'; end
    if isAge1, item.agegrp='Age1'; elseif isAge2, item.agegrp='Age2'; else, item.agegrp='(unassigned)'; end
    item.vowel   = vowel;

    if isMale && isAge1 && vowel=='A'
        ALS_Male_Age1_A{idx.ALS_Male_Age1_A} = item; idx.ALS_Male_Age1_A = idx.ALS_Male_Age1_A + 1;
    elseif isMale && isAge1 && vowel=='I'
        ALS_Male_Age1_I{idx.ALS_Male_Age1_I} = item; idx.ALS_Male_Age1_I = idx.ALS_Male_Age1_I + 1;
    elseif isMale && isAge2 && vowel=='A'
        ALS_Male_Age2_A{idx.ALS_Male_Age2_A} = item; idx.ALS_Male_Age2_A = idx.ALS_Male_Age2_A + 1;
    elseif isMale && isAge2 && vowel=='I'
        ALS_Male_Age2_I{idx.ALS_Male_Age2_I} = item; idx.ALS_Male_Age2_I = idx.ALS_Male_Age2_I + 1;
    elseif ~isMale && isAge1 && vowel=='A'
        ALS_Female_Age1_A{idx.ALS_Female_Age1_A} = item; idx.ALS_Female_Age1_A = idx.ALS_Female_Age1_A + 1;
    elseif ~isMale && isAge1 && vowel=='I'
        ALS_Female_Age1_I{idx.ALS_Female_Age1_I} = item; idx.ALS_Female_Age1_I = idx.ALS_Female_Age1_I + 1;
    elseif ~isMale && isAge2 && vowel=='A'
        ALS_Female_Age2_A{idx.ALS_Female_Age2_A} = item; idx.ALS_Female_Age2_A = idx.ALS_Female_Age2_A + 1;
    elseif ~isMale && isAge2 && vowel=='I'
        ALS_Female_Age2_I{idx.ALS_Female_Age2_I} = item; idx.ALS_Female_Age2_I = idx.ALS_Female_Age2_I + 1;
    end
end

%% ----------- Build nonALS (HC) groups ----------
idx = struct();
idx.HC_Male_Age1_A=1; idx.HC_Male_Age1_I=1; idx.HC_Male_Age2_A=1; idx.HC_Male_Age2_I=1;
idx.HC_Female_Age1_A=1; idx.HC_Female_Age1_I=1; idx.HC_Female_Age2_A=1; idx.HC_Female_Age2_I=1;

for k = 1:numel(filesHC)
    fullpath = fullfile(filesHC(k).folder, filesHC(k).name);
    [x, fs_k] = audioread(fullpath);
    if size(x,2) > 1, x = mean(x,2); end
    x = x - mean(x);

    subj  = ceil(k/2);
    if mod(k,2)==1, vowel='A'; else, vowel='I'; end

    isMale = ismember(subj, HC_maleIdx);
    isAge1 = ismember(subj, HC_ageIdx1);
    isAge2 = ismember(subj, HC_ageIdx2);

    item.audio   = x;
    item.fs      = fs_k;
    item.file    = filesHC(k).name;
    item.folder  = filesHC(k).folder;
    item.fullpath= fullpath;
    item.status  = 'nonALS';
    item.subject = subj;
    if isMale, item.sex='Male'; else, item.sex='Female'; end
    if isAge1, item.agegrp='Age1'; elseif isAge2, item.agegrp='Age2'; else, item.agegrp='(unassigned)'; end
    item.vowel   = vowel;

    if isMale && isAge1 && vowel=='A'
        HC_Male_Age1_A{idx.HC_Male_Age1_A} = item; idx.HC_Male_Age1_A = idx.HC_Male_Age1_A + 1;
    elseif isMale && isAge1 && vowel=='I'
        HC_Male_Age1_I{idx.HC_Male_Age1_I} = item; idx.HC_Male_Age1_I = idx.HC_Male_Age1_I + 1;
    elseif isMale && isAge2 && vowel=='A'
        HC_Male_Age2_A{idx.HC_Male_Age2_A} = item; idx.HC_Male_Age2_A = idx.HC_Male_Age2_A + 1;
    elseif isMale && isAge2 && vowel=='I'
        HC_Male_Age2_I{idx.HC_Male_Age2_I} = item; idx.HC_Male_Age2_I = idx.HC_Male_Age2_I + 1;
    elseif ~isMale && isAge1 && vowel=='A'
        HC_Female_Age1_A{idx.HC_Female_Age1_A} = item; idx.HC_Female_Age1_A = idx.HC_Female_Age1_A + 1;
    elseif ~isMale && isAge1 && vowel=='I'
        HC_Female_Age1_I{idx.HC_Female_Age1_I} = item; idx.HC_Female_Age1_I = idx.HC_Female_Age1_I + 1;
    elseif ~isMale && isAge2 && vowel=='A'
        HC_Female_Age2_A{idx.HC_Female_Age2_A} = item; idx.HC_Female_Age2_A = idx.HC_Female_Age2_A + 1;
    elseif ~isMale && isAge2 && vowel=='I'
        HC_Female_Age2_I{idx.HC_Female_Age2_I} = item; idx.HC_Female_Age2_I = idx.HC_Female_Age2_I + 1;
    end
end

%% ----------- Make unified catalog ----------
groupNames = { ...
    'ALS_Male_Age1_A','ALS_Male_Age1_I','ALS_Male_Age2_A','ALS_Male_Age2_I', ...
    'ALS_Female_Age1_A','ALS_Female_Age1_I','ALS_Female_Age2_A','ALS_Female_Age2_I', ...
    'HC_Male_Age1_A','HC_Male_Age1_I','HC_Male_Age2_A','HC_Male_Age2_I', ...
    'HC_Female_Age1_A','HC_Female_Age1_I','HC_Female_Age2_A','HC_Female_Age2_I' ...
};

catalog = {};
for gi = 1:numel(groupNames)
    g = eval(groupNames{gi});  % cell array of structs
    for j = 1:numel(g)
        if isempty(g{j}), continue; end
        tmp = g{j};
        tmp.groupVar = groupNames{gi};
        catalog{end+1} = tmp; %#ok<SAGROW>
    end
end

if isempty(catalog)
    error('Catalog is empty. Check file ordering and index lists.');
end

%% ================================================================
%  INTERACTIVE BROWSER (NO AUDIO PLAYBACK)
%% ================================================================
defaultStartSec = 1.00;
defaultDurSec   = 0.05;

keepGoing = true;
while keepGoing

    % Filters: choose "All" to skip any category
    statusChoice = listdlg('PromptString','Filter: Status','SelectionMode','single', ...
        'ListString',{'All','ALS','nonALS'}, 'ListSize',[250 120]);
    if isempty(statusChoice), break; end
    statusStr = {'All','ALS','nonALS'}; statusStr = statusStr{statusChoice};

    sexChoice = listdlg('PromptString','Filter: Sex','SelectionMode','single', ...
        'ListString',{'All','Male','Female'}, 'ListSize',[250 120]);
    if isempty(sexChoice), break; end
    sexStr = {'All','Male','Female'}; sexStr = sexStr{sexChoice};

    ageChoice = listdlg('PromptString','Filter: Age Group','SelectionMode','single', ...
        'ListString',{'All','Age1','Age2'}, 'ListSize',[250 120]);
    if isempty(ageChoice), break; end
    ageStr = {'All','Age1','Age2'}; ageStr = ageStr{ageChoice};

    vowelChoice = listdlg('PromptString','Filter: Vowel','SelectionMode','single', ...
        'ListString',{'All','A','I'}, 'ListSize',[250 120]);
    if isempty(vowelChoice), break; end
    vowelStr = {'All','A','I'}; vowelStr = vowelStr{vowelChoice};

    % Apply filters
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
        uiwait(warndlg('No files match those filters. Try again.','No matches'));
        continue;
    end

    % File picker
    listStr = cell(numel(filtered),1);
    for i = 1:numel(filtered)
        it = filtered{i};
        dur = numel(it.audio)/it.fs;
        listStr{i} = sprintf('%03d) %s | subj %d | %s %s %s %s | %.2fs', ...
            i, it.file, it.subject, it.status, it.sex, it.agegrp, it.vowel, dur);
    end

    fileChoice = listdlg('PromptString',sprintf('Select a file to view (%d matches)', numel(filtered)), ...
        'SelectionMode','single', 'ListString',listStr, 'ListSize',[780 420]);
    if isempty(fileChoice), continue; end

    currentIdx = fileChoice;

    % Viewing loop within this filtered set
    inFileLoop = true;
    while inFileLoop
        it = filtered{currentIdx};
        x  = it.audio(:);
        fs = it.fs;
        t  = (0:numel(x)-1)/fs;
        totalDur = t(end);

        prompt = {'Start time (sec):','Window duration (sec):'};
        def    = {num2str(defaultStartSec), num2str(defaultDurSec)};
        answ = inputdlg(prompt, 'Time Window', [1 40], def);
        if isempty(answ), break; end

        startSec = str2double(answ{1});
        durSec   = str2double(answ{2});
        if isnan(startSec) || isnan(durSec) || durSec <= 0
            uiwait(warndlg('Invalid start/duration. Try again.','Bad input'));
            continue;
        end

        startSec = max(0, startSec);
        endSec   = min(totalDur, startSec + durSec);

        i1 = max(1, floor(startSec*fs)+1);
        i2 = min(numel(x), floor(endSec*fs)+1);

        defaultStartSec = startSec;
        defaultDurSec   = durSec;

        % Plot window
        figure(1); clf;
        plot(t(i1:i2), x(i1:i2));
        grid on;
        xlabel('Time (s)');
        ylabel('Amplitude');
        title(sprintf('%s | %s %s %s %s | subj %d | window %.3f–%.3fs', ...
            it.file, it.status, it.sex, it.agegrp, it.vowel, it.subject, t(i1), t(i2)));

        % Navigation (no audio options)
        nav = questdlg( ...
            sprintf('File %d of %d (filtered set). What next?', currentIdx, numel(filtered)), ...
            'Navigation', ...
            'Prev','Next','Change filters','Next');

        if isempty(nav)
            inFileLoop = false;
        else
            switch nav
                case 'Prev'
                    currentIdx = currentIdx - 1;
                    if currentIdx < 1, currentIdx = numel(filtered); end
                case 'Next'
                    currentIdx = currentIdx + 1;
                    if currentIdx > numel(filtered), currentIdx = 1; end
                case 'Change filters'
                    inFileLoop = false;
            end
        end
    end

    keepGoing = strcmp(questdlg('Continue browsing?', 'Continue', 'Yes','No','Yes'), 'Yes');
end

disp('Done.');