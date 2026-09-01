function [greeks, paths_shared, bumps] = compute_risk(mkt, ts, calib_params, N_paths, Nt, ...
    bump_frac, Z, K_vanilla, T_vanilla)
% COMPUTE_RISK Unified risk orchestrator: shares all MC paths and calibrations.
%
% INPUTS: mkt          - struct: spot, nodes_K, sigma_nodes, d, div_dates,
%                                smile.{moneyness,iv}, ssdf.{y2026,y2027,y2028}
%         ts           - term sheet: strike, barrier, autocall_lvl, coupon_level,
%                                    coupon_rate, notional, T1, T2, T3
%         calib_params - struct: sigma_atm, ttm, tol, max_iter, Ny, Nt, n_nodes
%         N_paths      - integer, MC paths
%         Nt           - integer, MC time steps
%         bump_frac    - scalar, bump size (e.g. 0.01)
%         Z            - N_paths×M pre-generated random matrix
%         K_vanilla    - scalar, vanilla put strike in EUR
%         T_vanilla    - scalar, vanilla put maturity in years
%
% OUTPUTS: greeks       - struct with fields:
%                          .cert    - LV-MC greeks for the autocallable
%                          .vanilla - flat fields (LV-MC) + .bs_mc + .bs_an
%                          .ssdf    - flat fields (LV-MC) + .bs_mc + .bs_an
%         paths_shared - optional struct containing pre-simulated path matrices (for Portfolio D grid search)
%         bumps        - optional struct containing bumps: .spot (EUR), .sigma (pp), .ssdf (3×1 EUR)
%
% All instruments are evaluated on the same shared paths to cut both runtime and
% cross-instrument estimator bias.

