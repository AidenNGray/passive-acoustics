%% Loading flight and audio data from dbdProcessingAll.m
load('angusJan24FlightAll.mat') %dbd mat data
addpath(genpath('labsimtests')) % audio path
addpath('D:\audio data\2024 angus1\segmented')
audioFile = '20240201_000000';

flightDataAll = angusJan24FlightData;

%%
% Audio Parameters
windowLength = 256;
overlap = round(0.5 * windowLength);
nfft = windowLength;

% Audio importing

% fid = fopen([audioFile '.log'], 'r');
% firstLine = fgetl(fid);
% fclose(fid);
% 
% tokens = regexp(firstLine, '^(\d+),', 'tokens');
% unixTime = str2double(tokens{1}{1});
% startTime = datetime(unixTime, 'ConvertFrom', 'posixtime');

startTime = datetime(audioFile,"InputFormat","yyyyMMdd_HHmmss");

[yMono, Fs] = audioread([audioFile '.wav']);
if size(yMono, 2) > 1
    yMono = mean(yMono, 2);  % Convert stereo to mono
end

[S, F, T] = spectrogram(yMono, windowLength, overlap, nfft, Fs);
dmonTime = startTime + seconds(T);

%%
% Pulling flight data
flightTime = flightDataAll.m_present_time;
ballastMotor = flightDataAll.m_is_ballast_pump_moving;
pitchMotor = flightDataAll.m_is_battpos_moving;
airPump = flightDataAll.m_air_pump;

% Cleaning data
ballastMotor(isnan(ballastMotor)) = 0;
pitchMotor(isnan(pitchMotor)) = 0;
airPump(isnan(airPump)) = 0;

offsetHours = 1;
offsetMinutes = 39;
offsetSeconds = 41.503;
offsetDirection = 1; % 1 or -1

offsetTotal = (offsetHours * 3600 + offsetMinutes * 60 + offsetSeconds) * offsetDirection;
flightTime = datetime(flightTime + offsetTotal,'ConvertFrom','posixtime');

%[orderFlightTime, sortIdx] = sort(flightTime); % Need if struct unordered

% Bound flight data to audio segment
[~, begin] = min(abs(flightTime - startTime));
[~, stop] = min(abs(flightTime - dmonTime(end)));

%%
% Plotting glider data
numPlots = 4;

figure;
pitchPlot = subplot(numPlots,1,1);
plot(flightTime(begin:stop), pitchMotor(begin:stop));
ylim([0 1.2])
ylabel('Pitch Moving')

airPlot = subplot(numPlots,1,2);
plot(flightTime(begin:stop), airPump(begin:stop), 'g');
ylim([0 1.2])
ylabel('Air Pump')

balPlot = subplot(numPlots,1,3);
pl1 = plot(flightTime(begin:stop), ballastMotor(begin:stop), 'r');
ylim([0 1.2])
ylabel('Ballast Moving')

% Plotting audio data

audioPlot = subplot(numPlots,1,4);
imagesc(dmonTime, F, 10*log10(abs(S)));
axis xy;
ylabel('Frequency (Hz)');
title('Spectrogram with Datetime X-Axis');
colorbar;
colormap('spring');
xlim([flightTime(begin) flightTime(stop)])

% 1 x axis
linkaxes([balPlot, pitchPlot, airPlot, audioPlot], 'x')

%% Looking at important spectrums

