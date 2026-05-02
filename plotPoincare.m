function out = plotPoincare(alsFolder, hcFolder, varargin)
%ChatGPT was used to format this code

% This script takes in two folders and produces plots of the calculated metrics

ALS = extractPoincareData(alsFolder, 'ALS');
HC  = extractPoincareData(hcFolder,  'HC');

out = calculatePoincare(ALS, HC, varargin{:});
end