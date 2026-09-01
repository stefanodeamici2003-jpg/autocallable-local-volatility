function [risk_results, Z_all, paths_all, bumps_all] = run_risk_pipeline(...
    mkt, ts, dates, calib_params, N_PATHS_GREEK, NT_MC, BUMP_FRAC, K_atmf_3Y, Z_95)
% RUN_RISK_PIPELINE Computes Greeks for all instruments under the LV model across three dates.
%
%   INPUTS:
%       mkt           - Cell array of market data structures
%       ts            - Struct containing contract term sheet specifications
%       dates         - Struct containing dates (calib_dates, div_dates, obs_dates, maturity, T_obs)
%       calib_params  - Struct containing PDE and fixed-point calibration parameters
%       N_PATHS_GREEK - Number of Monte Carlo simulation paths for Greeks computation
%       NT_MC         - Number of Monte Carlo time steps
%       BUMP_FRAC     - Bump fraction size (e.g. 0.01 for 1%)
%       K_atmf_3Y     - 3-year ATM forward strike
%       Z_95          - 95% confidence interval multiplier
%
%   OUTPUTS:
%       risk_results - Cell array of Greeks structures for each valuation date
%       Z_all        - Cell array of random numbers used for path simulations (one per date)
%       paths_all    - Cell array of pre-simulated path structures (one per date)
%       bumps_all    - Cell array of bumps structures (one per date)

    base_dir = fileparts(fileparts(mfilename('fullpath')));
    
    fprintf('\n%s\n  RISK MANAGEMENT — GREEKS (bump = %.0f%%)\n%s\n', repmat('=',1,60), BUMP_FRAC*100, repmat('=',1,60));

    T_obs = dates.T_obs;
    
    % Pre-allocate cell arrays for parfor sliced variables
    risk_results = cell(3, 1);
    Z_all        = cell(3, 1);
    paths_all    = cell(3, 1);
    bumps_all    = cell(3, 1);

    % Pre-generate CRN matrices on the client (deterministic given the rng seed)
    for i = 1:3
        T_i      = T_obs(i,3);
        tg_i     = sort(unique([linspace(0, T_i, NT_MC+1), mkt{i}.div_dates(:)', T_obs(i,:)]'));
        Z_all{i} = randn(N_PATHS_GREEK, numel(tg_i)-1);
    end

    parfor i = 1:3
        addpath(genpath(base_dir));

        m       = mkt{i};
        ts_i    = ts;
        ts_i.T1 = T_obs(i,1);
        ts_i.T2 = T_obs(i,2);
        ts_i.T3 = T_obs(i,3);

        Z = Z_all{i};   % sliced input, no randn inside parfor

        calib_params_i = struct('sigma_atm', calib_params.sigma_atm, 'ttm', m.ttm, 'tol', calib_params.tol, ...
            'max_iter', calib_params.max_iter, 'Ny', calib_params.Ny, 'Nt', calib_params.Nt, 'n_nodes', calib_params.n_nodes);

        [g_res, p_shared, b_shared] = compute_risk(m, ts_i, calib_params_i, ...
            N_PATHS_GREEK, NT_MC, BUMP_FRAC, Z, K_atmf_3Y, T_obs(i,3));
        risk_results{i} = g_res;
        paths_all{i}    = p_shared;
        bumps_all{i}    = b_shared;
    end

    % Serial loop for sequential console printing
    for i = 1:3
        ts_i    = ts;
        ts_i.T1 = T_obs(i,1);
        ts_i.T2 = T_obs(i,2);
        ts_i.T3 = T_obs(i,3);
        print_risk_all_instruments(risk_results{i}, mkt{i}, ts_i, Z_95);
    end
end
