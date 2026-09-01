function [fair_coupon, price, se_coupon] = solve_fair_coupon(spot, nodes_K, sigma_nodes, ts, NT_MC, iv_atm, div_dates, d, N_PATHS, t_extra)
% SOLVE_FAIR_COUPON Solves for the fair coupon rate of an Autocallable Reverse Convertible.
%
%   Supports pricing under either the Local Volatility (LV) model (by passing 
%   non-empty nodes_K and sigma_nodes) or the Black-Scholes (BS) model (by 
%   passing a constant iv_atm and empty grid variables).
%
%   INPUTS:
%       spot        - Spot price of the underlying asset
%       nodes_K     - Price grid nodes for Local Volatility (empty if BS model)
%       sigma_nodes - Local volatility values at nodes (empty if BS model)
%       ts          - Term structure structure
%       NT_MC       - Number of Monte Carlo time steps
%       iv_atm      - Constant volatility for BS model (empty if LV model)
%       div_dates   - Ex-dividend dates (in years from valuation date)
%       d           - Sequential proportional dividend ratios
%       N_PATHS     - Number of simulation paths
%       t_extra     - Observation time grid dates (e.g. autocall times)
%
%   OUTPUTS:
%       fair_coupon - Solved coupon rate (p.a.) s.t. E[Payoff] = Notional
%       price       - Price under the fair coupon (should be close to Notional)
%       se_coupon   - Standard error of the MC price under the fair coupon

    % Handle optional arguments
    if nargin < 10
        t_extra = [];
    end

    % Simulate asset paths
    [S_paths, sim_dates] = simulate_paths_MC( ...
        spot, nodes_K, sigma_nodes, ts.T3, NT_MC, iv_atm, ...
        div_dates, d, N_PATHS, true, t_extra);

    % Solve for fair coupon using fzero: E[payoff(c)] = notional
    fair_coupon = fzero(@(c) mean(payoff_autocallable(S_paths, sim_dates, ...
        setfield(ts, 'coupon_rate', c))) - ts.notional, [0.01, 0.50]);

    % Calculate price and standard error under the fair coupon
    payoffs_fair = payoff_autocallable(S_paths, sim_dates, setfield(ts, 'coupon_rate', fair_coupon));
    price = mean(payoffs_fair);
    se_coupon = std(payoffs_fair) / sqrt(N_PATHS);
end
