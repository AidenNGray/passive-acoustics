% Loading flight and audio data from dbdProcessingAll.m
load('C:\Users\graya\MATLAB\Projects\passive-acoustics\labsimtests\simest\simestProcessedAll.mat') %dbd mat data
addpath(genpath('labsimtests')) % audio path
audioFile = 'sim_eastern001';

% Audio Parameters
windowLength = 256;
overlap = round(0.5 * windowLength);
nfft = windowLength;

% Audio importing
fid = fopen([audioFile '.log'], 'r');
firstLine = fgetl(fid);
fclose(fid);

tokens = regexp(firstLine, '^(\d+),', 'tokens');
unixTime = str2double(tokens{1}{1});
startTime = datetime(unixTime, 'ConvertFrom', 'posixtime');

[yMono, Fs] = audioread([audioFile '.wav']);
if size(yMono, 2) > 1
    yMono = mean(yMono, 2);  % Convert stereo to mono
end

[S, F, T] = spectrogram(yMono, windowLength, overlap, nfft, Fs);
dmonTime = startTime + seconds(T);

% Pulling flight data
flightTime = flightDataAll.m_present_time;
ballastMotor = flightDataAll.m_is_ballast_pump_moving;
pitchMotor = flightDataAll.m_is_battpos_moving;
airPump = flightDataAll.m_air_pump;

% Cleaning data
ballastMotor(isnan(ballastMotor)) = 0;
pitchMotor(isnan(pitchMotor)) = 0;
airPump(isnan(airPump)) = 0;

offsetHours = 0;
offsetMinutes = 14;
offsetSeconds = 25;
offsetDirection = -1; % 1 or -1

offsetTotal = (offsetHours * 3600 + offsetMinutes * 60 + offsetSeconds) * offsetDirection;
flightTime = datetime(flightTime + offsetTotal,'ConvertFrom','posixtime');

[orderFlightTime, sortIdx] = sort(flightTime);

% Plotting glider data
numPlots = 4;

figure;
balPlot = subplot(numPlots,1,1);
pl1 = plot(orderFlightTime,ballastMotor(sortIdx), 'Color', 'red');
ylim([0 1.2])
ylabel('Ballast Moving')

pitchPlot = subplot(numPlots,1,2);
plot(orderFlightTime,pitchMotor(sortIdx));
ylim([0 1.2])
ylabel('Pitch Moving')

airPlot = subplot(numPlots,1,3);
plot(orderFlightTime, airPump(sortIdx), 'g');
ylim([0 1.2])
ylabel('Air Pump')

% Plotting audio data

audioPlot = subplot(numPlots,1,4);
imagesc(dmonTime, F, 10*log10(abs(S)));
axis xy;
ylabel('Frequency (Hz)');
title('Spectrogram with Datetime X-Axis');
%colorbar;
colormap('parula');

% 1 x axis
linkaxes([balPlot, pitchPlot, airPlot, audioPlot], 'x')