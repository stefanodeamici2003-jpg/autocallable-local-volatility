function plot_instrument_profiles(profile_cert, N_CERT, spot_t0, date_label)

fig = figure('Name', ['Instrument Standalone Profiles — ' date_label], 'Color', 'w', 'Position', [150 150 950 780]);
try; fig.Theme = 'light'; catch; end          % force light theme

col_cert = [0.15 0.15 0.15];

bar_lvl    = 0.70 * spot_t0;
strike_lvl = spot_t0;

% -------------------------------------------------------------------------
% Subplot 1: Standalone Vega Profile (Area Chart)
% -------------------------------------------------------------------------
subplot(2, 1, 1);
hold on;

% Certificate position vega (N_CERT * cert_vega)
cert_pos_vega = N_CERT * profile_cert.vega;

% Fine grid for smooth shading of area
x_fine = linspace(min(profile_cert.spot_grid), max(profile_cert.spot_grid), 500);
y_fine = interp1(profile_cert.spot_grid, cert_pos_vega, x_fine, 'pchip');

% Shading for positive (green) and negative (red) regions
y_pos = max(y_fine, 0);
y_neg = min(y_fine, 0);

color_green = [46, 125, 50] / 255;
color_red   = [198, 40, 40] / 255;

area(x_fine, y_pos, 0, 'FaceColor', color_green, 'EdgeColor', 'none', 'FaceAlpha', 0.20, 'HandleVisibility', 'off');
area(x_fine, y_neg, 0, 'FaceColor', color_red, 'EdgeColor', 'none', 'FaceAlpha', 0.20, 'HandleVisibility', 'off');

% Plot the main line on top
plot(profile_cert.spot_grid, cert_pos_vega, '-', 'Color', col_cert, ...
    'LineWidth', 2.5, 'DisplayName', 'Short Certificate Vega');

yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

% Critical vertical guide lines
line_col = [0.4 0.4 0.4];
xline(bar_lvl, '--', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');
xline(strike_lvl, '-.', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');

% Label critical spots near bottom with a clean background box
yl = ylim;
text(bar_lvl, yl(1) + 0.04*diff(yl), '  Barrier (70%)', 'FontSize', 9, 'FontName', 'Helvetica', ...
     'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
     'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);
text(strike_lvl, yl(1) + 0.04*diff(yl), '  Strike / S_0 (100%)', 'FontSize', 9, 'FontName', 'Helvetica', ...
     'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
     'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);

% Draw background patches
p1 = patch([0 bar_lvl bar_lvl 0], [yl(1) yl(1) yl(2) yl(2)], [0.99 0.94 0.94], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
p2 = patch([bar_lvl strike_lvl strike_lvl bar_lvl], [yl(1) yl(1) yl(2) yl(2)], [0.98 0.98 0.98], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
p3 = patch([strike_lvl 2.0*spot_t0 2.0*spot_t0 strike_lvl], [yl(1) yl(1) yl(2) yl(2)], [0.94 0.97 0.99], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
uistack([p1, p2, p3], 'bottom');

xlabel('Spot Price (EUR)', 'FontSize', 11, 'FontName', 'Helvetica', 'Color', [0.15 0.15 0.15]);
ylabel('Vega (EUR / 1pp)', 'FontSize', 11, 'FontName', 'Helvetica', 'Color', [0.15 0.15 0.15]);
title(['Certificate Standalone Vega Profile — ' date_label], 'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Helvetica');
legend('Location', 'best', 'FontSize', 9.5, 'FontName', 'Helvetica', 'Color', [1 1 1 0.90], 'EdgeColor', [0.85 0.85 0.85]);
grid on; box off;

ax = gca;
ax.Layer = 'top';
ax.FontSize = 10;
ax.FontName = 'Helvetica';
ax.XColor = [0.25 0.25 0.25];
ax.YColor = [0.25 0.25 0.25];
ax.GridColor = [0.85 0.85 0.85];
ax.GridAlpha = 0.4;
ax.LineWidth = 1.0;
xlim([min(profile_cert.spot_grid) max(profile_cert.spot_grid)]);

% -------------------------------------------------------------------------
% Subplot 2: Certificate Standalone Dividend Sensitivity
% -------------------------------------------------------------------------
subplot(2, 1, 2);
hold on;

ssdf_labels = {'SSDF 2026', 'SSDF 2027', 'SSDF 2028'};
colors = {[24, 110, 145] / 255, [219, 76, 70] / 255, [46, 125, 50] / 255};  % Teal, Red, Green
markers = {'-o', '-s', '-^'};

% Plot the dividend sensitivity of the short certificate position
for i = 1:3
    cert_pos_div = N_CERT * profile_cert.div_sens(i, :);
    plot(profile_cert.spot_grid, cert_pos_div, markers{i}, 'Color', colors{i}, ...
        'LineWidth', 2.0, 'MarkerSize', 5.5, ...
        'DisplayName', [ssdf_labels{i} ' (Short Cert)']);
end

yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

% Critical vertical guide lines
xline(bar_lvl, '--', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');
xline(strike_lvl, '-.', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');

% Label critical spots near bottom
yl = ylim;
text(bar_lvl, yl(1) + 0.04*diff(yl), '  Barrier (70%)', 'FontSize', 9, 'FontName', 'Helvetica', ...
     'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
     'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);
text(strike_lvl, yl(1) + 0.04*diff(yl), '  Strike / S_0 (100%)', 'FontSize', 9, 'FontName', 'Helvetica', ...
     'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
     'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);

% Draw background bands for contract regions
p1 = patch([0 bar_lvl bar_lvl 0], [yl(1) yl(1) yl(2) yl(2)], [0.99 0.94 0.94], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
p2 = patch([bar_lvl strike_lvl strike_lvl bar_lvl], [yl(1) yl(1) yl(2) yl(2)], [0.98 0.98 0.98], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
p3 = patch([strike_lvl 2.0*spot_t0 2.0*spot_t0 strike_lvl], [yl(1) yl(1) yl(2) yl(2)], [0.94 0.97 0.99], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
uistack([p1, p2, p3], 'bottom');

xlabel('Spot Price (EUR)', 'FontSize', 11, 'FontName', 'Helvetica', 'Color', [0.15 0.15 0.15]);
ylabel('Dividend Sensitivity (EUR / EUR SSDF)', 'FontSize', 11, 'FontName', 'Helvetica', 'Color', [0.15 0.15 0.15]);
title(['Certificate Standalone Dividend Sensitivity — ' date_label], 'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Helvetica');
legend('Location', 'best', 'FontSize', 9.5, 'FontName', 'Helvetica', 'Color', [1 1 1 0.90], 'EdgeColor', [0.85 0.85 0.85]);
grid on; box off;

ax = gca;
ax.Layer = 'top';
ax.FontSize = 10;
ax.FontName = 'Helvetica';
ax.XColor = [0.25 0.25 0.25];
ax.YColor = [0.25 0.25 0.25];
ax.GridColor = [0.85 0.85 0.85];
ax.GridAlpha = 0.4;
ax.LineWidth = 1.0;
xlim([min(profile_cert.spot_grid) max(profile_cert.spot_grid)]);

end