T             = ts.T3;
t_extra       = [ts.T1, ts.T2, ts.T3];
t_grid        = sort(unique([linspace(0, T, Nt+1), mkt.div_dates(:)', t_extra]'));
ssdf_vec      = [mkt.ssdf.y2026; mkt.ssdf.y2027; mkt.ssdf.y2028];
bump_abs_spot = bump_frac * mkt.spot;
bump_ssdf_abs = bump_frac * ssdf_vec;

% Shared bumps struct
bumps.spot  = bump_abs_spot;
bumps.sigma = bump_frac;
bumps.ssdf  = bump_ssdf_abs;

% Baseline paths
S_base = simulate_lv_paths_MC(mkt.spot, mkt.nodes_K, mkt.sigma_nodes, ...
    T, Nt, mkt.div_dates, mkt.d, N_paths, false, Z, t_extra);

% Spot-bumped paths (recalibrate forward, dividends and vol surface) — up
spot_up  = mkt.spot + bump_abs_spot;
d_up_s   = bootstrap_dividends(spot_up, ssdf_vec);
fwd_up   = compute_forward(spot_up,  d_up_s,  mkt.div_dates, calib_params.ttm);
[sig_up, K_up] = calibrate_lv(mkt.smile.moneyness, mkt.smile.iv, ...
    spot_up, fwd_up, calib_params.sigma_atm, calib_params.ttm, ...
    d_up_s, mkt.div_dates, calib_params.n_nodes, calib_params.tol, ...
    calib_params.max_iter, calib_params.Ny, calib_params.Nt, false);
S_up = simulate_lv_paths_MC(spot_up, K_up, sig_up, T, Nt, ...
    mkt.div_dates, d_up_s, N_paths, false, Z, t_extra);

spot_down = mkt.spot - bump_abs_spot;
d_down_s  = bootstrap_dividends(spot_down, ssdf_vec);
fwd_down  = compute_forward(spot_down, d_down_s, mkt.div_dates, calib_params.ttm);
[sig_down, K_down] = calibrate_lv(mkt.smile.moneyness, mkt.smile.iv, ...
    spot_down, fwd_down, calib_params.sigma_atm, calib_params.ttm, ...
    d_down_s, mkt.div_dates, calib_params.n_nodes, calib_params.tol, ...
    calib_params.max_iter, calib_params.Ny, calib_params.Nt, false);
S_down = simulate_lv_paths_MC(spot_down, K_down, sig_down, T, Nt, ...
    mkt.div_dates, d_down_s, N_paths, false, Z, t_extra);

% Sigma-bumped paths (IV bump with recalibration)
fwd_base = compute_forward(mkt.spot, mkt.d, mkt.div_dates, calib_params.ttm);

[sig_sup, K_sup] = calibrate_lv(mkt.smile.moneyness, mkt.smile.iv + bump_frac, ...
    mkt.spot, fwd_base, calib_params.sigma_atm + bump_frac, calib_params.ttm, ...
    mkt.d, mkt.div_dates, calib_params.n_nodes, calib_params.tol, ...
    calib_params.max_iter, calib_params.Ny, calib_params.Nt, false);
S_sup = simulate_lv_paths_MC(mkt.spot, K_sup, sig_sup, T, Nt, ...
    mkt.div_dates, mkt.d, N_paths, false, Z, t_extra);

[sig_sdown, K_sdown] = calibrate_lv(mkt.smile.moneyness, mkt.smile.iv - bump_frac, ...
    mkt.spot, fwd_base, calib_params.sigma_atm - bump_frac, calib_params.ttm, ...
    mkt.d, mkt.div_dates, calib_params.n_nodes, calib_params.tol, ...
    calib_params.max_iter, calib_params.Ny, calib_params.Nt, false);
S_sdown = simulate_lv_paths_MC(mkt.spot, K_sdown, sig_sdown, T, Nt, ...
    mkt.div_dates, mkt.d, N_paths, false, Z, t_extra);

% SSDF-bumped paths
S_dup   = cell(3,1);
S_ddown = cell(3,1);
for i = 1:3
    bump_i = bump_frac * ssdf_vec(i);
    ssdf_u = ssdf_vec; ssdf_u(i) = ssdf_u(i) + bump_i;
    ssdf_d = ssdf_vec; ssdf_d(i) = ssdf_d(i) - bump_i;
    d_u = bootstrap_dividends(mkt.spot, ssdf_u);
    d_d = bootstrap_dividends(mkt.spot, ssdf_d);
    S_dup{i}   = simulate_lv_paths_MC(mkt.spot, mkt.nodes_K, ...
        mkt.sigma_nodes, T, Nt, mkt.div_dates, d_u, N_paths, false, Z, t_extra);
    S_ddown{i} = simulate_lv_paths_MC(mkt.spot, mkt.nodes_K, ...
        mkt.sigma_nodes, T, Nt, mkt.div_dates, d_d, N_paths, false, Z, t_extra);
end

% Greeks for every instrument
greeks.cert = compute_greeks_autocall(S_base, S_up, S_down, S_sup, S_sdown, ...
    S_dup, S_ddown, t_grid, ts, bumps);

greeks.vanilla = compute_greeks_vanilla(S_base, S_up, S_down, S_sup, S_sdown, ...
    S_dup, S_ddown, t_grid, K_vanilla, T_vanilla, bumps);

greeks.ssdf = compute_greeks_ssdf(S_base, S_up, S_down, S_sup, S_sdown, ...
    mkt.d, d_up_s, d_down_s, t_grid, mkt.div_dates, bumps);

% Optional outputs for Portfolio D
if nargout > 1
    paths_shared.S_base  = S_base;
    paths_shared.S_up    = S_up;
    paths_shared.S_down  = S_down;
    paths_shared.S_sup   = S_sup;
    paths_shared.S_sdown = S_sdown;
    paths_shared.S_dup   = S_dup;
    paths_shared.S_ddown = S_ddown;
    paths_shared.t_grid  = t_grid;
    paths_shared.sig_sup   = sig_sup;
    paths_shared.K_sup     = K_sup;
    paths_shared.sig_sdown = sig_sdown;
    paths_shared.K_sdown   = K_sdown;
end

end
