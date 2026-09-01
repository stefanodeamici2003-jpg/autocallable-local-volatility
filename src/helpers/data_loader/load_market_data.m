function data = load_market_data(filename)
% Load spot, vol smile and SSDF from a project Excel file.
% INPUTS: filename - string, path to .xlsx market data file
% OUTPUTS: data     - struct with fields: date, spot, ttm,
%                    smile.{moneyness, iv}, ssdf.{y2026, y2027, y2028}

[~, data.date, ~] = fileparts(filename);

spot_raw         = readmatrix(filename, 'Sheet', 'Spot',  'OutputType', 'double');
data.spot        = spot_raw(1);

vol_raw               = readmatrix(filename, 'Sheet', 'Vol', 'OutputType', 'double');
data.ttm              = vol_raw(1, 2);
data.smile.moneyness  = vol_raw(2:end, 1);
data.smile.iv         = vol_raw(2:end, 2);

ssdf_raw        = readmatrix(filename, 'Sheet', 'SSDF', 'OutputType', 'double');
data.ssdf.y2026 = ssdf_raw(1, 2);
data.ssdf.y2027 = ssdf_raw(2, 2);
data.ssdf.y2028 = ssdf_raw(3, 2);

end
