function [sigma_nodes, nodes_K, n_iterations, final_error] = calibrate_lv(smile_M, smile_IV, S0, forward, sigma_atm, T, d, tau_divs, n_nodes, tol, max_iter, Ny, Nt, verbose, extra_mandatory_K)
% Local volatility calibration via Reghai fixed-point iteration.
% INPUTS: smile_M          - Nx1 vector, moneyness from market smile
%         smile_IV         - Nx1 vector, implied vols from market smile
%         S0               - scalar, current spot
%         forward          - scalar, forward price at maturity
%         sigma_atm        - scalar, ATM implied vol (used for node grid if n_nodes < N)
%         T                - scalar, time to maturity in years
%         d                - Nd×1 vector, proportional dividend yields
%         tau_divs         - Nd×1 vector, ex-dividend times in years from today
%         n_nodes          - integer, number of LV nodes
%         tol              - scalar, convergence threshold on max|IV_mkt - IV_mod|
%         max_iter         - integer, max fixed-point iterations
%         Ny               - integer, PDE spatial nodes (default: 250)
%         Nt               - integer, PDE time steps   (default: 250)
%         verbose          - logical, print iteration info (default: false)
%         extra_mandatory_K - Mx1 vector, additional strikes forced into the node grid (default: [])
% OUTPUTS: sigma_nodes - n_nodes×1 vector, calibrated sigma at LV nodes
%         nodes_K     - n_nodes×1 vector, corresponding node strikes
%         n_iterations - integer, number of iterations used to converge
%         final_error  - scalar, max|IV_mkt - IV_mod| at the last iteration

if nargin < 12, Ny                = 250;   end
if nargin < 13, Nt                = 250;   end
if nargin < 14, verbose           = false; end
if nargin < 15, extra_mandatory_K = [];    end

[K_calib, IV_mkt] = convert_smile_to_strikes(smile_M, smile_IV, S0);

if n_nodes == length(K_calib)
    % Nodes coincide with calibration strikes: IV_mkt is the exact initial guess,
    % no interpolation error in the first fixed-point update.
    nodes_K     = K_calib;
    sigma_nodes = IV_mkt;
else
    % Curvature-based optimization of nodes
    [S_low, S_high] = setup_boundaries(forward, sigma_atm, T, 3);
    mandatory_K = [S_low; S_high; forward; extra_mandatory_K(:)];
    nodes_K     = select_adaptive_nodes(K_calib, IV_mkt, mandatory_K, n_nodes);
    sigma_nodes = init_lv_from_smile(nodes_K, K_calib, IV_mkt);
end

for iter = 1:max_iter
    [K_pde, C_pde] = solve_fokker_planck_nu(S0, T, sigma_nodes, nodes_K, tau_divs, d, Ny, Nt);

    C_calib = interp1(K_pde, C_pde, K_calib, 'linear', 'extrap');

    IV_mod = arrayfun(@(k,c) bs_implied_vol(forward, k, T, c), K_calib, C_calib);

    err = max(abs(IV_mkt - IV_mod));

    if verbose
        fprintf('  iter %2d | max IV err = %.2e\n', iter, err);
    end

    if err < tol, break; end
    sigma_nodes = update_lv_fixedpoint(sigma_nodes, IV_mkt, IV_mod, nodes_K, K_calib);
end

n_iterations = iter;
final_error  = err;

if verbose
    if err < tol
        fprintf('  => converged in %d iterations\n', iter);
    else
        fprintf('  => did NOT converge after %d iterations (err = %.2e)\n', max_iter, err);
    end
end
end
