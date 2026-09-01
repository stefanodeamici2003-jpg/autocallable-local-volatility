function nodes_K = select_adaptive_nodes(K_calib, IV_mkt, mandatory_K, n_nodes)
% Select n_nodes LV grid points: mandatory strikes + curvature-proportional sampling.
% INPUTS: K_calib     - Nx1, calibration strikes in EUR
%         IV_mkt      - Nx1, market implied vols at K_calib
%         mandatory_K - Mx1, strikes that must be included
%         n_nodes     - integer, total number of nodes desired
% OUTPUTS: nodes_K     - n_nodes×1, selected strikes in ascending order

% Step 1: curvature in log-strike space
V    = IV_mkt .^ 2;
curv = abs(diff(diff(V)));
curv = [0; curv; 0];

% Step 2: indices of mandatory strikes (nearest match in K_calib)
find_nearest  = @(k) find(abs(K_calib - k) == min(abs(K_calib - k)), 1);
mandatory_idx = unique(arrayfun(find_nearest, mandatory_K(:)));

% Guard: more mandatory nodes than requested
if numel(mandatory_idx) >= n_nodes
    nodes_K = sort(K_calib(mandatory_idx(1:n_nodes)));
    return;
end

% Step 3: proportional-to-curvature sampling for free nodes
n_free    = n_nodes - numel(mandatory_idx);
curv_free = curv;
curv_free(mandatory_idx) = 0;

total_curv = sum(curv_free);
if total_curv > 0
    cum        = cumsum(curv_free) / total_curv;
    thr_all    = linspace(0, 1, n_free + 2)';
    thresholds = thr_all(2:end-1);
    free_idx   = arrayfun(@(t) find(cum >= t, 1), thresholds);
else
    % Fallback: uniform spacing over non-mandatory candidates
    candidates = setdiff((1:numel(K_calib))', mandatory_idx);
    step       = max(1, floor(numel(candidates) / n_free));
    sel        = candidates(1:step:end);
    free_idx   = sel(1:min(n_free, numel(sel)));
end

% Step 4: merge, de-duplicate, pad with highest-curvature residuals if needed
all_idx = unique([mandatory_idx(:); free_idx(:)]);

if numel(all_idx) < n_nodes
    curv_pad = curv;
    curv_pad(all_idx) = -Inf;
    n_needed = n_nodes - numel(all_idx);
    [~, sorted_idx] = sort(curv_pad, 'descend');
    all_idx = [all_idx; sorted_idx(1:n_needed)];
    all_idx = sort(all_idx);
end

nodes_K = sort(K_calib(all_idx(1:n_nodes)));
end
