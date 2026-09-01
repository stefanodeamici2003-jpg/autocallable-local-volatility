function g = compute_greeks_autocall(S_base, S_up, S_down, S_sup, S_sdown, ...
    S_dup, S_ddown, t_grid, ts, bumps)
% COMPUTE_GREEKS_AUTOCALL Greeks for the autocallable certificate from pre-simulated paths.
%
% INPUTS: S_*      - pre-simulated path matrices (N_paths×M)
%         t_grid   - shared time grid
%         ts       - term sheet (strike, barrier, coupon_rate, notional, T1,T2,T3)
%         bumps    - struct: .spot (EUR), .sigma (pp), .ssdf (3×1 EUR)
%
% OUTPUTS: g        - struct with fields:
%                      .price, .price_se
%                      .delta, .delta_se
%                      .vega, .vega_se
%                      .div_sens (3×1), .div_sens_se (3×1)

payoff_fn = @(S, tg) payoff_autocallable(S, tg, ts);

% Price
[g.price, g.price_se] = price_from_paths(payoff_fn, S_base, t_grid);

% Delta
[g.delta, g.delta_se] = sens_from_paths(payoff_fn, S_up, S_down, t_grid, bumps.spot);

% Vega parallel
[g.vega, g.vega_se] = sens_from_paths(payoff_fn, S_sup, S_sdown, t_grid, bumps.sigma);

% Dividend sensitivity
g.div_sens    = zeros(3, 1);
g.div_sens_se = zeros(3, 1);
for i = 1:3
    [g.div_sens(i), g.div_sens_se(i)] = sens_from_paths( ...
        payoff_fn, S_dup{i}, S_ddown{i}, t_grid, bumps.ssdf(i));
end
end
