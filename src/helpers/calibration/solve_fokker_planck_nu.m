function [K_pde, C_pde] = solve_fokker_planck_nu(S0, T, sigma_nodes, nodes_K, tau_divs, d, Ny, Nt)
% Solve the forward Kolmogorov PDE for call prices with discrete dividends, on a
% non-uniform time grid: a uniform base of (Nt+1) points augmented with the exact
% ex-dividend times tau_divs, so each dividend jump lands precisely on tau_i with
% no round-to-step approximation.
% INPUTS: S0          - scalar, spot price
%         T           - scalar, time to maturity in years
%         sigma_nodes - n_nodes×1 vector, local vol sigma at LV nodes
%         nodes_K     - n_nodes×1 vector, LV node strikes
%         tau_divs    - Nd×1 vector, ex-dividend times in years
%         d           - Nd×1 vector, proportional dividend yields
%         Ny          - integer, number of spatial nodes
%         Nt          - integer, number of base time steps
% OUTPUTS: K_pde       - Ny×1 vector, strike grid
%         C_pde       - Ny×1 vector, call prices at maturity T

dy = 1 / Ny;

% --- Spatial grid (Duffy transform, identical to uniform version) ---------
y     = linspace(0, 1 - 1/Ny, Ny)';
K_pde = S0 * y ./ (1 - y);

sigma_local_sq = eval_lv(K_pde, log(nodes_K), sigma_nodes) .^ 2;

c_y = -sigma_local_sq .* y.^2 .* (1 - y);
d_y =  0.5 * sigma_local_sq .* y.^2 .* (1 - y).^2;

% --- Build non-uniform time grid -----------------------------------------
% Start from a uniform partition with Nt steps, then insert tau_divs.
t_uniform = linspace(0, T, Nt + 1)';
t_grid    = sort([t_uniform; tau_divs(:)]);
% Remove near-duplicates (a tau that already lands almost on a uniform node)
t_grid    = t_grid([true; diff(t_grid) > 1e-10]);
dt_vec    = diff(t_grid);            % (N_steps × 1), all > 0 by construction
N_steps   = numel(dt_vec);

% Identify exact dividend step indices: dividend i is applied AT THE END
% of step k = div_steps(i) (i.e. after solving from t_grid(k) to t_grid(k+1)).
[~, div_node_idx] = ismembertol(tau_divs, t_grid, 1e-10);
div_steps = div_node_idx - 1;        % step after which to apply the jump

% --- Sparse triplet templates --------------------------------------------
rows = [1:Ny, 2:Ny, 1:Ny-1];
cols = [1:Ny, 1:Ny-1, 2:Ny];

% --- Time-stepping loop with LU caching across equal dt ------------------
C_pde   = max(S0 - K_pde, 0);
dt_prev = NaN;
dA      = [];

for j = 1:N_steps
    dt = dt_vec(j);

    if isnan(dt_prev) || abs(dt - dt_prev) > 1e-14
        % dt changed → rebuild A and its LU factorization.
        main_diag = ones(Ny, 1);
        sub_diag  = zeros(Ny, 1);
        sup_diag  = zeros(Ny, 1);

        idx            = 2:Ny-1;
        main_diag(idx) = 1 + 2*(dt/dy^2) * d_y(idx);
        sub_diag(idx)  =    (dt/(2*dy))   * c_y(idx) - (dt/dy^2) * d_y(idx);
        sup_diag(idx)  =   -(dt/(2*dy))   * c_y(idx) - (dt/dy^2) * d_y(idx);

        vals = [main_diag', sub_diag(2:Ny)', sup_diag(1:Ny-1)'];
        A    = sparse(rows, cols, vals, Ny, Ny);
        dA   = decomposition(A, 'lu');
        dt_prev = dt;
    end

    C_pde = dA \ C_pde;

    % Dividend jump (exact: dividend i lands precisely on t_grid(div_steps(i)+1)).
    for i_div = find(div_steps == j)'
        K_shifted = K_pde / (1 - d(i_div));
        C_pde     = (1 - d(i_div)) * interp1(K_pde, C_pde, K_shifted, 'linear', 0);
    end
end
end