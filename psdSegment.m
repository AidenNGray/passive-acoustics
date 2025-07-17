function [psdMotor, fMotor, psdBG, fBG] = psdSegment(signal, sRate, psdPar, timestamp, forward, back)
%psdSegment Computes power spectral density of motor and background
%   Assumes motor and background noise are sequential. Motor is 'forward'
%   seconds after 'timestamp' and BG is 'back' seconds prior. Timestamp
%   passed as 'HH:mm:ss'.

%% Segment audio signal

dur = duration(timestamp);
centerTime = seconds(dur); % end of baseline / start of motor

startTime = centerTime - back;  % start of baseline
endTime = centerTime + forward;    % end of motor

startSample = floor(startTime * sRate) + 1;
centerSample = floor(centerTime * sRate);
endSample = floor(endTime * sRate);

bgSegment = signal(startSample:centerSample);
motorSegment = signal(centerSample:endSample);

%% PSD computation
% parameters
window = psdPar.window;
noverlap = psdPar.noverlap;
nfft = psdPar.nfft;

% calculations
[psdBG, fBG] = pwelch(bgSegment, window, noverlap, nfft, sRate); % baseline
[psdMotor, fMotor] = pwelch(motorSegment, window, noverlap, nfft, sRate); % motor

end