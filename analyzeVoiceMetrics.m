function results = analyzeVoiceMetrics(filepath)
% ChatGPT used for formatting the code.

% The function of this script is to do the computation 
% For the four metrics (jitter, shimmer, HNR, and per second harmonic contribution)

% Input: a file path to a folder/single file of .wave file/s
% Output: a struct of results that has the metric information
wavFiles = getWavFiles_local(filepath);
nFiles   = numel(wavFiles);

if nFiles == 0
    error('No .wav files found at the provided path.');
end

% Varies parameters that can effect the metric outputs
L         = 3;        % Upsample factor
frameDur  = 0.040;    % Duration of autocorrelation frame to detect consecutive periods
f0Min     = 60;       % Minimum F0 (Hz) - Lower bound for autocorrelation peak detection.
f0Max     = 400;      % Maximum F0 (Hz) - Upper bound for autocorrelation peak detection.
bandWidth = 100;      % Initialize harmonic search window (Hz) for HNR.
maxFreq   = 2000;     % Highest frequency for harmonic analysis (Hz)
peakFrac  = 0.005;    % Fraction of peak for HNR band edges

% Intialize the results struct that
% Will return information
results = repmat(emptyResult_local(), nFiles, 1);


%% Main Loop
for n = 1:nFiles

    % Load in individual files
    fullpath = fullfile(wavFiles(n).folder, wavFiles(n).name);
    [x, fs0] = audioread(fullpath);

    % Ensure that audio in mono
    if size(x, 2) > 1
        x = mean(x, 2);
    end

    % Remove DC and upsample audio
    x = x(:);
    x = x - mean(x);
    x = resample(x, L, 1);
    fs = L * fs0;
    duration_s = numel(x) / fs;

    % Fill in file identification
    results(n).fileName   = string(wavFiles(n).name);
    results(n).fullPath   = string(fullpath);
    results(n).fs_Hz      = fs0;
    results(n).fs_proc_Hz = fs;
    results(n).duration_s = duration_s;
    results(n).waveforms = x;

    % Compute FFT used for HNR
    N_fft = numel(x);
    X_fft = fft(x);
    P2    = abs(X_fft / N_fft);
    P1    = P2(1:floor(N_fft/2)+1);

    if numel(P1) > 2
        P1(2:end-1) = 2 * P1(2:end-1);
    end

    f_full = fs * (0:floor(N_fft/2)) / N_fft;

    % ==========================================
    % Find F0 using autocorrelation
    % ===========================================
    frameLen   = round(frameDur * fs);          % Frame length in samples
    lagMin     = round(fs / f0Max);             % Min sample bound for autocorrelation
    lagMax     = round(fs / f0Min);             % Max sample bound for autocorrelation
    ts_samples = round(0.5 * fs);               % Start 1/2 second into audio
    N_sig      = length(x);

    % Ensures that there are enough samples to run autocorrelation
    if (N_sig - ts_samples - frameLen) <= 0
        continue;
    end

    numFrames = floor((N_sig - ts_samples - frameLen) / lagMin) + 1;
    f0_frames = NaN(numFrames, 1);
    ts_list   = [];

    % For each frame, find the autocorrelation peak associate with each period
    for m = 1:numFrames

        % Another check
        if (ts_samples + frameLen - 1) > N_sig
            break;
        end

        % Extract the current frame
        frame = x(ts_samples : ts_samples + frameLen - 1);
        frame = frame - mean(frame); %remove DC

        % Compute full AUTOcorrelation of theframe with itself.
        % This is the actual period detection aspect -> an n multiple of a period should be
        % A repetition of the signal -> high correlation
        [r, ~] = xcorr(frame, frame);
        r = r(frameLen:end); % pos lag
        r = r / (r(1) + eps); % normalize

        % Constrain all future searches to a plus-minus 20Hz windows so the fundamental frequency is
        % Maintained as the source for jitter and shimmer
        if m > 1 && ~isnan(f0_frames(m-1))
            lastF0          = f0_frames(m-1);
            lagMin_search   = max(lagMin, round(fs / (lastF0 + 20)));
            lagMax_search   = min(lagMax, round(fs / max(lastF0 - 20, 1)));
        else
            % For first period, use normal large upper and lower bounds
            lagMin_search = lagMin;
            lagMax_search = lagMax;
        end

        % Skip this frame if the search range is invalid or exceeds the
        % Autocorrelation length
        if lagMin_search >= lagMax_search || lagMax_search > numel(r)
            continue;
        end

        % Find the lag with the highest autocorrelation within the search window
        search          = r(lagMin_search:lagMax_search);
        [pk, idxPk]    = max(search);
        bestLag         = lagMin_search + idxPk - 1;   % Find absolute lag

        % Just in case not positive correlation is found
        if pk <= 0
            continue;
        end

        % Move along to the next period by the lag associated peak
        ts_samples = ts_samples + bestLag;

        % Stop if the signal runs out of samples
        if (ts_samples + frameLen - 1) > N_sig
            break;
        end

        % Save the time stamp for the period and compute the F0
        ts_list(end+1, 1) = (ts_samples - 1) / fs;
        f0_frames(m)      = fs / bestLag;
    end

    if all(isnan(f0_frames))
        continue;
    end

    % Averages the frequency associated with each period to find the fundamental frequency
    F0 = median(f0_frames, 'omitnan');
    results(n).F0_Hz = F0;

    % =========================
    % Calculate HNR
    % =========================

    % Initialise
    HNR = NaN;
    valid_bins = f_full <= maxFreq;
    f_fft      = f_full(valid_bins);
    P1_fft     = P1(valid_bins);

    % Ensure that F0 is positive
    if isfinite(F0) && F0 > 0

        % Estimated haronics from calculated fundamental frequency
        harmonics = F0:F0:maxFreq;

        % Compute the PSD
        [Pxx_hnr, f_hnr] = pwelch(x, [], [], [], fs);
        keep_hnr = f_hnr <= maxFreq;
        f_hnr    = f_hnr(keep_hnr);
        Pxx_hnr  = Pxx_hnr(keep_hnr);

        results(n).hnr_f_Hz = f_hnr;
        results(n).hnr_psd  = Pxx_hnr;

        bandLeft  = NaN(size(harmonics));
        bandRight = NaN(size(harmonics));

        % Find the actual harmonics around estimated harmonics that represents the actual harmonics
        for k = 1:length(harmonics)

            % Set bandwidth for kth harmonic
            fCenter  = harmonics(k);
            idxLocal = (f_hnr >= (fCenter - bandWidth/2)) & (f_hnr <= (fCenter + bandWidth/2));
            fLocal   = f_hnr(idxLocal);
            powLocal = Pxx_hnr(idxLocal);

            if isempty(fLocal)
                continue;
            end

            % Find peak associated with harmonic
            [peakVal, iPeak] = max(powLocal);
            if ~isfinite(peakVal) || peakVal <= 0
                continue;
            end

            % Find bandwidth associated with power using power threshold
            fPeak   = fLocal(iPeak);
            halfVal = peakVal * peakFrac;

            % Move left until threshold power value is found to set lower bound
            iL = iPeak;
            while iL > 1 && powLocal(iL) >= halfVal
                iL = iL - 1;
            end

            % Move left until threshold power value is found to set upper bound
            iR = iPeak;
            while iR < numel(powLocal) && powLocal(iR) >= halfVal
                iR = iR + 1;
            end

            % Using bounds, find the width of harmonic power contribution
            leftWidth  = fPeak - fLocal(iL);
            rightWidth = fLocal(iR) - fPeak;
            halfWidth  = max(leftWidth, rightWidth);

            bandLeft(k)  = fPeak - halfWidth;
            bandRight(k) = fPeak + halfWidth;

            results(n).hnr_bandLeft_Hz  = bandLeft(:);
            results(n).hnr_bandRight_Hz = bandRight(:);
            results(n).harmonic_freqs_Hz = harmonics(:);
        end

        BW_h = 0;
        Ph   = 0;

        % Accumulate power across all harmonics for HNR
        for k = 1:length(bandLeft)
            if ~isfinite(bandLeft(k)) || ~isfinite(bandRight(k))
                continue;
            end

            BW_h = BW_h + (bandRight(k) - bandLeft(k));
            idxBand = (f_hnr >= bandLeft(k)) & (f_hnr <= bandRight(k));
            Ph = Ph + sum(Pxx_hnr(idxBand));
        end

        % Compute HNR using PSD power.
        Ptot = sum(Pxx_hnr);
        BW_tot = f_hnr(end) - f_hnr(1);
        BW_n   = max(BW_tot - BW_h, eps);
        Pn     = max(Ptot - Ph, eps);
        HNR = 10 * log10((Ph / max(BW_h, eps)) / (Pn / BW_n));
    end

    % Save HNR to results
    results(n).HNR_dB = HNR;

    % =========================
    % Calculate PSD Jitter
    % =========================

    % Initialze
    numSecs      = floor(length(x) / fs);
    pcJitter     = NaN;
    nSecondsUsed = 0;

    % Ensure that F0 is positive
    if isfinite(F0) && F0 > 0
        harmonics_fixed = F0:F0:maxFreq;
        nHarm           = length(harmonics_fixed);
        PC_mat          = NaN(numSecs, nHarm);

        % Extract one-second segment and compute the PSD for this section
        for s = 1:numSecs
            i1 = round((s-1)*fs) + 1;
            i2 = min(round(s*fs), length(x));
            x_sec = x(i1:i2);

            [Pxx_s, f_s] = pwelch(x_sec, [], [], [], fs);
            keep_s = f_s <= maxFreq;
            f_s    = f_s(keep_s);
            Pxx_s  = Pxx_s(keep_s);

            harmonicPower = NaN(nHarm,1);

            % Loop through all harmonics
            for k = 1:nHarm

                % Set bandwidth for kth harmonic
                fCenter  = harmonics_fixed(k);
                idxLocal = (f_s >= (fCenter - bandWidth/2)) & (f_s <= (fCenter + bandWidth/2));
                fLocal   = f_s(idxLocal);
                powLocal = Pxx_s(idxLocal);

                if isempty(fLocal)
                    continue;
                end

                % Find peak associated with harmonic
                [peakVal, iPeak] = max(powLocal);
                if ~isfinite(peakVal) || peakVal <= 0
                    continue;
                end

                % Find bandwidth associated with power using power threshold
                halfVal = peakVal * peakFrac;

                % Walks left until lower bound is found
                iL = iPeak;
                while iL > 1 && powLocal(iL) >= halfVal
                    iL = iL - 1;
                end

                % Walks right until upper bound is found
                iR = iPeak;
                while iR < numel(powLocal) && powLocal(iR) >= halfVal
                    iR = iR + 1;
                end

                % Sums the power within the bandwidth
                idxBand = (f_s >= fLocal(iL)) & (f_s <= fLocal(iR));
                harmonicPower(k) = sum(Pxx_s(idxBand));
            end

            % Total power
            totalPow = sum(harmonicPower, 'omitnan');
            if totalPow > 0
                PC_mat(s,:) = harmonicPower ./ totalPow;
                nSecondsUsed = nSecondsUsed + 1;
            end
        end

        % 1 second intervals until the end of the audio file
        untilS = round(numSecs / 6);
        if untilS < size(PC_mat,1)
            PC_mat = PC_mat(untilS+1:end, :);
        end

        results(n).PC_mat_raw = PC_mat;

        % Compute PSD jitter from consecutive rows
        allDiffs = [];
        allVals  = [];


        % Compare same kth harmnic in each frame
        for s = 2:size(PC_mat,1)
            yPrev = PC_mat(s-1,:);
            yCurr = PC_mat(s,:);
            valid = isfinite(yPrev) & isfinite(yCurr);

            if any(valid)
                allDiffs = [allDiffs, abs(yCurr(valid) - yPrev(valid))];
            end
        end

        allVals = PC_mat(isfinite(PC_mat));

        % Compute the average difference
        if ~isempty(allDiffs) && ~isempty(allVals)
            meanDiff = sum(allDiffs, 'omitnan') / numel(allDiffs);
            meanVal  = sum(allVals,  'omitnan') / numel(allVals);
            pcJitter = meanDiff / (meanVal + eps);
        end
    else
        results(n).PC_mat_raw = [];
    end

    % Save PSD jitter to results
    results(n).PSD_jitter_percent = 100 * pcJitter;
    results(n).nSecondsUsed       = nSecondsUsed;

    % =========================
    % Calculate shimmer
    % =========================

    ts_samp_abs = round(ts_list * fs); %Times stamps in periods
    numPeriods  = length(ts_samp_abs) - 1; %Number of periods

    % Initialize
    M_peak = NaN(numPeriods, 1);
    m_peak = NaN(numPeriods, 1);

    % For each periods, find the peak-to-peak amplitude
    for k = 1:numPeriods

        % Index of back of period
        idx1 = ts_samp_abs(k);
        idx2 = ts_samp_abs(k+1) - 1;

        % Check if proper length
        if idx2 > length(x)
            idx2 = length(x);
        end

        % Check is proper orientation
        if idx1 < 1 || idx1 >= idx2
            continue;
        end

        % Create the segment that will be searched and find the peaks
        seg = x(idx1:idx2);
        [pksMax, ~] = findpeaks(seg);

        % If not peak is found, expand the search window.
        if isempty(pksMax)
            idx1b = max(1, idx1-5);
            idx2b = min(length(x), idx2+5);
            seg   = x(idx1b:idx2b);
            [pksMax, ~] = findpeaks(seg);
        end

        % Get the max peak for the top of App
        if ~isempty(pksMax)
            M_peak(k) = max(pksMax);
        end

        % Creates inverted segment to find min peaks
        seg2 = x(ts_samp_abs(k):min(ts_samp_abs(k+1)-1, length(x)));
        [pksMin, ~] = findpeaks(-seg2);


        % If not peak is found, expand the search window.
        if isempty(pksMin)
            idx1b = max(1, ts_samp_abs(k)-5);
            idx2b = min(length(x), min(ts_samp_abs(k+1)-1, length(x))+5);
            seg2  = x(idx1b:idx2b);
            [pksMin, ~] = findpeaks(-seg2);
        end

        % Revert peak back to min value
        if ~isempty(pksMin)
            m_peak(k) = -max(pksMin);
        end
    end

    % Finds the peak to peak amplitude from the min and max
    A_pp = M_peak - m_peak;
    A_pp = A_pp(~isnan(A_pp) & A_pp > 0);


    % Computes local shimmer
    if numel(A_pp) < 2
        localShimmer = NaN;
    else
        localShimmer = mean(abs(diff(A_pp))) / (mean(A_pp) + eps);
    end

    % Stores the local shimmer results
    results(n).shimmer_percent = 100 * localShimmer;
    results(n).nAmplitudesUsed = numel(A_pp);

    % Stores raw App values
    A0_pp = A_pp;
    if numel(A0_pp) >= 2
        untilA = round(length(A0_pp) / 6);
        if untilA < numel(A0_pp)
            A0_pp = A0_pp(untilA+1:end);
        end
    end

    results(n).A_pp_raw = A0_pp(:);
    results(n).timeStamps = ts_samp_abs;

    % =========================
    % Calculate Jitter
    % =========================

    % Compute periods by taking derivative of time stamps
    T_periods = diff(ts_samp_abs) / fs;

    % Remove the first 1/6 from the jitter calculation. Artificial jitter was noticed in the roughly this time window,
    % Meaning the front must be removed.
    until = round(length(T_periods) / 6);
    if until >= 1 && until < length(T_periods)
        T_periods(1:until) = [];
    end

    % Only keep valid periods within possible vocal window
    valid_T = T_periods > (1/f0Max) & T_periods < (1/f0Min);
    T_periods = T_periods(valid_T);
    N_T = length(T_periods);

    % Compute local jitter
    if N_T < 2
        localJitter = NaN;
    else
        num = (1/(N_T-1)) * sum(abs(diff(T_periods)));
        den = (1/N_T)     * sum(T_periods);
        localJitter = num / den;
    end

    % Save jitter to results
    results(n).jitter_percent = 100 * localJitter;
    results(n).nPeriodsUsed   = N_T;
    results(n).T_periods_raw  = T_periods(:);

