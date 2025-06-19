% Making dbdasc files usable
% Made with AI assistance

% Directory containing ASCII files
dataDir = 'C:\Users\graya\MATLAB\Projects\passive-acoustics\labsimtests\simest';  % <-- Update this!
filePattern = fullfile(dataDir, '*.dbdasc');  % Adjust extension if needed
fileList = dir(filePattern);

% Master structure to hold everything
flightData = struct();

% Loop over all files
for k = 1:length(fileList)
    fileName = fullfile(dataDir, fileList(k).name);
    fid = fopen(fileName, 'r');
    
    % --- Read and parse metadata (lines 1–14) ---
    meta = struct();
    for i = 1:14
        line = fgetl(fid);
        tokens = regexp(line, '^(.*?):\s*(.*)$', 'tokens');
        if ~isempty(tokens)
            key = matlab.lang.makeValidName(strtrim(tokens{1}{1}));
            value = strtrim(tokens{1}{2});
            meta.(key) = value;
        end
    end
    
    % --- Read variable names (line 15) ---
    varLine = fgetl(fid);
    varNames = strsplit(strtrim(varLine));
    
    % --- Skip data type line (line 16) ---
    fgetl(fid);

    % --- Read numeric data ---
    data = textscan(fid, repmat('%f', 1, numel(varNames)), 'Delimiter', ' ', 'CollectOutput', true);
    fclose(fid);
    
    % --- Store variables in structure ---
    vars = struct();
    for i = 1:numel(varNames)
        field = matlab.lang.makeValidName(varNames{i});
        vars.(field) = data{1}(:, i);
    end

    % --- Remove variables that are entirely NaN ---
    fields = fieldnames(vars);
    for i = 1:numel(fields)
        vec = vars.(fields{i});
        if all(isnan(vec))
            vars = rmfield(vars, fields{i});
        end
    end
    
    % --- Store into main struct under filename key ---
    baseName = sprintf("segment%d",k);
    flightData.(baseName).meta = meta;
    flightData.(baseName).data = vars;
end
