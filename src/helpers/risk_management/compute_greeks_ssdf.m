function g = compute_greeks_ssdf(S_base, S_up, S_down, S_sup, S_sdown, ...
    d_base, d_up_s, d_down_s, t_grid, div_dates, bumps)
% Delta and Vega of the three SSDF contracts from pre-simulated paths.
% INPUTS: S_*       - N_paths×M pre-simulated path matrices
%         d_base    - 3×1, base proportional dividend yields
%         d_up_s    - 3×1, dividend yields at spot_up (re-bootstrapped)
%         d_down_s  - 3×1, dividend yields at spot_down (re-bootstrapped)
%         t_grid    - 1×M time grid in years
%         div_dates - 3×1, dividend ex-dates in year fractions
%         bumps     - struct: .spot (EUR abs), .sigma (pp abs)
% OUTPUTS: g         - struct: .delta (3×1), .delta_se (3×1),
%                             .vega  (3×1), .vega_se  (3×1)
% NOTE:   delta ≈ 0 by construction: SSDF prices are market observables,
%         d_i re-bootstraps to keep SSDF_i fixed when spot moves.
%         vega ≈ 0 by construction: proportional divs independent of vol.

div_step = arrayfun(@(tau) find(abs(t_grid - tau) < 1e-10, 1), div_dates(:)');

g.price    = zeros(3, 1);  g.price_se = zeros(3, 1);
g.delta    = zeros(3, 1);  g.delta_se = zeros(3, 1);
g.vega     = zeros(3, 1);  g.vega_se  = zeros(3, 1);

for i = 1:3
    % Base scale for price and vega
    scale_base = d_base(i) / (1 - d_base(i));
    pf_base    = @(S, ~) scale_base .* S(:, div_step(i));

    [g.price(i), g.price_se(i)] = price_from_paths(pf_base, S_base, t_grid);

    % Delta: use re-bootstrapped scales
    scale_up   = d_up_s(i)   / (1 - d_up_s(i));
    scale_down = d_down_s(i) / (1 - d_down_s(i));
    pay_up     = scale_up   .* S_up(:,   div_step(i));
    pay_down   = scale_down .* S_down(:, div_step(i));
    dd = (pay_up - pay_down) / (2 * bumps.spot);
    g.delta(i)    = mean(dd);
    g.delta_se(i) = std(dd) / sqrt(size(S_base, 1));

    % Vega: scale unchanged
    pf_vega = @(S, ~) scale_base .* S(:, div_step(i));
    [g.vega(i),  g.vega_se(i)]  = sens_from_paths(pf_vega, S_sup, S_sdown, t_grid, bumps.sigma);
end
end