% Used for finding spectral fingerprint of air pump


%% Making larger spectrogram
% Approx 1feb24 00:00:00 to 12:00:00
files = dir("2024 nc\2024_02\*.nc");
timeFull = [];
freq = zeros(256,1);
dbSpecFull = [];

for i = 1:length(files)
    [time, freq, dbSpec] = nc2spec(files(i).name);
    timeFull = [timeFull; time];
    dbSpecFull = [dbSpecFull; dbSpec];
end

% Test visualization
figure;
imagesc(timeFull, freq, dbSpecFull');
colorbar;
axis xy;
ylabel('Frequency (Hz)');
xlabel('Time')
%title(filename,'Interpreter','none');

%% Air segmentation with indicies
centerIndicies = [3460 7073 13023 42390 38516 75430 110516 144521 184280 ...
    247392 240396 262295 269577 320493 331118 355939 402133 412413 ...
    438327 447822 275977 491812 524416 541760 564187 575208 599964 ...
    611866 624236 653637];

motorDurSamples = 95; % Approximate number of samples motor runs for
startIndicies = centerIndicies - 95;
endIndicies = centerIndicies + 95;

ballastSegments = struct();

for i = 1:length(centerIndicies)
    blSpectrogram = dbSpecFull(startIndicies(i):centerIndicies(i),:);
    motorSpectrogram = dbSpecFull(centerIndicies(i):endIndicies(i),:);

    ballastSegments(i).blSpecSegment = blSpectrogram;
    ballastSegments(i).motorSpecSegment = motorSpectrogram;

    % figure;
    % imagesc(blSpectrogram');
    % colorbar;
    % axis xy;
    % ylabel('Frequency (Hz)');
    % xlabel('Time')
    % title(sprintf("Baseline i = %d",i))
    % 
    % figure;
    % imagesc(motorSpectrogram');
    % colorbar;
    % axis xy;
    % ylabel('Frequency (Hz)');
    % xlabel('Time')
    % title(sprintf("Motor i = %d",i))

    ballastSegments(i).blSpectrum = mean(blSpectrogram, 1);
    ballastSegments(i).motorSpectrum = mean(motorSpectrogram, 1);
end

%% Ballast pump computations & stats

n = numel(ballastSegments); 

% Preallocate
baseline_matrix = zeros(n, 256);
motor_matrix = zeros(n, 256);

for i = 1:n
    baseline_matrix(i, :) = ballastSegments(i).blSpectrum;
    motor_matrix(i, :) = ballastSegments(i).motorSpectrum;
end

% T-test
p_values = zeros(1, 256);
t_stats = zeros(1, 256);

for f = 1:256
    [~, p_values(f), ~, stats] = ttest(baseline_matrix(:,f), motor_matrix(:,f));
    t_stats(f) = stats.tstat;
end

% Average spectra
mean_baseline = mean(baseline_matrix, 1);
mean_motor = mean(motor_matrix, 1);

figure;
plot(freq, mean_baseline, 'b', 'DisplayName', 'Baseline');
hold on;
plot(freq, mean_motor, 'r', 'DisplayName', 'Ballast');
xlabel('Frequency Bin');
ylabel('Amplitude (dB)');
title('Average Spectra @ Ballast Pump Actuations    n = 30')
legend;

significant_bins = p_values < 0.05;
hold on;
scatter(freq(significant_bins), mean_motor(significant_bins), 20, 'k', 'filled', 'DisplayName', 'p < 0.05');

% Plotting fingerprint
figure;
plot(freq, (mean_motor - mean_baseline));
xlabel('Freqency (Hz)')
ylabel('Amplitude (dB)')
title('Ballast Pump Spectral Fingerprint on 01Feb2024')
