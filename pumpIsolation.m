% Pulling spectrums for each pump/motor MANUALLY

% Loading audio data
addpath('D:\audio data\2024 angus1\segmented')
audioFile = '20240201_000000'; % DO NOT CHANGE

%%
% Audio Parameters
windowLength = 256;
overlap = round(0.5 * windowLength);
nfft = windowLength;

% Audio importing
startTime = datetime(audioFile,"InputFormat","yyyyMMdd_HHmmss");

[yMono, Fs] = audioread([audioFile '.wav']);
if size(yMono, 2) > 1
    yMono = mean(yMono, 2);  % Convert stereo to mono
end

[S, F, T] = spectrogram(yMono, windowLength, overlap, nfft, Fs);
dmonTime = startTime + seconds(T);

%% GUI visualization

testSignal = yMono(1:1e7);
signalAnalyzer(testSignal,'SampleRate',Fs)

%% Baseline segmentation

startHours = 0;
startMinutes = 57;
startSeconds = 37;
endSeconds = 47;

startTime = (startHours*3600) + (startMinutes)*60 + startSeconds;  % seconds
endTime = (startHours*3600) + (startMinutes)*60 + endSeconds;    % seconds

startSample = floor(startTime * Fs) + 1;
endSample = floor(endTime * Fs);

segment = testSignal(startSample:endSample);  % extract audio segment

w = blackman(length(segment)); % Applying window to reduce leakage
windowedSegment = segment .* w;

nfft = 2^nextpow2(length(windowedSegment));  % zero-pad to next power of 2
Y = fft(windowedSegment, nfft);
Ymag = abs(Y(1:nfft/2+1));         % magnitude
f = Fs*(0:(nfft/2))/nfft;          % frequency axis

figure
%hold on
plot(f, 20*log10(Ymag), 'r');           % convert to dB
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title('Spectrum of Ballast Pump')
ylim([-100 0])
grid on

%% Baseline pwelch test
window = hamming(1024);
noverlap = 512;
nfft = 2048;

[pxx, f] = pwelch(yMono, window, noverlap, nfft, Fs);

% Plot in dB
plot(f, 10*log10(pxx));
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
title('Welch Power Spectral Density Estimate');
grid on;

%%  Segments
% Baseline
startHours = 0;
startMinutes = 57;
startSeconds = 37;
endSeconds = 47;

startTime = (startHours*3600) + (startMinutes)*60 + startSeconds;  % seconds
endTime = (startHours*3600) + (startMinutes)*60 + endSeconds;    % seconds

startSample = floor(startTime * Fs) + 1;
endSample = floor(endTime * Fs);

baselineSegment = yMono(startSample:endSample); 

% Ballast
startHours = 0;
startMinutes = 58;
startSeconds = 7;
endSeconds = 13.5;

startTime = (startHours*3600) + (startMinutes)*60 + startSeconds;  % seconds
endTime = (startHours*3600) + (startMinutes)*60 + endSeconds;    % seconds

startSample = floor(startTime * Fs) + 1;
endSample = floor(endTime * Fs);

ballastSegment = yMono(startSample:endSample);  

% Pitch
startHours = 0;
startMinutes = 58;
startSeconds = 25;
endSeconds = 28;

startTime = (startHours*3600) + (startMinutes)*60 + startSeconds;  % seconds
endTime = (startHours*3600) + (startMinutes)*60 + endSeconds;    % seconds

startSample = floor(startTime * Fs) + 1;
endSample = floor(endTime * Fs);

pitchSegment = yMono(startSample:endSample);  

% Air
% startHours = 0;
% startMinutes = 58;
% startSeconds = 25;
% endSeconds = 28;
% 
% startTime = (startHours*3600) + (startMinutes)*60 + startSeconds;  % seconds
% endTime = (startHours*3600) + (startMinutes)*60 + endSeconds;    % seconds
% 
% startSample = floor(startTime * Fs) + 1;
% endSample = floor(endTime * Fs);
% 
% airSegment = yMono(startSample:endSample); 

%% PSD plotting
% parameters
window = blackman(1024);
noverlap = 512;
nfft = 2048;

% calculations
[basePXX, baseF] = pwelch(baselineSegment, window, noverlap, nfft, Fs); % baseline
[ballastPXX, ballastF] = pwelch(ballastSegment, window, noverlap, nfft, Fs); % ballast
[pitchPXX, pitchF] = pwelch(pitchSegment, window, noverlap, nfft, Fs); % pitch
%[airPXX, airF] = pwelch(airSegment, window, noverlap, nfft, Fs); % air

% plotting
figure
hold on;
plot(baseF, 10*log10(basePXX));
plot(ballastF, 10*log10(ballastPXX));
%plot(pitchF, 10*log10(pitchPXX));
%plot(f, 10*log10(pxx));
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
title('Welch Power Spectral Density Estimate');
grid on;
legend('baseline', 'ballast', 'pitch')
ylim([-120 -80])
hold off;

%% Ballast pump segmentation

startHours = 0;
startMinutes = 58;
startSeconds = 7;
endSeconds = 13.5;

startTime = (startHours*3600) + (startMinutes)*60 + startSeconds;  % seconds
endTime = (startHours*3600) + (startMinutes)*60 + endSeconds;    % seconds

startSample = floor(startTime * Fs) + 1;
endSample = floor(endTime * Fs);

segment = testSignal(startSample:endSample);  % extract audio segment

w = blackman(length(segment)); % Applying window to reduce leakage
windowedSegment = segment .* w;

nfft = 2^nextpow2(length(windowedSegment));  % zero-pad to next power of 2
Y = fft(windowedSegment, nfft);
Ymag = abs(Y(1:nfft/2+1));         % magnitude
f = Fs*(0:(nfft/2))/nfft;          % frequency axis

plot(f, 20*log10(Ymag), 'b');           % convert to dB
% xlabel('Frequency (Hz)')
% ylabel('Magnitude (dB)')
% title('Spectrum of Ballast Pump')
% ylim([-100 0])
% grid on

%% Pitch motor segmentation

startHours = 0;
startMinutes = 58;
startSeconds = 25;
endSeconds = 28;

startTime = (startHours*3600) + (startMinutes)*60 + startSeconds;  % seconds
endTime = (startHours*3600) + (startMinutes)*60 + endSeconds;    % seconds

startSample = floor(startTime * Fs) + 1;
endSample = floor(endTime * Fs);

segment = testSignal(startSample:endSample);  % extract audio segment

w = blackman(length(segment)); % Applying window to reduce leakage
windowedSegment = segment .* w;

nfft = 2^nextpow2(length(windowedSegment));  % zero-pad to next power of 2
Y = fft(windowedSegment, nfft);
Ymag = abs(Y(1:nfft/2+1));         % magnitude
f = Fs*(0:(nfft/2))/nfft;          % frequency axis

plot(f, 20*log10(Ymag), 'g');           % convert to dB
% xlabel('Frequency (Hz)')
% ylabel('Magnitude (dB)')
% title('Spectrum of Ballast Pump')
% grid on
hold off
legend('Baseline', 'Ballast', 'Pitch')
