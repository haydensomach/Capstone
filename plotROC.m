function rocResults = plotROC(nonALSExcelPath, ALSExcelPath)
% ChatGPT used for formatting the code.

% The function calculates the ROC plot for the four metrics

% Input: a file path to a folder/single file of .wave file/s
% Output: an ROC plot for each metric and the composite metric

% Read the files
T_NonALS = readtable(nonALSExcelPath);
T_ALS    = readtable(ALSExcelPath);

% Figures names
featureNames = {'Jitter_percent', 'Shimmer_percent', 'HNR_dB', 'PSD_Jitter_percent'};

% Required parameters for ROC plotting
requiredVars = {'FileName','Fs_Hz','Duration_s', ...
    'F0_Hz','HNR_dB','PSD_Jitter_percent', ...
    'Jitter_percent','Shimmer_percent', ...
    'Suspect_F0','Suspect_HNR','Suspect_PSD', ...
    'Suspect_Jitter','Suspect_Shimmer'};

for i = 1:numel(requiredVars)
    if ~ismember(requiredVars{i}, T_NonALS.Properties.VariableNames)
        error('Non-ALS Excel file is missing column: %s', requiredVars{i});
    end
    if ~ismember(requiredVars{i}, T_ALS.Properties.VariableNames)
        error('ALS Excel file is missing column: %s', requiredVars{i});
    end
end

% 1 = ALS, 0 = NonALS
labels_all = [zeros(height(T_NonALS),1); ones(height(T_ALS),1)];

% Store results
nFeat = numel(featureNames);
X = cell(nFeat,1);
Y = cell(nFeat,1);
T = cell(nFeat,1);
AUC           = zeros(nFeat,1);
bestThreshold = zeros(nFeat,1);
bestTPR       = zeros(nFeat,1);
bestFPR       = zeros(nFeat,1);
idxBest       = zeros(nFeat,1);

figure;
set(gcf, 'Color', 'w');
hold on;
hLine = gobjects(nFeat+1, 1);

colors = [
    0 0.4470 0.7410;        % Blue
    0.8500 0.3250 0.0980;   % Orange
    0.9290 0.6940 0.1250;   % Yellow
    0.4940 0.1840 0.5560;   % Purple
    0.4660 0.6740 0.1880    % Green
    ];

% ROC calculations below
allScores = NaN(height(T_NonALS) + height(T_ALS), nFeat);
for k = 1:nFeat
    allScores(:,k) = [T_NonALS.(featureNames{k}); T_ALS.(featureNames{k})];
end
keep_all = all(isfinite(allScores), 2);

for k = 1:nFeat
    scores_original = [T_NonALS.(featureNames{k}); T_ALS.(featureNames{k})];
    labels = labels_all;

    % Remove NaNs for this feature
    keep = isfinite(scores_original);
    scores_original = scores_original(keep);
    labels = labels(keep);

    % Invert HNR
    if strcmp(featureNames{k}, 'HNR_dB')
        scores_forROC = -scores_original;
    else
        scores_forROC = scores_original;
    end

    % Compute ROC
    [X{k}, Y{k}, T{k}, AUC(k)] = perfcurve(labels, scores_forROC, 1);

    % Best threshold by Youden index
    youden = Y{k} - X{k};
    [~, idxBest(k)] = max(youden);

    % Convert threshold back to original scale for HNR
    if strcmp(featureNames{k}, 'HNR_dB')
        bestThreshold(k) = -T{k}(idxBest(k));
    else
        bestThreshold(k) = T{k}(idxBest(k));
    end

    bestTPR(k) = Y{k}(idxBest(k));
    bestFPR(k) = X{k}(idxBest(k));

    % Plot individual ROC
    hLine(k) = plot(X{k}, Y{k}, ...
        'LineWidth', 2, ...
        'Color', [colors(k,:) 0.3]);
end

% Composite weighted by individual preformance
labels_composite = labels_all(keep_all);
scores_norm_matrix = zeros(sum(keep_all), nFeat);

