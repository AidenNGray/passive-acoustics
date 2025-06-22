file_name = 'sim_eastern001';

% [y, Fs] = audioread([file_name '.wav']);
% t = (0:length(y)-1) / Fs;
% plot(t, y);
% xlabel('Time (seconds)');
% ylabel('Amplitude');
% title(['Waveform of ' file_name '.wav']);

% Parameters
windowLength = 512;
overlap = round(0.5 * windowLength);
nfft = windowLength;

% Auto
figure;
spectrogram(y, windowLength, overlap, nfft, Fs, 'yaxis');
title('Spectrogram of Audio File');

% Manual w/ datetime
figure;
fid = fopen([file_name '.log'], 'r');
firstLine = fgetl(fid);
fclose(fid);

tokens = regexp(firstLine, '^(\d+),', 'tokens');
unixTime = str2double(tokens{1}{1});
startTime = datetime(unixTime, 'ConvertFrom', 'posixtime');

[yMono, ~] = audioread([file_name '.wav']);
if size(yMono, 2) > 1
    yMono = mean(yMono, 2);  % Convert stereo to mono
end

[S, F, T] = spectrogram(yMono, windowLength, overlap, nfft, Fs);

timeVec = startTime + seconds(T);

imagesc(timeVec, F, 10*log10(abs(S)));
axis xy;
xlabel('Time');
ylabel('Frequency (Hz)');
title('Spectrogram with Datetime X-Axis');
colorbar;
colormap('parula');
