function out = calculatePoincare(ALS, HC, varargin)
% ChatGPT was used to format this script.
% ChatGPT also assisted in MATLAB synax that helped plot the poincare data

% The function of this script is to prepare the poincare plots 
% For the vocal biomarker metrics

% Input: two folder contains .wave files
% Output: poincare plots for each metric

%Gets information for each metric
p = inputParser;
addParameter(p, 'axLim', 2.5);
addParameter(p, 'caxMaxJitter', 600);
addParameter(p, 'caxMaxShimmer', 400);
addParameter(p, 'caxMaxPSD', 300);
parse(p, varargin{:});

axLim         = p.Results.axLim;
caxMax_jitter = p.Results.caxMaxJitter;
caxMax_shimmer = p.Results.caxMaxShimmer;
caxMax_psd    = p.Results.caxMaxPSD;

pool = @(cellArr) cell2mat( ...
    cellfun(@(v) v(:), cellArr(~cellfun(@isempty, cellArr)), ...
    'UniformOutput', false));

%Creates pooled normalization so that the SD is comparable
allT_pooled = [pool(ALS.T_periods_all); pool(HC.T_periods_all)];
allT_pooled = allT_pooled(isfinite(allT_pooled));
mu_T = mean(allT_pooled);
sd_T = std(allT_pooled);

allA_pooled = [pool(ALS.A_pp_all); pool(HC.A_pp_all)];
allA_pooled = allA_pooled(isfinite(allA_pooled));
mu_A = mean(allA_pooled);
sd_A = std(allA_pooled);

pool_PC = @(PC_cell) cell2mat( ...
    cellfun(@(M) M(isfinite(M)), ...
    cellfun(@(M) M(:), PC_cell(~cellfun(@isempty, PC_cell)), 'UniformOutput', false), ...
    'UniformOutput', false));

allPC_pooled = [pool_PC(ALS.PC_all); pool_PC(HC.PC_all)];
allPC_pooled = allPC_pooled(isfinite(allPC_pooled));
mu_PC = mean(allPC_pooled);
sd_PC = std(allPC_pooled);

%Builds the poincare pairs that are necessary for plotting
pairs_T_ALS  = build_pairs_local(ALS.T_periods_all, mu_T, sd_T);
pairs_T_HC   = build_pairs_local(HC.T_periods_all,  mu_T, sd_T);

pairs_A_ALS  = build_pairs_local(ALS.A_pp_all, mu_A, sd_A);
pairs_A_HC   = build_pairs_local(HC.A_pp_all,  mu_A, sd_A);

pairs_PC_ALS = build_pairs_PC_local(ALS.PC_all, mu_PC, sd_PC);
pairs_PC_HC  = build_pairs_PC_local(HC.PC_all,  mu_PC, sd_PC);

%Jitter figure
figure('Name', 'Poincare Jitter Comparison', 'Color', 'w', ...
    'Units', 'normalized', 'Position', [0.05 0.25 0.88 0.50]);
subplot(1,2,1);
plot_poincare_local(pairs_T_ALS, axLim, caxMax_jitter, ...
    'ALS — Pitch Periods', 'Normalized T_i', 'Normalized T_{i+1}');
subplot(1,2,2);
plot_poincare_local(pairs_T_HC, axLim, caxMax_jitter, ...
    'non-ALS — Pitch Periods', 'Normalized T_i', 'Normalized T_{i+1}');
sgtitle('Poincaré: Jitter (pooled normalization)', 'FontWeight', 'bold', 'FontSize', 17);

%Shimmer figure
figure('Name', 'Poincare Shimmer Comparison', 'Color', 'w', ...
    'Units', 'normalized', 'Position', [0.05 0.25 0.88 0.50]);
subplot(1,2,1);
plot_poincare_local(pairs_A_ALS, axLim, caxMax_shimmer, ...
    'ALS — Peak-to-Peak Amplitude', 'Normalized A_i', 'Normalized A_{i+1}');
subplot(1,2,2);
plot_poincare_local(pairs_A_HC, axLim, caxMax_shimmer, ...
    'non-ALS — Peak-to-Peak Amplitude', 'Normalized A_i', 'Normalized A_{i+1}');
sgtitle('Poincaré: Shimmer (pooled normalization)', 'FontWeight', 'bold', 'FontSize', 17);

%PC Comparsion figure
figure('Name', 'Poincare PC Comparison', 'Color', 'w', ...
    'Units', 'normalized', 'Position', [0.05 0.25 0.88 0.50]);
