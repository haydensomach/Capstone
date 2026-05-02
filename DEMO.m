%ChatGPT helped format this code

% The function of this script is to act as a live demo and compute vocal metrics
% With real-time audio input

% Input: audio from a person
% Output: all four vocal metrics are printed on the command line; four plots
% Related to each metric are also displayed.

clear; clc; close all;

fs        = 44100;     % Set samples per second
nBits     = 16;        % Audio bit depth
nChannels = 1;         % Mono
recTime   = 5;         % Seconds

% Output filename
outFolder = fullfile(pwd, 'recorded_audio');
if ~isfolder(outFolder)
    mkdir(outFolder);
end

timestamp = datestr(now, 'yyyy_mm_dd_HH_MM_SS');
outFile   = fullfile(outFolder, ['voiceDemo_' timestamp '.wav']);

% Print countdown
fprintf('Get ready to speak.\n');
for k = 3:-1:1
    fprintf('%d...\n', k);
    pause(1);
end
fprintf('Start speaking now.\n');

% Record the audio
recObj = audiorecorder(fs, nBits, nChannels);
recordblocking(recObj, recTime);
fprintf('Recording complete.\n');

% Save audio
audioData = getaudiodata(recObj);
audiowrite(outFile, audioData, fs);

fprintf('Saved 5 second audio file to:\n%s\n', outFile);

% Call function to full analysis to create metrics
results = analyzeVoiceMetrics(outFile);

% Display the metrics
if isempty(results)
    error('No results were returned.');
end

fprintf('\n===== Voice Metrics =====\n');
fprintf('File: %s\n', results(1).fileName);
fprintf('Full Path: %s\n', results(1).fullPath);
fprintf('Original Sample Rate (Hz): %.0f\n', results(1).fs_Hz);
fprintf('Duration (s): %.3f\n', results(1).duration_s);
fprintf('F0 (Hz): %.3f\n', results(1).F0_Hz);
fprintf('Jitter (%%): %.3f\n', results(1).jitter_percent);
fprintf('Shimmer (%%): %.3f\n', results(1).shimmer_percent);
fprintf('HNR (dB): %.3f\n', results(1).HNR_dB);
fprintf('PSD Jitter (%%): %.3f\n', results(1).PSD_jitter_percent);
fprintf('Periods Used: %.0f\n', results(1).nPeriodsUsed);
fprintf('Amplitudes Used: %.0f\n', results(1).nAmplitudesUsed);
fprintf('Seconds Used: %.0f\n', results(1).nSecondsUsed);

% Plotting
r = results(1);

x  = r.waveforms;
fs = r.fs_proc_Hz;
t  = (0:numel(x)-1) / fs;

% Necessary to rebuild the markers for the audio file to mark 
% Periods and peak to peak amplitudes
ts_samp_abs = r.timeStamps;
numPeriods  = length(ts_samp_abs) - 1;

Mi = NaN(numPeriods, 1);
mi = NaN(numPeriods, 1);

for k = 1:numPeriods
    idx1 = ts_samp_abs(k);
    idx2 = ts_samp_abs(k+1) - 1;

    if idx2 > length(x)
        idx2 = length(x);
    end
    if idx1 < 1 || idx1 >= idx2
        continue;
    end

    %Find the maxima
    seg = x(idx1:idx2);
    [pksMax, locsMax] = findpeaks(seg);

    if isempty(pksMax)
        idx1b = max(1, idx1-5);
        idx2b = min(length(x), idx2+5);
        seg   = x(idx1b:idx2b);
        [pksMax, locsMax] = findpeaks(seg);
        idxStartMax = idx1b;
    else
        idxStartMax = idx1;
    end

    if ~isempty(pksMax)
        [~, iMax] = max(pksMax);
        Mi(k) = idxStartMax + locsMax(iMax) - 1;
    end

    %Find the minima
    idx1m = ts_samp_abs(k);
    idx2m = min(ts_samp_abs(k+1)-1, length(x));
    seg2  = x(idx1m:idx2m);
    [pksMin, locsMin] = findpeaks(-seg2);

    if isempty(pksMin)
        idx1b = max(1, idx1m-5);
        idx2b = min(length(x), idx2m+5);
        seg2  = x(idx1b:idx2b);
        [pksMin, locsMin] = findpeaks(-seg2);
        idxStartMin = idx1b;
    else
        idxStartMin = idx1m;
    end

    if ~isempty(pksMin)
        [~, iMin] = max(pksMin);
        mi(k) = idxStartMin + locsMin(iMin) - 1;
    end
end

% Display markers on a subsection of the wave form
figure('Name', 'Waveform with Peak Markers');
plot(t, x, 'LineWidth', 1.0);
hold on;
grid on;
xlim([1,1.05])
xlabel('Time (s)');
ylabel('Amplitude');
title('Waveform');

idxMax = Mi(~isnan(Mi));
idxMin = mi(~isnan(mi));

plot(t(idxMax), x(idxMax), 'ro', 'MarkerSize', 8);
plot(t(idxMin), x(idxMin), 'bo', 'MarkerSize', 8);
plot(t(idxMax), x(idxMax), 'r-', 'LineWidth', 1.2);
plot(t(idxMin), x(idxMin), 'b-', 'LineWidth', 1.2);

hold off;

% Power contribution plot
PC_mat = r.PC_mat_raw;
if ~isempty(PC_mat) && isfinite(r.F0_Hz) && r.F0_Hz > 0
    harmonics_Hz = r.F0_Hz : r.F0_Hz : (r.F0_Hz * size(PC_mat,2));

    figure('Name', sprintf('Harmonic Power Contribution: %s', r.fileName));
    hold on;

    legText = strings(size(PC_mat,1),1);

    for s = 1:size(PC_mat,1)
        plot(harmonics_Hz, 100*PC_mat(s,:), 'o-', 'LineWidth', 1.5);
        legText(s) = sprintf('Second %d', s);
    end

    xlabel('Frequency (Hz)');
    ylabel('Power Contribution (%)');
    title('Harmonic Power');
    legend(legText, 'Location', 'best');
    grid on;
    hold off;
end

% HNR Plotting
if ~isempty(r.hnr_f_Hz) && ~isempty(r.hnr_psd)
    figure('Name', 'Welch PSD + Harmonic Bands');

    fPlot = r.hnr_f_Hz(:);
    yPlot = 10*log10(r.hnr_psd(:));

    hold on;
    grid on;

    % Plot full PSD in background
    plot(fPlot, yPlot, 'k', 'LineWidth', 1.0);

    % Overlay each harmonic band as its own colored segment
    for k = 1:numel(r.hnr_bandLeft_Hz)
        if ~isfinite(r.hnr_bandLeft_Hz(k)) || ~isfinite(r.hnr_bandRight_Hz(k))
            continue;
        end

        idxBand = (fPlot >= r.hnr_bandLeft_Hz(k)) & (fPlot <= r.hnr_bandRight_Hz(k));

        if any(idxBand)
            plot(fPlot(idxBand), yPlot(idxBand), 'r', 'LineWidth', 2.0);
        end
    end

    xlim([0 600]);
    xlabel('Frequency (Hz)');
    ylabel('Power/Frequency (dB/Hz)');
    title('Harmonic Power');
    hold off;
end



