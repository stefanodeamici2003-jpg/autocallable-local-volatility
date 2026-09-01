function sigma_nodes = init_lv_from_smile(nodes_K, K_calib, IV_mkt)
% Initialise LV node values by interpolating market smile onto nodes.
% INPUTS: nodes_K    - n_nodes×1 vector, LV node strikes
%         K_calib    - Nx1 vector, calibration strikes
%         IV_mkt     - Nx1 vector, market implied vols at K_calib
% OUTPUTS: sigma_nodes - n_nodes×1 vector, sigma at each node
% NOTE:   interpolation and extrapolation in log-strike space

sigma_nodes = interp1(log(K_calib), IV_mkt, log(nodes_K), 'linear', 'extrap');
end
