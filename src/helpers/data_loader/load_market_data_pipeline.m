function mkt = load_market_data_pipeline(data_dir)
% LOAD_MARKET_DATA_PIPELINE Loads market spreadsheet files and bootstraps proportional dividends.
%
%   INPUTS:
%       data_dir - Directory containing the Excel market data files
%
%   OUTPUTS:
%       mkt      - Cell array of structures containing loaded spot, smile, ssdf, and dividends

    files = {'05mar2026.xlsx', '06mar2026.xlsx', '09mar2026.xlsx'};
    mkt   = cellfun(@(f) load_market_data(fullfile(data_dir, f)), files, 'UniformOutput', false);

    for i = 1:3
        m = mkt{i};
        mkt{i}.d = bootstrap_dividends(m.spot, [m.ssdf.y2026; m.ssdf.y2027; m.ssdf.y2028]);
    end
end
