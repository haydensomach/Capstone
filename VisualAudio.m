%% ================================================================
%  Minsk2020 Audio Inspector (BRAND NEW SCRIPT)
%  ------------------------------------------------
%  Behavior:
%   - Filter (optional) by Status/Sex/Age/Vowel ("All" = no filter)
%   - Select ONE file
%   - Enter start time + window duration
%   - Plot that window
%   - SCRIPT ENDS (no next/prev prompting)
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

    item.audio   = x;
    item.fs      = fs;
    item.file    = filesAls(k).name;
    item.folder  = filesAls(k).folder;
    item.fullpath= fullpath;
    item.status  = 'ALS';
    item.subject = subj;
    if isMale, item.sex='Male'; else, item.sex='Female'; end
    if isAge1, item.agegrp='Age1'; elseif isAge2, item.agegrp='Age2'; else, item.agegrp='(unassigned)'; end
    item.vowel   = vowel;

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

    item.audio   = x;
    item.fs      = fs;
    item.file    = filesHC(k).name;
    item.folder  = filesHC(k).folder;
    item.fullpath= fullpath;
    item.status  = 'nonALS';
    item.subject = subj;
    if isMale, item.sex='Male'; else, item.sex='Female'; end
    if isAge1, item.agegrp='Age1'; elseif isAge2, item.agegrp='Age2'; else, item.agegrp='(unassigned)'; end
    item.vowel   = vowel;

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

%% ----------- PLOT AND END ----------
figure;
plot(t(i1:i2), x(i1:i2));
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title(sprintf('%s | %s %s %s %s | subj %d | window %.3f–%.3fs', ...
    it.file, it.status, it.sex, it.agegrp, it.vowel, it.subject, t(i1), t(i2)));