for k = 1:nFeat
    scores_original = allScores(keep_all, k);

    % Flip HNR so higher = more likely ALS
    if strcmp(featureNames{k}, 'HNR_dB')
        scores_forComposite = -scores_original;
    else
        scores_forComposite = scores_original;
    end

    % Normalize to [0,1]
    fMin = min(scores_forComposite);
    fMax = max(scores_forComposite);

    if fMax > fMin
        scores_norm = (scores_forComposite - fMin) / (fMax - fMin);
    else
        scores_norm = zeros(size(scores_forComposite));
    end

    scores_norm_matrix(:,k) = scores_norm;
end

% Find the weighting by normalizing
weights = AUC(:);
weights = weights / sum(weights);

% Compute composite scores
composite_scores = scores_norm_matrix * weights;

% Create curve
[X_comp, Y_comp, T_comp, AUC_comp] = perfcurve(labels_composite, composite_scores, 1);

% Find the best threshold for each metric
youden_comp = Y_comp - X_comp;
[~, idxBest_comp] = max(youden_comp);
bestThreshold_comp = T_comp(idxBest_comp);
bestTPR_comp = Y_comp(idxBest_comp);
bestFPR_comp = X_comp(idxBest_comp);

% Plotting code for axes and labels
hLine(nFeat+1) = plot(X_comp, Y_comp, 'LineWidth', 2.5, 'Color', [0,0,0]);
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title('ROC Curve Male');
grid on;
hold off;

ax = gca;
set(ax, 'Color', 'w', 'FontSize', 13);

% Print the results from the individuals ROC plots and the composite metric
for k = 1:nFeat
    fprintf('AUC (%s) = %.4f\n', featureNames{k}, AUC(k));
    fprintf('Best threshold (%s) = %.6f\n', featureNames{k}, bestThreshold(k));
    fprintf('TPR at best threshold (%s) = %.4f\n', featureNames{k}, bestTPR(k));
    fprintf('FPR at best threshold (%s) = %.4f\n', featureNames{k}, bestFPR(k));

    if strcmp(featureNames{k}, 'HNR_dB')
        fprintf('Decision rule: classify as ALS if %s <= %.6f\n\n', ...
            featureNames{k}, bestThreshold(k));
    else
        fprintf('Decision rule: classify as ALS if %s >= %.6f\n\n', ...
            featureNames{k}, bestThreshold(k));
    end
end

fprintf('AUC (Composite average) = %.4f\n', AUC_comp);
fprintf('Best threshold (Composite average) = %.6f\n', bestThreshold_comp);
fprintf('TPR at best threshold (Composite) = %.4f\n', bestTPR_comp);
fprintf('FPR at best threshold (Composite) = %.4f\n\n', bestFPR_comp);

% Create a legend for the plot
legend([hLine(1) hLine(2) hLine(3) hLine(4) hLine(5)], ...
    sprintf('Jitter (AUC = %.3f)', AUC(1)), ...
    sprintf('Shimmer (AUC = %.3f)', AUC(2)), ...
    sprintf('HNR (AUC = %.3f)', AUC(3)), ...
    sprintf('PSD Jitter (AUC = %.3f)', AUC(4)), ...
    sprintf('Composite (AUC = %.3f)', AUC_comp), ...
    'Location', 'southeast');

% Store the results
rocResults.featureNames = featureNames;
rocResults.X = X;
rocResults.Y = Y;
rocResults.T = T;
rocResults.AUC = AUC;
rocResults.bestThreshold = bestThreshold;
rocResults.bestTPR = bestTPR;
rocResults.bestFPR = bestFPR;
rocResults.idxBest = idxBest;

rocResults.X_comp = X_comp;
rocResults.Y_comp = Y_comp;
rocResults.T_comp = T_comp;
rocResults.AUC_comp = AUC_comp;
rocResults.bestThreshold_comp = bestThreshold_comp;
rocResults.bestTPR_comp = bestTPR_comp;
rocResults.bestFPR_comp = bestFPR_comp;
rocResults.idxBest_comp = idxBest_comp;
rocResults.weights = weights;
rocResults.keep_all = keep_all;
end