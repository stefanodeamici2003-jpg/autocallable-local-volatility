function [sens, sens_se] = sens_from_paths(payoff_fn, S_plus, S_minus, t_grid, bump)
% SENS_FROM_PATHS Central-difference sensitivity and MC standard error from bumped paths.
% Shared by delta (spot bump), vega (vol bump) and dividend sensitivity (SSDF bump):
% the estimator is identical, only the bumped parameter and units differ.
% INPUTS: payoff_fn - function handle @(S, t_grid) -> N_paths×1 payoffs
%         S_plus    - paths simulated at the up-bumped parameter
%         S_minus   - paths simulated at the down-bumped parameter
%         t_grid    - 1×M actual time grid in years
%         bump      - scalar, absolute bump size (same units as the parameter)
% OUTPUTS: sens      - scalar, central-difference sensitivity dV/dparam
%         sens_se   - scalar, Monte Carlo standard error of the estimate

pay_plus  = payoff_fn(S_plus,  t_grid);
pay_minus = payoff_fn(S_minus, t_grid);
d         = (pay_plus - pay_minus) / (2 * bump);
sens      = mean(d);
sens_se   = std(d) / sqrt(size(S_plus, 1));
end
