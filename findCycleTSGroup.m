function [out, cycleTS] = findCycleTSGroup(statusStr, sexStr, vowelStr, dataA, dataI, fs)

%This script output an array of periods corresponding to a group of audio files in a subgroup.

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
f0Max = 300;
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

            threshold = 0.3;

            % Find peaks in the search region
            [pks, locs] = findpeaks(search2);

            % Keep only peaks above threshold
            validIdx = find(pks > threshold);

            if isempty(validIdx)
                break;   % no valid peak found
            end

            % Take the FIRST peak above threshold
            firstPeakLoc = locs(validIdx(1));
            bestLag2 = lagMin + firstPeakLoc - 1;

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