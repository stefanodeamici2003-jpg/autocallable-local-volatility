function sigma = eval_lv(S, nodes_X, sigma_nodes)
% Evaluate local vol sigma at stock price(s) S via piecewise-linear interp in log-strike.
% INPUTS: S           - scalar or vector, stock price(s)
%         nodes_X     - n_nodes×1 vector, log-strike node positions = log(nodes_K)
%         sigma_nodes - n_nodes×1 vector, sigma at each node
% OUTPUTS: sigma       - same size as S, local vol (linear extrap beyond nodes)
% NOTE:   extrapolation continues the slope of the first/last segment in log-strike

% Cache the interpolant across calls; rebuild only when the grid or values change.
persistent last_X last_V F
if isempty(F) || ~isequal(nodes_X, last_X) || ~isequal(sigma_nodes, last_V)
    F = griddedInterpolant(nodes_X, sigma_nodes, 'linear', 'linear');
    last_X = nodes_X;
    last_V = sigma_nodes;
end

log_S = log(max(S, 1e-10));
sigma = F(log_S);
end
