function [portfolios, vanilla_opt, spot_grid] = run_hedging_pipeline(...
    mkt, ts, dates, calib_params, N_PATHS_GREEK, NT_MC, BUMP_FRAC, Z_t0, N_CERT, greeks_t0, paths_all, bumps_all)
% RUN_HEDGING_PIPELINE Selects the optimal vanilla hedge and builds Portfolios A, B, C, D.
%
%   INPUTS:
%       mkt           - Cell array of market data structures
%       ts            - Struct containing contract term sheet specifications
%       dates         - Struct containing dates (calib_dates, div_dates, obs_dates, maturity, T_obs)
%       calib_params  - Struct containing PDE and fixed-point calibration parameters
%       N_PATHS_GREEK - Number of Monte Carlo simulation paths for Greeks computation
%       NT_MC         - Number of Monte Carlo time steps
%       BUMP_FRAC     - Bump fraction size (e.g. 0.01 for 1%)
%       Z_t0          - Random matrix used for simulation at valuation date t0
%       N_CERT        - Quantity of certificate to hedge (e.g., -200)
%       greeks_t0     - Greeks structure evaluated at t0
%       paths_all     - Pre-simulated paths structure for all three dates
%       bumps_all     - Struct containing pre-computed bumps for all three dates
%
%   OUTPUTS:
%       portfolios    - Struct containing portfolios A, B, C, D weights and specifications
%       vanilla_opt   - Struct containing optimal vanilla contract parameters and Greeks across dates
%       spot_grid     - Evaluation spot grid (containing S0 exactly) used for risk profiling

    fprintf('\n%s\n  OPTIMAL VANILLA SELECTION\n%s\n', repmat('=',1,60), repmat('=',1,60));

    T_obs = dates.T_obs;

    % Construct a uniform spot grid containing critical levels exactly to avoid noise
    spot_t0 = mkt{1}.spot;
    multipliers = 0.45:0.05:1.20;
    spot_grid = unique([multipliers * spot_t0, spot_t0, ts.barrier_pct * spot_t0, ts.autocall_lvl]);

    ts_t0 = ts;
    ts_t0.T1 = T_obs(1,1);
    ts_t0.T2 = T_obs(1,2);
    ts_t0.T3 = T_obs(1,3);

    calib_params_t0 = struct('sigma_atm', calib_params.sigma_atm, 'ttm', mkt{1}.ttm, 'tol', calib_params.tol, ...
        'max_iter', calib_params.max_iter, 'Ny', calib_params.Ny, 'Nt', calib_params.Nt, 'n_nodes', calib_params.n_nodes);

    % Candidate grid in forward-moneyness
    money_grid = [0.80 0.85 0.90 0.95 1.00 1.05 1.10];
    mat_T      = T_obs(1, 1:3);
    fwd_T      = arrayfun(@(T) compute_forward(mkt{1}.spot, mkt{1}.d, mkt{1}.div_dates, T), mat_T);
    fwd_col    = fwd_T(:);
    [MM, MI]   = meshgrid(money_grid, 1:3);
    K_grid     = MM(:) .* fwd_col(MI(:));
    T_grid     = mat_T(MI(:))';

    [profile_cert_grid, profile_van_grid] = compute_risk_profile( ...
        mkt{1}, ts_t0, spot_grid, calib_params_t0, N_PATHS_GREEK, NT_MC, ...
        BUMP_FRAC, Z_t0, K_grid, T_grid);

    % Risk-neutral lognormal spot weights for the selection metric (Option A).
    % Horizon = certificate life (3Y): we hedge over the product's life, even though
    % the P&L is marked a few days later. sigma = ATMF implied vol at that horizon.
    tau_w   = T_obs(1, 3);
    F_w     = fwd_col(end);
    sigma_w = interp1(mkt{1}.smile.moneyness, mkt{1}.smile.iv, F_w / spot_t0, 'linear', 'extrap');
    w_spot  = lognormal_spot_weights(spot_grid, spot_t0, F_w, sigma_w, tau_w);

    [best, l2_scores] = select_optimal_vanilla_l2(profile_cert_grid, ...
        profile_van_grid, N_CERT, mkt{1}.spot, [mat_T(:), fwd_col], w_spot);

    plot_vanilla_grid_profiles(profile_cert_grid, profile_van_grid, N_CERT, ...
        mkt{1}.spot, [mat_T(:), fwd_col], w_spot, mkt{1}.date, best, l2_scores);

    vanilla_opt_strike            = best.strike;
    [~, vanilla_opt_maturity_idx] = min(abs(T_obs(1,:) - best.maturity));
    vanilla_opt_maturity          = T_obs(1, vanilla_opt_maturity_idx);

    vanilla_opt_greeks = cell(3, 1);
    for i = 1:3
        T_opt_i = T_obs(i, vanilla_opt_maturity_idx);
        vanilla_opt_greeks{i} = compute_greeks_vanilla( ...
            paths_all{i}.S_base, paths_all{i}.S_up, paths_all{i}.S_down, ...
            paths_all{i}.S_sup, paths_all{i}.S_sdown, ...
            paths_all{i}.S_dup, paths_all{i}.S_ddown, paths_all{i}.t_grid, ...
            vanilla_opt_strike, T_opt_i, bumps_all{i});
    end

    vanilla_opt.greeks       = vanilla_opt_greeks{1};
    vanilla_opt.all_greeks   = vanilla_opt_greeks; % Keep all 3 dates
    vanilla_opt.strike       = vanilla_opt_strike;
    vanilla_opt.moneyness    = best.moneyness;
    vanilla_opt.maturity     = vanilla_opt_maturity;
    vanilla_opt.maturity_idx = vanilla_opt_maturity_idx;

    % Build and print portfolios A, B, C, D
    portfolios = build_portfolios(greeks_t0, mkt{1}, ts, N_CERT, vanilla_opt);
end
