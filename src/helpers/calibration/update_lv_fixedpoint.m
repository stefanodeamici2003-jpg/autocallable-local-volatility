function sigma_new = update_lv_fixedpoint(sigma_nodes, IV_mkt, IV_mod, nodes_K, K_calib)
% Reghai fixed-point update: sigma_new = sigma_old * (IV_mkt / IV_mod).
% INPUTS: sigma_nodes - n_nodes×1 vector, current sigma at LV nodes
%         IV_mkt      - Nx1 vector, market implied vols at K_calib
%         IV_mod      - Nx1 vector, model implied vols at K_calib
%         nodes_K     - n_nodes×1 vector, LV node strikes
%         K_calib     - Nx1 vector, calibration strikes
% OUTPUTS: sigma_new   - n_nodes×1 vector, updated sigma at LV nodes

% Interpolate the ratio (not sigma directly): IV_mkt/IV_mod is smoother
% and cancels systematic bias when nodes_K does not coincide with K_calib.
ratio     = interp1(log(K_calib), IV_mkt ./ IV_mod, log(nodes_K), 'linear', 'extrap');
sigma_new = sigma_nodes .* ratio;
end
