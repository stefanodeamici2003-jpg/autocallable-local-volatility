function [profile_cert, profile_van] = compute_risk_profile(mkt, ts, spot_grid, calib_params, ...
    N_paths, Nt, bump_frac, Z, K_vanilla, T_vanilla)
% COMPUTE_RISK_PROFILE Vega and dividend sensitivity vs spot level.
%
% The function computes the autocallable profile and one or several vanilla
% put profiles. All vanilla candidates reuse the same bumped MC paths for a
% given spot level, so adding candidates does not add simulations.

base_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));

T         = ts.T3;
t_extra   = [ts.T1, ts.T2, ts.T3];
t_grid    = sort(unique([linspace(0, T, Nt+1), mkt.div_dates(:)', t_extra]'));
ssdf_vec  = [mkt.ssdf.y2026; mkt.ssdf.y2027; mkt.ssdf.y2028];
spot_grid = spot_grid(:)';
n_spot    = numel(spot_grid);

K_vanilla = K_vanilla(:);
T_vanilla = T_vanilla(:);
n_vanilla = numel(K_vanilla);
assert(numel(T_vanilla) == n_vanilla, ...
    'K_vanilla and T_vanilla must have the same length.');

idx_T_van = zeros(n_vanilla, 1);
for j = 1:n_vanilla
    [~, idx_T_van(j)] = min(abs(t_grid - T_vanilla(j)));
end

vega            = zeros(1, n_spot);
vega_se         = zeros(1, n_spot);
div_sens        = zeros(3, n_spot);
div_sens_se     = zeros(3, n_spot);
vega_van        = zeros(n_vanilla, n_spot);
vega_van_se     = zeros(n_vanilla, n_spot);
div_sens_van    = zeros(3, n_spot, n_vanilla);
div_sens_van_se = zeros(3, n_spot, n_vanilla);

bump_ssdf = bump_frac * ssdf_vec;

parfor k = 1:n_spot
    addpath(genpath(base_dir));
    S_k = spot_grid(k);

    fwd_k = compute_forward(S_k, mkt.d, mkt.div_dates, calib_params.ttm);

    [sig_sup_k, K_sup_k] = calibrate_lv(mkt.smile.moneyness, ...
        mkt.smile.iv + bump_frac, S_k, fwd_k, ...
        calib_params.sigma_atm + bump_frac, calib_params.ttm, ...
        mkt.d, mkt.div_dates, calib_params.n_nodes, ...
        calib_params.tol, calib_params.max_iter, ...
        calib_params.Ny, calib_params.Nt, false);
    S_sup = simulate_lv_paths_MC(S_k, K_sup_k, sig_sup_k, ...
        T, Nt, mkt.div_dates, mkt.d, N_paths, false, Z, t_extra);

    [sig_sdown_k, K_sdown_k] = calibrate_lv(mkt.smile.moneyness, ...
        mkt.smile.iv - bump_frac, S_k, fwd_k, ...
        calib_params.sigma_atm - bump_frac, calib_params.ttm, ...
        mkt.d, mkt.div_dates, calib_params.n_nodes, ...
        calib_params.tol, calib_params.max_iter, ...
        calib_params.Ny, calib_params.Nt, false);
    S_sdown = simulate_lv_paths_MC(S_k, K_sdown_k, sig_sdown_k, ...
        T, Nt, mkt.div_dates, mkt.d, N_paths, false, Z, t_extra);

    payoff_cert = @(S, tg) payoff_autocallable(S, tg, ts);
    [vk, vk_se] = sens_from_paths(payoff_cert, S_sup, S_sdown, t_grid, bump_frac);
    vega(k)    = vk;
    vega_se(k) = vk_se;

    vega_van_k    = zeros(n_vanilla, 1);
    vega_van_se_k = zeros(n_vanilla, 1);
    for j = 1:n_vanilla
        K_j   = K_vanilla(j);
        idx_j = idx_T_van(j);
        put_fn = @(S, ~) max(K_j - S(:, idx_j), 0);
        [vega_van_k(j), vega_van_se_k(j)] = sens_from_paths( ...
            put_fn, S_sup, S_sdown, t_grid, bump_frac);
    end
    vega_van(:, k)    = vega_van_k;
    vega_van_se(:, k) = vega_van_se_k;

    ds_k        = zeros(3, 1);
    ds_se_k     = zeros(3, 1);
    ds_van_k    = zeros(3, n_vanilla);
    ds_van_se_k = zeros(3, n_vanilla);

    for i = 1:3
        ssdf_u = ssdf_vec; ssdf_u(i) = ssdf_u(i) + bump_ssdf(i);
        ssdf_d = ssdf_vec; ssdf_d(i) = ssdf_d(i) - bump_ssdf(i);
        d_u    = bootstrap_dividends(S_k, ssdf_u);
        d_d    = bootstrap_dividends(S_k, ssdf_d);
        S_dup   = simulate_lv_paths_MC(S_k, mkt.nodes_K, mkt.sigma_nodes, ...
            T, Nt, mkt.div_dates, d_u, N_paths, false, Z, t_extra);
        S_ddown = simulate_lv_paths_MC(S_k, mkt.nodes_K, mkt.sigma_nodes, ...
            T, Nt, mkt.div_dates, d_d, N_paths, false, Z, t_extra);

        [ds_k(i), ds_se_k(i)] = sens_from_paths( ...
            payoff_cert, S_dup, S_ddown, t_grid, bump_ssdf(i));

        for j = 1:n_vanilla
            K_j   = K_vanilla(j);
            idx_j = idx_T_van(j);
            put_fn = @(S, ~) max(K_j - S(:, idx_j), 0);
            [ds_van_k(i, j), ds_van_se_k(i, j)] = sens_from_paths( ...
                put_fn, S_dup, S_ddown, t_grid, bump_ssdf(i));
        end
    end

    div_sens(:, k)        = ds_k;
    div_sens_se(:, k)     = ds_se_k;
    div_sens_van(:, k, :)    = reshape(ds_van_k, 3, 1, n_vanilla);
    div_sens_van_se(:, k, :) = reshape(ds_van_se_k, 3, 1, n_vanilla);
end

profile_cert.spot_grid   = spot_grid;
profile_cert.spot_t0     = mkt.spot;
profile_cert.vega        = vega;
profile_cert.vega_se     = vega_se;
profile_cert.div_sens    = div_sens;
profile_cert.div_sens_se = div_sens_se;

profile_van.spot_grid = spot_grid;
profile_van.strike    = K_vanilla;
profile_van.maturity  = T_vanilla;
profile_van.vega      = vega_van;
profile_van.vega_se   = vega_van_se;

if n_vanilla == 1
    profile_van.div_sens    = div_sens_van(:, :, 1);
    profile_van.div_sens_se = div_sens_van_se(:, :, 1);
else
    profile_van.div_sens    = div_sens_van;
    profile_van.div_sens_se = div_sens_van_se;
end
end
