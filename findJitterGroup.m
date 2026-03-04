function [localJitter] = findJitterGroup(statusStr, sexStr, vowelStr, dataA, dataI, fs, plotBool)

    [~, cycleTS] = findCycleTSGroup(statusStr, sexStr, vowelStr, dataA, dataI, fs);
    
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
    