%This script plots the periods array for a single audio file.
%Load single audo file
[x, fs] = audioread('/Users/hayden/Documents/Minsk2020_ALS_database/HC/115_i.wav');

if size(x,2) > 1
    x = mean(x,2);
end

audioCycles = findCycleTSSingle(x, fs);

if length(audioCycles) < 3
    error('Not enough cycles detected.');
end

%find periods arrays
T = diff(audioCycles);
T(1) = [];

%% ----------- Plot -----------
figure;
plot(T,'-o');
xlabel('Cycle Index');
ylabel('Period Length (seconds)');
title('Period Array Using Your Exact Function');
grid on;

