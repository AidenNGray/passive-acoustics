% Used for finding spectral fingerprint of pitch motor
addpath(genpath('2024 nc'))

%% Making larger spectrogram
% Approx 1feb24 00:00:00 to 12:00:00
files = dir("2024 nc\ballast\*.nc");
timeFull = [];
dbSpecFull = [];

for i = 1:length(files)
    [time, freq, dbSpec] = nc2spec(files(i).name);
    timeFull = [timeFull; time];
    dbSpecFull = [dbSpecFull; dbSpec];
end

% Index hunting
figure;
imagesc(timeFull, freq, dbSpecFull');
colorbar;
axis xy;
ylabel('Frequency (Hz)');
xlabel('Time')
title('01Feb2024 Spectrogram')

%% Pitch segmentation with indicies
centerIndicies = [11295 11571 30822 40878 41229 93942 135298 137040 ...
    207970 245958 246161 320781 322579 322926 392476 392838 422960 ...
    423454 450046 450390 490226 534254 534735 564542 565301 603285 ...
    603558 628108 628453 660927];
endIndicies = [11317 11586 30845 40900 41248 93966 135321 137060 ...
    207996 245984 246181 320808 322606 322947 392503 392859 422987 ...
    423481 450070 450412 490250 534280 534756 564575 565323 603315 ...
    603582 628133 628476 660951];

motorDurSamples = endIndicies - centerIndicies; % Approximate number of samples motor runs for
startIndicies = centerIndicies - motorDurSamples;

pitchSegments = struct();

for i = 1:length(centerIndicies)
    blSpectrogram = dbSpecFull(startIndicies(i):centerIndicies(i),:);
    motorSpectrogram = dbSpecFull(centerIndicies(i):endIndicies(i),:);

    pitchSegments(i).blSpecSegment = blSpectrogram;
    pitchSegments(i).motorSpecSegment = motorSpectrogram;

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

    pitchSegments(i).blSpectrum = mean(blSpectrogram, 1);
    pitchSegments(i).motorSpectrum = mean(motorSpectrogram, 1);
end

%% Ballast pump computations & stats

n = numel(pitchSegments); 

% Preallocate
baseline_matrix = zeros(n, 256);
motor_matrix = zeros(n, 256);

for i = 1:n
    baseline_matrix(i, :) = pitchSegments(i).blSpectrum;
    motor_matrix(i, :) = pitchSegments(i).motorSpectrum;
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

% Plotting
figure;
plot(freq, mean_baseline, 'b', 'DisplayName', 'Baseline');
hold on;
plot(freq, mean_motor, 'r', 'DisplayName', 'Pitch');
xlabel('Frequency Bin');
ylabel('Amplitude (dB)');
title('Average Spectra @ Pitch Motor Actuations    n = 30')
legend;

significant_bins = p_values < 0.05;
hold on;
scatter(freq(significant_bins), mean_motor(significant_bins), 20, 'k', 'filled', 'DisplayName', 'p < 0.05');

%% Fingerprint computations
figure;
plot(freq, (mean_motor - mean_baseline), 'b');
xlabel('Freqency (Hz)')
ylabel('Amplitude (dB)')
title('Pitch Motor Spectral Fingerprint on 01Feb2024')
