function [best, scores] = select_optimal_vanilla_l2(profile_cert, profile_van, ...
    N_CERT, spot_t0, grid_T_fwd, w)
% SELECT_OPTIMAL_VANILLA_L2 Select vanilla hedge by weighted L2 residuals.
%
% For each candidate put, the Portfolio-D hedge is built at S0 and then kept
% fixed across the spot grid. The selected candidate minimizes:
%   Lw_total = Lw_vega + Lw_div
%
% with:
%   Lw_vega = sqrt(sum(w .* net_vega.^2))
%   Lw_div  = sqrt(sum(w .* sum(net_div.^2, 1)))

spot_grid    = profile_cert.spot_grid(:)';
[~, idx_s0]  = min(abs(spot_grid - spot_t0));
w            = w(:)';
cert_vega    = profile_cert.vega(:)';
cert_ds      = profile_cert.div_sens;
cert_vega_t0 = cert_vega(idx_s0);
cert_ds_t0   = cert_ds(:, idx_s0);

n_candidates = numel(profile_van.strike);
n_spot       = numel(spot_grid);

scores.h_van     = zeros(n_candidates, 1);
scores.h_ssdf    = zeros(3, n_candidates);
scores.net_vega  = zeros(n_candidates, n_spot);
scores.net_div   = zeros(3, n_spot, n_candidates);
scores.moneyness = zeros(n_candidates, 1);
scores.Lw_vega   = zeros(n_candidates, 1);
scores.Lw_div    = zeros(n_candidates, 1);
scores.Lw_total  = zeros(n_candidates, 1);

best = struct('strike', NaN, 'maturity', NaN, 'moneyness', NaN, ...
    'Lw_vega', NaN, 'Lw_div', NaN, 'Lw_total', inf);

for c = 1:n_candidates
    van_vega = profile_van.vega(c, :);
    van_ds   = profile_van.div_sens(:, :, c);

    h_van  = -N_CERT * cert_vega_t0 / van_vega(idx_s0);
    h_ssdf = -N_CERT * cert_ds_t0 - h_van * van_ds(:, idx_s0);

    net_vega = N_CERT * cert_vega + h_van * van_vega;
    net_div  = N_CERT * cert_ds + h_ssdf + h_van * van_ds;

    Lw_vega  = sqrt(sum(w .* net_vega.^2));
    Lw_div   = sqrt(sum(w .* sum(net_div.^2, 1)));
    Lw_total = Lw_vega + Lw_div;

    fwd_m = grid_T_fwd(abs(grid_T_fwd(:, 1) - profile_van.maturity(c)) < 1e-9, 2);
    mny   = profile_van.strike(c) / fwd_m(1);

    scores.h_van(c)        = h_van;
    scores.h_ssdf(:, c)    = h_ssdf;
    scores.net_vega(c, :)  = net_vega;
    scores.net_div(:, :, c) = net_div;
    scores.moneyness(c)    = mny;
    scores.Lw_vega(c)      = Lw_vega;
    scores.Lw_div(c)       = Lw_div;
    scores.Lw_total(c)     = Lw_total;

    if Lw_total < best.Lw_total
        best.strike    = profile_van.strike(c);
        best.maturity  = profile_van.maturity(c);
        best.moneyness = mny;
        best.Lw_vega   = Lw_vega;
        best.Lw_div    = Lw_div;
        best.Lw_total  = Lw_total;
    end
end
end
