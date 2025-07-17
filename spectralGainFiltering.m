% Frequency domain filtering with spectral gain

%% Set up
% File loading
load("ballastFingerprint.mat")
addpath('D:\audio data\2024 angus1\segmented')
audioFile = '20240201_000000'; % DO NOT CHANGE

% Parameters
window = blackman(1024);
noverlap = 512;
nfft = 2048;

%% Computations


%% Validation