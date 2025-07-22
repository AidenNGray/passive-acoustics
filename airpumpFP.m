% Used for finding spectral fingerprint of air pump
load('airSpectrogram.mat')

%% Making larger spectrogram
% Approx 1feb24 00:00:00 to 8feb24 00:00:00
files = dir("2024 nc\air\*.nc");
airSpectrograms = struct();

for i = 1:8
    timeFull = [];
    freq = zeros(256,1);
    dbSpecFull = [];
    for j = 1:60
        index = (i-1)*60 + j;
        [time, freq, dbSpec] = nc2spec(files(index).name);
        timeFull = [timeFull; time];
        dbSpecFull = [dbSpecFull; dbSpec];
        fprintf("File %d loaded\n", index)
    end
    airSpectrograms(i).time = timeFull;
    airSpectrograms(i).spectrogram = dbSpecFull;
    fprintf("Section %d complete", i)
end
disp("All files loaded")
% Test visualization

for i = 1:numel(airSpectrograms)
    figure;
    imagesc(airSpectrograms(i).spectrogram');
    colorbar;
    axis xy;
    ylabel('Frequency (Hz)');
    xlabel('Time')
    title(sprintf("Section %d",i))
end

%% Air segmentation with indicies
segmentLength = 843720;

% sec2 = segmentLength;
% sec3 = 2 * segmentLength;
% sec4 = 3 * segmentLength;
% sec5 = 4 * segmentLength;
% sec6 = 5 * segmentLength;
% sec7 = 6 * segmentLength;
% sec8 = 7 * segmentLength;

startAir = struct();
endAir = struct();

startAir(1).index = [46873 278908 498106 722158];
startAir(2).index = [64842 554384 779370];
startAir(3).index = [160008 385248 610354];
startAir(4).index = [216885 441892 666341];
startAir(5).index = [48327 273006 497437 723545];
startAir(6).index = [104278 328962 554447 778429];
startAir(7).index = [160250 385083];
startAir(8).index = 102050;

endAir(1).index = [49523 281926 500714 724668];
endAir(2).index = [67863 557298 782081];
endAir(3).index = [162790 388114 613011];
endAir(4).index = [219508 444489 669165];
endAir(5).index = [51112 275850 500201 726333];
endAir(6).index = [107218 331770 557387 781317];
endAir(7).index = [163108 387875];
endAir(8).index = 105055;

motorDurSamples = 1000; % Approximate number of samples motor runs for
airSegments = struct();
n = 0;

for i = 1:numel(startAir)
    startBG = startAir(i).index - motorDurSamples;
    endBG = startAir(i).index;
    startSurf = endAir(i).index;
    endSurf = endAir(i).index + motorDurSamples;
    for j = 1:length(endBG)
        n = n + 1;

        blSpectrogram = airSpectrograms(i).spectrogram(startBG(j):endBG(j),:);
        motorSpectrogram = airSpectrograms(i).spectrogram(endBG(j):startSurf(j),:);
        surfSpectrogram = airSpectrograms(i).spectrogram(startSurf(j):endSurf(j),:);
    
        airSegments(n).blSpecSegment = blSpectrogram;
        airSegments(n).motorSpecSegment = motorSpectrogram;
        airSegments(n).surfSpecSegment = surfSpectrogram;
    
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
        % 
        % figure;
        % imagesc(surfSpectrogram');
        % colorbar;
        % axis xy;
        % ylabel('Frequency (Hz)');
        % xlabel('Time')
        % title(sprintf("Surface i = %d",i))
    
        airSegments(n).blSpectrum = mean(blSpectrogram, 1);
        airSegments(n).motorSpectrum = mean(motorSpectrogram, 1);
        airSegments(n).surfSpectrum = mean(surfSpectrogram, 1);
    end
end

%% Ballast pump computations & stats

n = numel(airSegments); 

% Preallocate
baseline_matrix = zeros(n, 256);
motor_matrix = zeros(n, 256);
surface_matrix = zeros(n, 256);

for i = 1:n
    baseline_matrix(i, :) = airSegments(i).blSpectrum;
    motor_matrix(i, :) = airSegments(i).motorSpectrum;
    surface_matrix(i, :) = airSegments(i).surfSpectrum;
end

% T-test
p_values_bgM = zeros(1, 256); % background to motor
t_stats_bgM = zeros(1, 256);
p_values_mS = zeros(1, 256); % motor to surface
t_stats_mS = zeros(1, 256);
p_values_bgS = zeros(1, 256); % background to surface
t_stats_bgS = zeros(1, 256);

for f = 1:256
    [~, p_values_bgM(f), ~, stats] = ttest(baseline_matrix(:,f), motor_matrix(:,f));
    t_stats_bgM(f) = stats.tstat;

    [~, p_values_mS(f), ~, stats] = ttest(motor_matrix(:,f), surface_matrix(:,f));
    t_stats_mS(f) = stats.tstat;

    [~, p_values_bgS(f), ~, stats] = ttest(baseline_matrix(:,f), surface_matrix(:,f));
    t_stats_bgS(f) = stats.tstat;
end

% Average spectra
mean_baseline = mean(baseline_matrix, 1);
mean_motor = mean(motor_matrix, 1);
mean_surface = mean(surface_matrix, 1);

figure;
plot(freq, mean_baseline, 'b', 'DisplayName', 'Baseline');
hold on;
plot(freq, mean_motor, 'r', 'DisplayName', 'Air Pump');
plot(freq, mean_surface, 'g', 'DisplayName', 'Surface')
xlabel('Frequency Bin');
ylabel('Amplitude (dB)');
title('Average Spectra @ Air Pump Actuations    n = 24')
legend;

significant_bins_bgM = p_values_bgM < 0.05;
significant_bins_mS = p_values_mS < .05;
hold on;
scatter(freq(significant_bins_bgM), mean_motor(significant_bins_bgM), 20, 'k', 'filled', 'DisplayName', 'baseline p < 0.05');
scatter(freq(significant_bins_mS), mean_motor(significant_bins_mS), 20, 'm', 'DisplayName', 'surface p < .05');

%% Fingerprint computations
% Plotting fingerprint
figure;
plot(freq, (mean_motor - mean_baseline), 'b', 'DisplayName', 'Relative to Baseline');
hold on;
plot(freq, (mean_motor - mean_surface), 'g', 'DisplayName', 'Relative to Surface')
xlabel('Freqency (Hz)');
ylabel('Amplitude (dB)');
title('Ballast Pump Spectral Fingerprint from 01Feb2024 to 05Feb2024');
legend;
hold off;

figure;
plot(freq, (mean_surface - mean_baseline), 'Color', [0.7 0 1])
xlabel('Frequency (Hz)')
ylabel('Amplitude (dB)')
title('Surface Noise Spectral Fingerprint from 01Feb2024 to 05Feb2024')
