function [time, freq, convSpec] = nc2spec(filename,step)
    if nargin < 2
        step = 1;
    end
    ncObj = easyNC.Reader(filename);
    segmentData = ncObj.read2struct();
    infoStruct = ncObj.info();
    
    [~,~,~,scale,offset,~] = infoStruct.Variables(4).Attributes.Value;
    
    A_flat = segmentData.spectrogram(:);
    A_flat_uint16 = typecast(A_flat, 'uint16');
    uintSpec = reshape(A_flat_uint16, size(segmentData.spectrogram));

    convSpec = double(uintSpec(1:step:end,:)) * scale + offset;

    secSS = segmentData.time(1:step:end);
    [~,~,startTime] = infoStruct.Variables(2).Attributes.Value;
    startDT = datetime(startTime,"InputFormat",'MM/dd/yy HH:mm:ss');
    time = startDT + seconds(secSS);

    freq = segmentData.freq;
    
    %epsilon = 1e-12;
    %power = abs(convSpec).^2;
    %dbSpec = 10*log10(power+epsilon);
end