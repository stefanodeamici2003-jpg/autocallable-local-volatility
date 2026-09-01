function run_risk_profile_pipeline(mkt, ts, dates, spot_grid, calib_params, N_PATHS_GREEK, NT_MC, ...
    BUMP_FRAC, Z_t0, greeks_t0, vanilla_opt, portfolios, N_CERT, K_atmf_3Y)
% RUN_RISK_PROFILE_PIPELINE Evaluates standalone and portfolio risk profiles across spot grid.
%
%   INPUTS:
%       mkt           - Cell array of market data structures
%       ts            - Struct containing contract term sheet specifications
%       dates         - Struct containing dates (calib_dates, div_dates, obs_dates, maturity, T_obs)
%       spot_grid     - Spot price grid for profiling
%       calib_params  - Struct containing PDE and fixed-point calibration parameters
%       N_PATHS_GREEK - Number of Monte Carlo simulation paths for Greeks computation
%       NT_MC         - Number of Monte Carlo time steps
%       BUMP_FRAC     - Bump fraction size (e.g. 0.01 for 1%)
%       Z_t0          - Random matrix used for simulation at valuation date t0
%       greeks_t0     - Greeks structure evaluated at t0
%       vanilla_opt   - Struct containing optimal vanilla contract parameters and Greeks
%       portfolios    - Struct containing portfolios weights and configurations
%       N_CERT        - Quantity of certificate to hedge (e.g., -200)
%       K_atmf_3Y     - 3-year ATM forward strike

    fprintf('\n%s\n  RISK PROFILE VS SPOT LEVEL\n%s\n', repmat('=',1,60), repmat('=',1,60));

    T_obs = dates.T_obs;
    
    ts_t0 = ts;
    ts_t0.T1 = T_obs(1,1);
    ts_t0.T2 = T_obs(1,2);
    ts_t0.T3 = T_obs(1,3);

    calib_params_t0 = struct('sigma_atm', calib_params.sigma_atm, 'ttm', mkt{1}.ttm, 'tol', calib_params.tol, ...
        'max_iter', calib_params.max_iter, 'Ny', calib_params.Ny, 'Nt', calib_params.Nt, 'n_nodes', calib_params.n_nodes);

    [profile_cert, profile_van_pair] = compute_risk_profile( ...
        mkt{1}, ts_t0, spot_grid, calib_params_t0, N_PATHS_GREEK, NT_MC, ...
        BUMP_FRAC, Z_t0, [K_atmf_3Y; vanilla_opt.strike], ...
        [T_obs(1,3); vanilla_opt.maturity]);

    profile_van.vega        = profile_van_pair.vega(1, :);
    profile_van.vega_se     = profile_van_pair.vega_se(1, :);
    profile_van.div_sens    = profile_van_pair.div_sens(:, :, 1);
    profile_van.div_sens_se = profile_van_pair.div_sens_se(:, :, 1);

    profile_van_opt.vega        = profile_van_pair.vega(2, :);
    profile_van_opt.vega_se     = profile_van_pair.vega_se(2, :);
    profile_van_opt.div_sens    = profile_van_pair.div_sens(:, :, 2);
    profile_van_opt.div_sens_se = profile_van_pair.div_sens_se(:, :, 2);

    % Pin profiles at S0 to exact t0 greeks to remove Monte Carlo grid noise
    [~, idx_s0] = min(abs(spot_grid - mkt{1}.spot));
    profile_cert.vega(idx_s0)            = greeks_t0.cert.vega;
    profile_cert.div_sens(:, idx_s0)     = greeks_t0.cert.div_sens;
    profile_van.vega(idx_s0)             = greeks_t0.vanilla.vega;
    profile_van.div_sens(:, idx_s0)      = greeks_t0.vanilla.div_sens;
    profile_van_opt.vega(idx_s0)         = vanilla_opt.greeks.vega;
    profile_van_opt.div_sens(:, idx_s0)  = vanilla_opt.greeks.div_sens;

    port_profiles = compute_portfolio_profiles(profile_cert, profile_van, portfolios, N_CERT, profile_van_opt);

    plot_risk_profile(port_profiles, spot_grid, ts_t0, mkt{1}.spot, mkt{1}.date);

    % Plot individual instrument standalone profiles
    plot_instrument_profiles(profile_cert, N_CERT, mkt{1}.spot, mkt{1}.date);
end
