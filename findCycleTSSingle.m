function cycleTS = findCycleTSSingle(x, fs)

    % Remove DC
    x = x - mean(x);
    N = length(x);
    
    %% ---- Parameters (same as your original) ----
    frameDur = 0.040;
    frameLen = round(frameDur * fs);
    
    f0Min = 60;
    f0Max = 300;
    
    lagMin = round(fs / f0Max);
    lagMax = round(fs / f0Min);
    
    %% ---- Iterative Cycle Timestamp Extraction ----
    
    ts_samples = 44100;   % start index (1-based) — same as your original
    ts_list = 0;          % timestamps in seconds, starts at 0
    
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
    
    cycleTS = ts_list;
    
    end