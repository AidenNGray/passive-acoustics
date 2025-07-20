% Used for finding spectral fingerprint of ballast pump


%% Testing
% Loading netcdf files
addpath(genpath('2024 nc'))
file = 'glider_ANGUS_glider_1_240201_002528.nc';

[time, freq, dbSpec] = nc2spec(file);

% Test
figure;
imagesc(time, freq, dbSpec');
colorbar;
axis xy;
ylabel('Frequency (Hz)');
xlabel('Time')
title(filename,'Interpreter','none');


%% Making larger spectrogram
% Approx 1feb24 00:00:00 to 12:00:00
files = dir("2024 nc\working\*.nc");
timeFull = [];
freqFull = zeros(256,1);
dbSpecFull = [];

for i = 1:length(files)
    [time, freq, dbSpec] = nc2spec(files(i).name);
    timeFull = [timeFull; time];
    dbSpecFull = [dbSpecFull; dbSpec];
    if i == 1
        freqFull = freq;
    end
end

% Test visualization
figure;
imagesc(timeFull, freqFull, dbSpecFull');
colorbar;
axis xy;
ylabel('Frequency (Hz)');
xlabel('Time')
%title(filename,'Interpreter','none');

%% Ballast pump segmentation
timestamps = {'00:01:48', '00:09:52', ' 00:28:03', '00:35:53', '00:59:06', ...
    '01:57:28', '01:41:45', '01:50:08', '02:03:54', '02:12:00.0', '02:21:46', ...
    '03:08:24', '03:41:26', '04:18:58', '04:43:03', '05:27:24', '05:33:19', ...
    '05:43:48', '06:00:20', '06:10:36', '06:23:21', '06:41:34', '09:32:21', ...
    '09:55:10', '10:20:06', '10:36:57', '11:11:08', '11:23:40', '11:37:59', ...
    '11:49:41'}; % Relative to 00:00:00
referenceTime = datetime("2024 02 01 00 00 00","InputFormat","yyyy MM dd HH mm ss");

dur = duration(timestamps);
secSinceMid = seconds(dur);
dtCenterTimestamps = referenceTime + seconds(secSinceMid);

dtStartTime = dtCenterTimestamps - seconds(6);
dtEndTime = dtCenterTimestamps + seconds(6);

timeFull_rounded = dateshift(timeFull, 'start', 'second');
startTime_rounded = dateshift(dtStartTime, 'start', 'second');
centerTime_rounded = dateshift(dtCenterTimestamps, 'start', 'second');
endTime_rounded = dateshift(dtEndTime, 'start', 'second');

ballastSegments = struct();
n = 0;

for i = 1:length(timestamps)
    if dtCenterTimestamps(i) < timeFull(1)
        continue
    end

    n = n+1;
    startIndex = find(timeFull_rounded == startTime_rounded(i), 1);
    centerIndex = find(timeFull_rounded == centerTime_rounded(i), 1);
    endIndex = find(timeFull_rounded == endTime_rounded(i), 1);

    blSpectrogram = dbSpecFull(startIndex:centerIndex,:);
    motorSpectrogram = dbSpecFull(centerIndex:endIndex,:);

    ballastSegments(n).blSpecSegment = blSpectrogram;
    ballastSegments(n).motorSpecSegment = motorSpectrogram;

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

    ballastSegments(n).blSpectrum = mean(blSpectrogram, 1);
    ballastSegments(n).motorSpectrum = mean(motorSpectrogram, 1);
end

%% Ballast segmentation with indicies
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

% Plotting
freq = freqFull;  % replace with actual frequency axis if you have one

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

figure;
plot(freq, (mean_motor - mean_baseline));
xlabel('Freqency (Hz)')
ylabel('Amplitude (dB)')
title('Ballast Pump Spectral Fingerprint on 01Feb2024')
