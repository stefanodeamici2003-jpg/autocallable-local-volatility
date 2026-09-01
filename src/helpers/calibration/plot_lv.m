function plot_lv(nodes_K, sigma_nodes, K_calib, IV_mkt, date_label, sub_idx)
% Plot sigma_LV^2 vs ln(S): interpolation zone, extrapolation tails, market smile.
% INPUTS: nodes_K     - n_nodes×1 vector, LV node strikes
%         sigma_nodes - n_nodes×1 vector, calibrated sigma at nodes
%         K_calib     - Nx1 vector, calibration strikes
%         IV_mkt      - Nx1 vector, market implied vols at K_calib
%         date_label  - string, title label
%         sub_idx     - optional integer, subplot index (1, 2, or 3)

nodes_X = log(nodes_K);
S_low   = nodes_K(1);
S_high  = nodes_K(end);

% Evaluation grid: 1 log-sigma-unit beyond the nodes on each side
margin = (nodes_X(end) - nodes_X(1)) * 0.25;
X_plot = linspace(nodes_X(1) - margin, nodes_X(end) + margin, 600)';
sig_lv = eval_lv(exp(X_plot), nodes_X, sigma_nodes);

y_max = max([sig_lv.^2; IV_mkt.^2]) * 1.15;

if nargin < 6 || isempty(sub_idx)
    figure('Name', ['LV — ' date_label]);
else
    subplot(1, 3, sub_idx);
end

% Extrapolation zones (shaded background — draw first so lines are on top)
fill([nodes_X(end), X_plot(end), X_plot(end), nodes_X(end)], ...
     [0, 0, y_max, y_max], [0.85 0.92 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off');
hold on;
fill([X_plot(1), nodes_X(1), nodes_X(1), X_plot(1)], ...
     [0, 0, y_max, y_max], [0.85 0.92 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off');

% Market implied variance
plot(log(K_calib), IV_mkt.^2, 'k--', 'LineWidth', 1.2, 'DisplayName', '\sigma^2_{mkt}(K)');

% Local variance curve
plot(X_plot, sig_lv.^2, 'b-', 'LineWidth', 2, 'DisplayName', '\sigma^2_{LV}(S)');

% LV nodes
plot(nodes_X, sigma_nodes.^2, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r', ...
     'DisplayName', 'LV nodes');

% S_low / S_high boundaries
suffix = ' (shifted)';

xline(log(S_low),  'g--', 'LineWidth', 1.2, 'Label', ['S_{low}' suffix],  ...
      'LabelVerticalAlignment', 'bottom', 'DisplayName', ['S_{low}' suffix]);
xline(log(S_high), 'g--', 'LineWidth', 1.2, 'Label', ['S_{high}' suffix], ...
      'LabelVerticalAlignment', 'bottom', 'DisplayName', ['S_{high}' suffix]);



xlabel('ln(S)');
ylabel('\sigma_{LV}^2');
title(['\sigma_{LV}^2 vs ln(S) — ' date_label]);
legend('Location', 'northeast');
ylim([0, y_max]);
grid on;
end
