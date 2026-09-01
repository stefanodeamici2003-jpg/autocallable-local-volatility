function mkt = run_calibration_pipeline(mkt, dates, ts, calib_params)
% RUN_CALIBRATION_PIPELINE Calibrates the Local Volatility model for each valuation date.
%
%   INPUTS:
%       mkt          - Cell array of market data structures
%       dates        - Struct containing dates (calib_dates, div_dates, obs_dates, maturity, T_obs)
%       ts           - Struct containing contract term sheet specifications
%       calib_params - Struct containing PDE and fixed-point calibration parameters
%
%   OUTPUTS:
%       mkt          - Cell array of market data structures, updated with sigma_nodes, nodes_K, and div_dates

    base_dir = fileparts(fileparts(mfilename('fullpath')));
    
    fprintf('\n%s\n  LOCAL VOLATILITY CALIBRATION\n%s\n', repmat('=',1,72), repmat('=',1,72));
    
    calib_dates = dates.calib_dates;
    div_dates   = dates.div_dates;
    maturity    = dates.maturity;
    
    parfor i = 1:3
        addpath(genpath(base_dir)); % parallel calibration over independent dates
        
        m = mkt{i};
        tau_divs = yearfrac(calib_dates(i), div_dates, 3);
        forward = compute_forward(m.spot, m.d, div_dates, maturity);

        [sigma_nodes, nodes_K, iters, err_final] = calibrate_lv( ...
            m.smile.moneyness, m.smile.iv, m.spot, forward, calib_params.sigma_atm, m.ttm, ...
            m.d, tau_divs, calib_params.n_nodes, calib_params.tol, calib_params.max_iter, ...
            calib_params.Ny, calib_params.Nt, false, ...
            [ts.barrier; ts.autocall_lvl]);

        fprintf('  <strong>[%s]</strong> Spot: %6.4f EUR | Fwd: %6.4f EUR | Divs: [%.2f%%, %.2f%%, %.2f%%]\n', ...
            m.date, m.spot, forward, m.d(1)*100, m.d(2)*100, m.d(3)*100);
        fprintf('      PDE Grid: %d nodes | Status: <strong>Calibrated</strong> (%d iterations, max err: %.2e)\n', ...
            calib_params.n_nodes, iters, err_final);

        mkt{i}.sigma_nodes = sigma_nodes;
        mkt{i}.nodes_K = nodes_K;
        mkt{i}.div_dates = tau_divs;
    end

    % Checks and plots (serial, figures require main thread)
    fprintf('\n%s\n  LOCAL VOL vs IMPLIED VOL SUMMARY\n%s\n', repmat('=',1,72), repmat('=',1,72));

    % Dedicated figure for the 3 LV subplots: plot_lv uses subplot() without
    % opening a figure, so create one here to avoid drawing over another plot.
    figure('Name', 'Local Volatility Calibration', 'Color', 'w');
    for i = 1:3
        m = mkt{i};
        nodes_X = log(m.nodes_K);
        K_check = [m.spot; 0.70*m.spot; 1.30*m.spot];
        sigma_check = eval_lv(K_check, nodes_X, m.sigma_nodes);
        iv_check = interp1(m.smile.moneyness, m.smile.iv, [1.00; 0.70; 1.30]);
        fprintf('  <strong>[%s]</strong>\n', m.date);
        fprintf('    sigma_LV:  ATM = %5.2f%%  |  70%% Strike = %5.2f%%  |  130%% Strike = %5.2f%%\n', ...
            sigma_check(1)*100, sigma_check(2)*100, sigma_check(3)*100);
        fprintf('    Mkt IV:    ATM = %5.2f%%  |  70%% Strike = %5.2f%%  |  130%% Strike = %5.2f%%\n', ...
            iv_check(1)*100, iv_check(2)*100, iv_check(3)*100);

        [K_calib, IV_mkt] = convert_smile_to_strikes(m.smile.moneyness, m.smile.iv, m.spot);
        plot_lv(m.nodes_K, m.sigma_nodes, K_calib, IV_mkt, m.date, i);
    end
end