end
end

% =================================
% Local helper to build struct
% ==================================
function s = emptyResult_local()
s = struct( ...
    'fileName', "", ...
    'fullPath', "", ...
    'fs_Hz', NaN, ...
    'fs_proc_Hz', NaN, ...
    'waveforms', [], ...
    'duration_s', NaN, ...
    'F0_Hz', NaN, ...
    'jitter_percent', NaN, ...
    'shimmer_percent', NaN, ...
    'HNR_dB', NaN, ...
    'PSD_jitter_percent', NaN, ...
    'nPeriodsUsed', NaN, ...
    'nAmplitudesUsed', NaN, ...
    'nSecondsUsed', NaN, ...
    'T_periods_raw', [], ...
    'timeStamps', [], ...
    'A_pp_raw', [], ...
    'Amax', [], ...
    'Amin', [], ...
    'PC_mat_raw', [], ...
    'harmonic_freqs_Hz', [], ...
    'hnr_f_Hz', [], ...
    'hnr_psd', [], ...
    'hnr_bandLeft_Hz', [], ...
    'hnr_bandRight_Hz', []);
end

% =====================================
% Local helper to accept .wav or folder
% =====================================
function wavFiles = getWavFiles_local(filepath)
filepath = char(filepath);

if isfolder(filepath)
    wavFiles = dir(fullfile(filepath, '*.wav'));
    [~, idx] = sort({wavFiles.name});
    wavFiles = wavFiles(idx);

elseif isfile(filepath)
    [folder, name, ext] = fileparts(filepath);

    if ~strcmpi(ext, '.wav')
        error('Input file must be a .wav file.');
    end

    tmp = dir(filepath);
    if isempty(tmp)
        error('Could not locate the specified .wav file.');
    end

    wavFiles = tmp;
    wavFiles.folder = folder;
    wavFiles.name   = [name ext];

else
    error('Input path does not exist.');
end
end