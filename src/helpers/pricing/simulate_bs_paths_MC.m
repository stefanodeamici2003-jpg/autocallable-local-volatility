function [S, t_grid] = simulate_bs_paths_MC(S0, sigma, T, Nt, tau_divs, d_ratios, N_paths, antithetic, Z, t_extra)
% Simulate Black-Scholes paths under constant volatility with discrete dividends.
% Vectorized Euler scheme in log-S.
% INPUTS: S0         - scalar, initial spot
%         sigma      - scalar, constant BS volatility
%         T          - scalar, horizon in years
%         Nt         - integer, base number of time steps
%         tau_divs   - Nd×1, ex-dividend times in years
%         d_ratios   - Nd×1, proportional dividend yields
%         N_paths    - integer, number of MC paths
%         antithetic - logical, true to use antithetic variates (ignored when Z given)
%         Z          - N_paths×M pre-generated randoms (optional); enables CRN, antithetic ignored
%         t_extra    - 1×k extra anchor times forced exactly onto the grid (optional)
% OUTPUTS: S          - N_paths×(M+1), simulated price paths
%         t_grid     - 1×(M+1), actual time grid used (includes tau_divs and t_extra exactly)

if nargin < 9,  Z       = []; end
if nargin < 10, t_extra = []; end
use_external_Z = ~isempty(Z);

if antithetic
    assert(mod(N_paths,2)==0, 'N_paths must be even for antithetic');
    N_half = N_paths / 2;
end

t_grid = sort(unique([linspace(0, T, Nt+1), tau_divs(:)', t_extra(:)']));
M      = numel(t_grid) - 1;
dt     = diff(t_grid);

div_step       = arrayfun(@(tau) find(abs(t_grid - tau) < 1e-12, 1), tau_divs);
drift_per_step = -0.5 * sigma^2 * dt;
vol_per_step   =  sigma * sqrt(dt);

if ~use_external_Z
    if antithetic
        Z_half = randn(N_half, M);
        Z      = [Z_half; -Z_half];
    else
        Z      = randn(N_paths, M);
    end
end

% Compute log-Euler steps and exponentiate
log_increments = vol_per_step .* Z + drift_per_step;
log_S          = cumsum(log_increments, 2);
S              = [ones(N_paths, 1) * S0, S0 * exp(log_S)];

% Apply proportional dividend factors element-wise
step_factors = ones(1, M+1);
step_factors(div_step) = 1 - d_ratios;
div_factor = cumprod(step_factors);
S = S .* div_factor;
end
