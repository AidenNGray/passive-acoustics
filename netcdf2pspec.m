
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

    ballastSegments(n).blSpectrum = mean(blSpectrogram, 1);
    ballastSegments(n).motorSpectrum = mean(motorSpectrogram, 1);
end

%% Ballast pump computations & stats


