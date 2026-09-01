%% 
% Dividend Risk in an Autocallable Reverse Convertible
% Financial Engineering Final Project - 2025/2026
% Authors: Stefano De Amici, Nassim Karimi, Alberto Toia

close all;   % start from a clean figure state so no plot overwrites another

base_dir = fileparts(mfilename('fullpath'));
addpath(genpath(base_dir));
data_dir = fullfile(base_dir, '..', 'Project5_Autocallable', 'Market Data');

% Constants & PDE Specifications
SIGMA_ATM      = 0.255;
N_NODES        = 56;   % selected from node_sweep.m
TOL            = 1e-4;
MAX_ITER       = 150;
NY             = 250;
NT             = 250;
N_PATHS        = 100000;
N_PATHS_GREEK  = 50000;
NT_MC          = 250;
BUMP_FRAC      = 0.01;
Z_95           = 1.96;      % 95% confidence interval multiplier (standard normal)
N_CERT         = -200;
rng(42);   % fixed seed for reproducible Monte Carlo across runs

% 1. Load Contract specifications (Term Sheet)
[ts, dates] = load_term_sheet();

% 2. Load Market Data & bootstrap dividends
mkt = load_market_data_pipeline(data_dir);

% Derive contract parameters that depend on spot price
ts.strike       = mkt{1}.spot;
ts.barrier      = ts.barrier_pct * ts.strike;
ts.autocall_lvl = ts.strike;
ts.coupon_level = ts.coupon_pct * ts.strike;

% Package PDE calibration parameters
calib_params = struct('sigma_atm', SIGMA_ATM, 'tol', TOL, 'max_iter', MAX_ITER, ...
                      'Ny', NY, 'Nt', NT, 'n_nodes', N_NODES, 'ttm', mkt{1}.ttm);

% 3. Calibrate Local Volatility model
mkt = run_calibration_pipeline(mkt, dates, ts, calib_params);

% 4. Monte Carlo pricing & Fair Coupon Solution
[ts, prices] = run_pricing_pipeline(mkt, ts, dates, NT_MC, N_PATHS, Z_95);

% 5. Risk management — Greeks
K_atmf_3Y = compute_forward(mkt{1}.spot, mkt{1}.d, dates.div_dates, dates.maturity);

[risk_results, Z_all, paths_all, bumps_all] = run_risk_pipeline(...
    mkt, ts, dates, calib_params, N_PATHS_GREEK, NT_MC, BUMP_FRAC, K_atmf_3Y, Z_95);

greeks_t0 = risk_results{1};

% 6. Optimal vanilla selection & Portfolio Building
[portfolios, vanilla_opt, spot_grid] = run_hedging_pipeline(...
    mkt, ts, dates, calib_params, N_PATHS_GREEK, NT_MC, BUMP_FRAC, Z_all{1}, N_CERT, greeks_t0, paths_all, bumps_all);

% 7. P&L Explain
pnl = run_pnl_pipeline(portfolios, risk_results, vanilla_opt, mkt, N_CERT);

% 7b. P&L Explain with bid-offer transaction costs
spreads = struct('cert', 0.005, 'van', 0.002, 'ssdf', 0.001, 'spot', 0.0001);
pnl_costs = run_pnl_pipeline_costs(portfolios, risk_results, vanilla_opt, mkt, N_CERT, spreads);

paths_all = [];   % free path matrices before the risk-profile sweep

% 8. Risk Profile vs Spot
run_risk_profile_pipeline(mkt, ts, dates, spot_grid, calib_params, N_PATHS_GREEK, NT_MC, ...
    BUMP_FRAC, Z_all{1}, greeks_t0, vanilla_opt, portfolios, N_CERT, K_atmf_3Y);
