% Find spectral fingerprint of ballast motor

%% Set up
% Loading audio data
addpath('D:\audio data\2024 angus1\segmented')
audioFile = '20240201_000000'; % DO NOT CHANGE
[yMono, Fs] = audioread([audioFile '.wav']);
timestamps = {'00:01:48.3', '00:09:51.6', ' 00:28:03.2', '00:35:53.3', '00:59:05.7', ...
    '01:57:27.8', '01:41:45.2', '01:50:07.6', '02:03:53.9', '02:12:00.0', '02:21:45.5', ...
    '03:08:24.2', '03:41:25.8', '04:18:58.1', '04:43:02.6', '05:27:24.0', '05:33:19.3', ...
    '05:43:48.1', '06:00:19.9', '06:10:35.6', '06:23:21.4', '06:41:33.7', '09:32:20.5', ...
    '09:55:09.8', '10:20:05.8', '10:36:56.7', '11:11:07.7', '11:23:40.2', '11:37:59.4', ...
    '11:49:41.0'};
N_segments = length(timestamps);

% PSD parameters
parameters.window = blackman(1024);
parameters.noverlap = 512;
parameters.nfft = 2048;

% preallocation
num_freqs = parameters.nfft/2 + 1;
baseline_psd = zeros(N_segments, num_freqs);
motor_psd = zeros(N_segments, num_freqs);

%% PSD computations

for i = 1:N_segments
    [Mpxx, fMotor, BLpxx, fBL] = psdSegment(yMono, Fs, parameters, timestamps{i}, 6, 6);

    baseline_psd(i, :) = 10*log10(BLpxx);  % dB
    motor_psd(i, :) = 10*log10(Mpxx);  % dB
end

%% Statistical computations

pvals = zeros(1, num_freqs);
for k = 1:num_freqs
    [~, p] = ttest2(baseline_psd(:,k), motor_psd(:,k));
    pvals(k) = p;
end

%% General average plotting

plot(fBL, mean(baseline_psd), 'b', fMotor, mean(motor_psd), 'r');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
legend('Baseline', 'Motor');
title('Average PSD Comparison   n=30    t=6sec');
grid on;

%% Statistical differences plotting

sig_thresh = 0.05;  % uncorrected
significant = pvals < sig_thresh;
mDif = mean(motor_psd - baseline_psd);

figure;
plot(fMotor, mDif, 'k');
hold on;
plot(fMotor(significant), mDif(significant), 'ro');
xlabel('Frequency (Hz)');
ylabel('Mean PSD Difference (dB)');
title('Motor - Baseline (Significant Points Highlighted)');
grid on;
hold off;

%% Exporting FP

specFP.motor = 'ballast';
specFP.samples = timestamps;
specFP.numSamples = N_segments;
specFP.signifcance = significant;
specFP.freq = fMotor;
specFP.avgMotor = motor_psd;
specFP.avgBaseline = baseline_psd;
specFP.fingerprint = mDif;

save("ballastFingerprint.mat", 'specFP')

