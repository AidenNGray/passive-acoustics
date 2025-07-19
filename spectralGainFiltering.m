% Frequency domain filtering with spectral gain

%% Set up
% File loading
load("ballastFingerprint.mat")
addpath('D:\audio data\2024 angus1\segmented')
audioFile = '20240201_000000'; % DO NOT CHANGE
[signal, Fs] = audioread([audioFile '.wav']);

% Parameters
window = blackman(1024);
noverlap = 512;
nfft = 2048;

% Structure nameing
fpStruct = specFP;

%% Computations
% Starting spectrogram
timestampOI = fpStruct.samples{1};
[blSegment, mSegment] = audioSegmentBLMotor(signal, Fs, timestampOI, 6, 6);

[S, F, T] = spectrogram(mSegment, window, noverlap, nfft, Fs);
[SBase, FBase, TBase] = spectrogram(blSegment, window, noverlap, nfft, Fs);

% Gain calcs
gain = 1 ./ (1 + exp(fpStruct.fingerprint));  % Soft suppression
gain = gain / max(gain);  % Normalize

% Applying gain
S_filtered = S .* gain';  

% Recon signal
sig_filtered = istft(S_filtered, Fs, 'Window', window, 'OverlapLength', noverlap, 'FFTLength', nfft);

%% Qualitative 
% Visualizations
figure;
numPlots = 3;

% Originial motor spec
originalMotor = subplot(numPlots,1,1);
imagesc(T, F, 10*log10(abs(S)));
axis xy;
ylabel('Frequency (Hz)');
title('Original Ballast Pump Spectrogram');
colormap('spring');

% Baseline spec
baselinePlot = subplot(numPlots,1,2);
imagesc(TBase, FBase, 10*log10(abs(SBase)));
axis xy;
ylabel('Frequency (Hz)');
title('Background Noise');
colormap('spring');

% Filtered spec
filteredSpec = subplot(numPlots,1,3);
imagesc(T, F, 10*log10(abs(S_filtered)));
axis xy;
ylabel('Frequency (Hz)');
title('Filtered Ballast Pump Spectrogram');
colormap('spring');

% Statistics