function g = compute_greeks_vanilla(S_base, S_up, S_down, S_sup, S_sdown, ...
    S_dup, S_ddown, t_grid, K, T_target, bumps)
% COMPUTE_GREEKS_VANILLA Greeks for a vanilla put from pre-simulated paths.
% No internal simulation, so it can be re-evaluated cheaply over many (K, T)
% candidates during the Portfolio D search.
% INPUTS: S_*      - pre-simulated path matrices (N_paths×M)
%         t_grid   - shared time grid
%         K        - strike in EUR
%         T_target - maturity in years (must be <= max(t_grid))
%         bumps    - struct: .spot (EUR), .sigma (pp), .ssdf (3×1 EUR)
%
% OUTPUTS: g        - struct with fields:
%                      .price, .price_se
%                      .delta, .delta_se
%                      .vega, .vega_se
%                      .div_sens (3×1), .div_sens_se (3×1)

[~, idx_T] = min(abs(t_grid - T_target));
payoff_fn  = @(S, ~) max(K - S(:, idx_T), 0);

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
