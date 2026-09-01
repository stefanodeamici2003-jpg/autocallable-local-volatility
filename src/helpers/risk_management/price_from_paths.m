function [price, price_se] = price_from_paths(payoff_fn, S, t_grid)
% PRICE_FROM_PATHS Compute price and standard error from simulated paths and payoff function.
%
% INPUTS: payoff_fn - function handle @(S, t_grid) -> N_paths×1 payoffs
%         S         - N_paths×M simulated price paths
%         t_grid    - 1×M actual time grid in years
%
% OUTPUTS: price     - scalar, model price
%         price_se  - scalar, Monte Carlo standard error

pay      = payoff_fn(S, t_grid);
price    = mean(pay);
price_se = std(pay) / sqrt(size(S, 1));
end
