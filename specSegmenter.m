function [bgSegment, motorSegment] = specSegmenter(timeVec, timestamp, forward, back)
%AUDIOSEGMENT Takes signal & timestamp, returns BL & Motor segments
%   Detailed explanation goes here
centerTime = timestamp; % end of baseline/start of motor
startTime = centerTime - seconds(back);  % start of baseline
endTime = centerTime + seconds(forward);    % end of motor

startSample = floor(startTime * sRate) + 1;
centerSample = floor(centerTime * sRate);
endSample = floor(endTime * sRate);

bgSegment = timeVec(startSample:centerSample);
motorSegment = timeVec(centerSample:endSample);
end