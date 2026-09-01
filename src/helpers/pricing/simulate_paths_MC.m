function [S, t_grid] = simulate_paths_MC(S0, nodes_K, sigma_nodes, T, Nt, sigma, tau_divs, d_ratios, N_paths, antithetic, t_extra)
% Dispatch to LV or BS Monte Carlo simulator.
% INPUTS: S0          - scalar, initial spot
%         nodes_K     - n_nodes×1 LV strikes, or [] for BS
%         sigma_nodes - n_nodes×1 LV vols,    or [] for BS
%         T           - scalar, horizon in years
%         Nt          - integer, base number of time steps
%         sigma       - scalar BS volatility,  or [] for LV
%         tau_divs    - Nd×1, ex-dividend times in years
%         d_ratios    - Nd×1, proportional dividend yields
%         N_paths     - integer, number of MC paths
%         antithetic  - logical
%         t_extra     - extra times to anchor exactly in the grid (e.g. observation
%                       dates); required by the LV path simulator
% OUTPUTS: S           - N_paths×(M+1), simulated paths
%         t_grid      - 1×(M+1), actual time grid used

if ~isempty(nodes_K)
    [S, t_grid] = simulate_lv_paths_MC(S0, nodes_K, sigma_nodes, T, Nt, tau_divs, d_ratios, N_paths, antithetic, [], t_extra);
else
    [S, t_grid] = simulate_bs_paths_MC(S0, sigma, T, Nt, tau_divs, d_ratios, N_paths, antithetic, [], t_extra);
end
end
