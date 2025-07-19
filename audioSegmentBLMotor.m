function [bgSegment, motorSegment] = audioSegmentBLMotor(signal, sRate, timestamp, forward, back)
%AUDIOSEGMENT Takes signal & timestamp, returns BL & Motor segments
%   Detailed explanation goes here
dur = duration(timestamp);
centerTime = seconds(dur); % end of baseline / start of motor

startTime = centerTime - back;  % start of baseline
endTime = centerTime + forward;    % end of motor

startSample = floor(startTime * sRate) + 1;
centerSample = floor(centerTime * sRate);
endSample = floor(endTime * sRate);

bgSegment = signal(startSample:centerSample);
motorSegment = signal(centerSample:endSample);
end