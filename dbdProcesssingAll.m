% Processing dbd or ebd data to a single struct
% Made with AI assistance

% Directory containing ASCII files
dataDir = 'C:\Users\graya\MATLAB\Projects\passive-acoustics\labsimtests\simest';  % <-- Update this!
filePattern = fullfile(dataDir, '*.dbdasc');
fileList = dir(filePattern);

flightDataAll = struct();
varNames = [];

% Loop over all files
for k = 1:length(fileList)
    fileName = fullfile(dataDir, fileList(k).name);
    fid = fopen(fileName, 'r');

    % --- Skip metadata lines ---
    for i = 1:14
        fgetl(fid);
    end

    % --- Read variable names (only from first file) ---
    if isempty(varNames)
        varLine = fgetl(fid);
        varNames = strsplit(strtrim(varLine));
    else
        fgetl(fid);  % still need to skip var line if not using
    end

    % --- Skip data type line ---
    fgetl(fid);
    fgetl(fid);

    % --- Read numeric data ---
    data = textscan(fid, repmat('%f', 1, numel(varNames)), ...
                    'Delimiter', ' ', 'CollectOutput', true);
    fclose(fid);
    
    % --- Append data into combinedData struct ---
    for i = 1:numel(varNames)
        field = matlab.lang.makeValidName(varNames{i});
        vec = data{1}(:, i);
        if isfield(flightDataAll, field)
            flightDataAll.(field) = [flightDataAll.(field); vec];
        else
            flightDataAll.(field) = vec;
        end
    end
end

% --- Remove fields that are entirely NaN ---
fields = fieldnames(flightDataAll);
for i = 1:numel(fields)
    vec = flightDataAll.(fields{i});
    if all(isnan(vec))
        flightDataAll = rmfield(flightDataAll, fields{i});
    end
end

% --- Sort in chonological order ---
[~, sort_idx] = sort(flightDataAll.m_present_time);
flightDataAll = structfun(@(x) x(sort_idx), flightDataAll, 'UniformOutput', false);