subplot(1,2,1);
if size(pairs_PC_ALS,1) >= 2
    plot_poincare_local(pairs_PC_ALS, axLim, caxMax_psd, ...
        'ALS — Harmonic Power Contribution', 'Normalized PC_i', 'Normalized PC_{i+1}');
else
    title('ALS — PC (insufficient data)'); axis square; box off;
end
subplot(1,2,2);
if size(pairs_PC_HC,1) >= 2
    plot_poincare_local(pairs_PC_HC, axLim, caxMax_psd, ...
        'non-ALS — Harmonic Power Contribution', 'Normalized PC_i', 'Normalized PC_{i+1}');
else
    title('non-ALS — PC (insufficient data)'); axis square; box off;
end
sgtitle('Poincaré: Harmonic Power Contribution (pooled normalization)', 'FontWeight', 'bold', 'FontSize', 17);

out = struct();
out.mu_T = mu_T; out.sd_T = sd_T;
out.mu_A = mu_A; out.sd_A = sd_A;
out.mu_PC = mu_PC; out.sd_PC = sd_PC;
out.pairs_T_ALS  = pairs_T_ALS;
out.pairs_T_HC   = pairs_T_HC;
out.pairs_A_ALS  = pairs_A_ALS;
out.pairs_A_HC   = pairs_A_HC;
out.pairs_PC_ALS = pairs_PC_ALS;
out.pairs_PC_HC  = pairs_PC_HC;
end

% Build pairs for all other
function pairs = build_pairs_local(cellArr, mu, sd)
pairs = [];
for i = 1:numel(cellArr)
    v = cellArr{i};
    if isempty(v) || numel(v) < 2
        continue;
    end
    v_norm = (v(:) - mu) / sd;
    pairs = [pairs; v_norm(1:end-1), v_norm(2:end)]; 
end
end

% Build pairs for PC only
function pairs = build_pairs_PC_local(PC_cell, mu, sd)
pairs = [];
for i = 1:numel(PC_cell)
    M = PC_cell{i};
    if isempty(M) || size(M,1) < 2
        continue;
    end

    M_norm = (M - mu) / sd;
    [~, nCols] = size(M_norm);

    for k = 1:nCols
        col = M_norm(:,k);
        valid = find(isfinite(col));

        if numel(valid) < 2
            continue;
        end

        consec = valid(diff(valid) == 1);
        if isempty(consec)
            continue;
        end

        pairs = [pairs; col(consec), col(consec+1)]; 
    end
end
end

%Plotting script for all poincare plots
function plot_poincare_local(pairs, axLim, caxMax, titleStr, xlabelStr, ylabelStr)

lo = -axLim;
hi =  axLim;

nBins  = 50;
xedges = linspace(lo, hi, nBins+1);
yedges = linspace(lo, hi, nBins+1);

[N,~,~,binX,binY] = histcounts2(pairs(:,1), pairs(:,2), xedges, yedges);

density = zeros(size(pairs,1),1);
valid   = binX > 0 & binY > 0;
if any(valid)
    density(valid) = N(sub2ind(size(N), binX(valid), binY(valid)));
end

hold on;
line([lo hi], [lo hi], 'Color', [0.6 0.6 0.6], 'LineStyle', '--', 'LineWidth', 1.0);
scatter(pairs(:,1), pairs(:,2), 12, density, 'filled', ...
    'MarkerFaceAlpha', 0.65, 'MarkerEdgeAlpha', 0);

colormap(copper);
cb = colorbar;
cb.Label.String = 'Local count';
clim([0 caxMax]);

d_perp = (pairs(:,2) - pairs(:,1)) / sqrt(2);
sd_val = std(d_perp);

text(0.97, 0.04, sprintf('SD_{\\perp} = %.4f', sd_val), ...
    'Units', 'normalized', 'HorizontalAlignment', 'right', ...
    'FontSize', 17, 'Color', [0.35 0.35 0.35]);
text(0.97, 0.10, sprintf('n = %d pairs', size(pairs,1)), ...
    'Units', 'normalized', 'HorizontalAlignment', 'right', ...
    'FontSize', 17, 'Color', [0.35 0.35 0.35]);

xlim([-1.5 3.2]);
ylim([-1.5 3.2]);
axis square;
box off;
grid on;

ax = gca;
ax.GridColor = [0.85 0.85 0.85];
ax.GridAlpha = 1.0;
ax.TickDir   = 'out';
ax.FontSize  = 17;

xlabel(xlabelStr, 'FontSize', 17);
ylabel(ylabelStr, 'FontSize', 17);
title(titleStr, 'FontSize', 17, 'FontWeight', 'bold');
hold off;
end