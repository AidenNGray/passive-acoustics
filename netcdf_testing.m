% Specify the NetCDF file
filename = 'glider_ANGUS_glider_1_240201_001028.nc';

% Open the NetCDF file
ncid = netcdf.open(filename, 'NOWRITE');

% Get information about the file
[ndims, nvars, ngatts, unlimdimid] = netcdf.inq(ncid);

% Loop through all variables and read their data
for varid = 0:nvars-1
    % Get variable name and details
    [varname, xtype, dimids, natts] = netcdf.inqVar(ncid, varid);
    
    % Read the variable data
    data = netcdf.getVar(ncid, varid);
    
    % Display variable name and data (optional)
    fprintf('Variable: %s\n', varname);
    %disp(data);
end

% Close the NetCDF file
netcdf.close(ncid);
