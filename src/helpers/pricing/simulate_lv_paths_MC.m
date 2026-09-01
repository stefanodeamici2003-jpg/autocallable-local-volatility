function [S, t_grid] = simulate_lv_paths_MC(S0, nodes_K, sigma_nodes, T, Nt, ...
    tau_divs, d_ratios, N_paths, antithetic, Z, t_extra)
% Simulate Local Volatility paths under the calibrated sigma_LV(S).
% Euler scheme in log-S, with proportional dividend jumps at ex-dates.
% INPUTS: S0          - scalar, initial spot
%         nodes_K     - n_nodes×1, LV node strikes (calibrated)
%         sigma_nodes - n_nodes×1, sigma at LV nodes (calibrated)
%         T           - scalar, horizon in years
%         Nt          - integer, base number of time steps
%         tau_divs    - Nd×1, ex-dividend times in years
%         d_ratios    - Nd×1, proportional dividend yields
%         N_paths     - integer, number of MC paths
%         antithetic  - logical, true to use antithetic variates (ignored when Z provided)
%         Z           - N_paths×M pre-generated randoms (optional); if provided antithetic is ignored
%         t_extra     - 1×k vector of anchor times (REQUIRED): observation
%                       dates that must land exactly on the time grid
%                       (e.g. autocallable T1,T2,T3). Pass [] is NOT allowed.
% OUTPUTS: S           - N_paths×(M+1), simulated price paths
%         t_grid      - 1×(M+1), actual time grid used (includes tau_divs and t_extra exactly)

if nargin < 10 || isempty(Z)
    Z = [];
end
if nargin < 11 || isempty(t_extra)
    error('simulate_lv_paths_MC:missing_t_extra', ...
        'simulate_lv_paths_MC requires t_extra (observation/anchor times) as the 11th argument.');
end
use_external_Z = ~isempty(Z);

if antithetic && ~use_external_Z
    assert(mod(N_paths,2)==0, 'N_paths must be even for antithetic');
    N_half = N_paths / 2;
end

% Dividend dates must land exactly on a grid node, not approximately.
% unique+sort inserts tau_divs into the regular linspace grid exactly.
t_grid = sort(unique([linspace(0, T, Nt+1), tau_divs(:)', t_extra(:)']));
M      = numel(t_grid) - 1;
dt     = diff(t_grid);

S      = zeros(N_paths, M+1);
S(:,1) = S0;

logK_nodes = log(nodes_K);
div_step   = arrayfun(@(tau) find(abs(t_grid - tau) < 1e-12, 1), tau_divs);

for k = 1:M
    sigma_k = max(eval_lv(S(:,k), logK_nodes, sigma_nodes), 1e-4);

    if use_external_Z
        % Same draws across base and bumped simulations: noise cancels in
        % central differences, reducing greek variance at no extra cost.
        Zk = Z(:, k);
    elseif antithetic
        Z_half = randn(N_half, 1);
        Zk     = [Z_half; -Z_half];
    else
        Zk = randn(N_paths, 1);
    end

    % Log-Euler step: the -0.5*sigma^2*dt term is the Ito correction
    % that ensures E[S_{t+dt}] = S_t (no spurious drift with r=0).
    S(:,k+1) = S(:,k) .* exp( sigma_k .* sqrt(dt(k)) .* Zk ...
        - 0.5 .* sigma_k.^2 .* dt(k) );

    % Proportional dividend jump: S(tau+) = S(tau-) * (1 - d_i)
    idx_div = find(div_step == k+1);
    for j = 1:numel(idx_div)
        S(:,k+1) = S(:,k+1) * (1 - d_ratios(idx_div(j)));
    end
end
end
