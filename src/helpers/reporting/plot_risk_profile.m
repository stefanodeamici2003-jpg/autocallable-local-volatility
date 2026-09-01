function plot_risk_profile(port_profiles, spot_grid, ts, spot_t0, date_label)

port_names = {'A', 'B', 'C', 'D'};
labels     = {'Portfolio A (\Delta-hedge)', 'Portfolio B (\Delta + Div)', ...
              'Portfolio C (\Delta + Div + Vega)', 'Portfolio D (\Delta + Div + Vega*)'};
              
colors     = {[219, 76, 70] / 255, ...    % Coral Red (Portfolio A)
              [235, 140, 40] / 255, ...   % Amber Orange (Portfolio B)
              [24, 110, 145] / 255, ...   % Slate Teal (Portfolio C)
              [138, 43, 226] / 255};      % Soft Violet (Portfolio D)
              
markers    = {'-o', '-s', '-^', '-d'};

fig = figure('Name', ['Risk Profile — ' date_label], 'Color', 'w', 'Position', [100 100 900 760]);
try; fig.Theme = 'light'; catch; end          % force light theme

x_fill = [spot_grid(:)', fliplr(spot_grid(:)')];
bar_lvl    = ts.barrier;
strike_lvl = ts.strike;

% -------------------------------------------------------------------------
% Panel 1: Vega vs Spot
% -------------------------------------------------------------------------
subplot(2, 1, 1);
hold on;

for p = 1:numel(port_names)
    pname = port_names{p};
    if ~isfield(port_profiles, pname); continue; end
    pr = port_profiles.(pname);
    col = colors{p};

    y_upper = pr.vega + 1.96 * pr.vega_se;
    y_lower = pr.vega - 1.96 * pr.vega_se;
    fill(x_fill, [y_upper(:)', fliplr(y_lower(:)')], col, ...
        'FaceAlpha', 0.08, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(spot_grid, pr.vega, [markers{p}], 'Color', col, ...
        'LineWidth', 1.8, 'MarkerSize', 5.5, 'DisplayName', labels{p});
end

yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

% Critical vertical guide lines
line_col = [0.4 0.4 0.4];
xline(bar_lvl, '--', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');
xline(strike_lvl, '-.', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');
if abs(strike_lvl - spot_t0) >= 1e-4
    xline(spot_t0, ':', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');
end

% Label critical spots near bottom
yl = ylim;
text(bar_lvl, yl(1) + 0.04*diff(yl), '  Barrier (70%)', 'FontSize', 9, 'FontName', 'Helvetica', ...
     'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
     'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);

if abs(strike_lvl - spot_t0) < 1e-4
    text(strike_lvl, yl(1) + 0.04*diff(yl), '  Strike / S_0 / Current Spot', 'FontSize', 9, 'FontName', 'Helvetica', ...
         'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
         'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);
else
    text(strike_lvl, yl(1) + 0.04*diff(yl), '  Strike / Autocall', 'FontSize', 9, 'FontName', 'Helvetica', ...
         'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
         'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);
    text(spot_t0, yl(1) + 0.08*diff(yl), '  Current Spot S_0', 'FontSize', 9, 'FontName', 'Helvetica', ...
         'FontAngle', 'italic', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
         'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);
end

% Draw background bands for contract regions
p1 = patch([0 bar_lvl bar_lvl 0], [yl(1) yl(1) yl(2) yl(2)], [0.99 0.94 0.94], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
p2 = patch([bar_lvl strike_lvl strike_lvl bar_lvl], [yl(1) yl(1) yl(2) yl(2)], [0.98 0.98 0.98], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
p3 = patch([strike_lvl 2.0*spot_t0 2.0*spot_t0 strike_lvl], [yl(1) yl(1) yl(2) yl(2)], [0.94 0.97 0.99], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
uistack([p1, p2, p3], 'bottom');

xlabel('Spot Price (EUR)', 'FontSize', 11, 'FontName', 'Helvetica', 'Color', [0.15 0.15 0.15]);
ylabel('Vega (EUR / 1pp)', 'FontSize', 11, 'FontName', 'Helvetica', 'Color', [0.15 0.15 0.15]);
title(['Portfolio Vega vs Spot — ' date_label], 'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Helvetica');
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
xlim([min(spot_grid) max(spot_grid)]);


% -------------------------------------------------------------------------
% Panel 2: Div Sensitivity vs Spot
% -------------------------------------------------------------------------
subplot(2, 1, 2);
hold on;

ssdf_labels = {'SSDF 2026', 'SSDF 2027', 'SSDF 2028'};
ssdf_styles = {'-o', '-s', '-^'};

for p = 1:numel(port_names)
    pname = port_names{p};
    if ~isfield(port_profiles, pname); continue; end
    pr  = port_profiles.(pname);
    col = colors{p};
    lab = labels{p};

    for i = 1:3
        y_upper_div = pr.div_sens(i, :) + 1.96 * pr.div_sens_se(i, :);
        y_lower_div = pr.div_sens(i, :) - 1.96 * pr.div_sens_se(i, :);
        fill(x_fill, [y_upper_div(:)', fliplr(y_lower_div(:)')], col, ...
            'FaceAlpha', 0.05, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        plot(spot_grid, pr.div_sens(i, :), ssdf_styles{i}, 'Color', col, ...
            'LineWidth', 1.5, 'MarkerSize', 5.5, ...
            'DisplayName', [lab ' — ' ssdf_labels{i}]);
    end
end

yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

% Critical vertical guide lines
xline(bar_lvl, '--', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');
xline(strike_lvl, '-.', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');
if abs(strike_lvl - spot_t0) >= 1e-4
    xline(spot_t0, ':', 'Color', line_col, 'LineWidth', 1.1, 'HandleVisibility', 'off');
end

% Label critical spots near bottom
yl = ylim;
text(bar_lvl, yl(1) + 0.04*diff(yl), '  Barrier (70%)', 'FontSize', 9, 'FontName', 'Helvetica', ...
     'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
     'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);

if abs(strike_lvl - spot_t0) < 1e-4
    text(strike_lvl, yl(1) + 0.04*diff(yl), '  Strike / S_0 / Current Spot', 'FontSize', 9, 'FontName', 'Helvetica', ...
         'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
         'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);
else
    text(strike_lvl, yl(1) + 0.04*diff(yl), '  Strike / Autocall', 'FontSize', 9, 'FontName', 'Helvetica', ...
         'FontWeight', 'bold', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
         'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);
    text(spot_t0, yl(1) + 0.08*diff(yl), '  Current Spot S_0', 'FontSize', 9, 'FontName', 'Helvetica', ...
         'FontAngle', 'italic', 'Color', line_col, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
         'BackgroundColor', [1 1 1 0.75], 'Margin', 1.5);
end

% Draw background bands for contract regions
p1 = patch([0 bar_lvl bar_lvl 0], [yl(1) yl(1) yl(2) yl(2)], [0.99 0.94 0.94], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
p2 = patch([bar_lvl strike_lvl strike_lvl bar_lvl], [yl(1) yl(1) yl(2) yl(2)], [0.98 0.98 0.98], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
p3 = patch([strike_lvl 2.0*spot_t0 2.0*spot_t0 strike_lvl], [yl(1) yl(1) yl(2) yl(2)], [0.94 0.97 0.99], 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');
uistack([p1, p2, p3], 'bottom');

xlabel('Spot Price (EUR)', 'FontSize', 11, 'FontName', 'Helvetica', 'Color', [0.15 0.15 0.15]);
ylabel('Div Sensitivity (EUR / EUR SSDF)', 'FontSize', 11, 'FontName', 'Helvetica', 'Color', [0.15 0.15 0.15]);
title(['Portfolio Div Sensitivity vs Spot — ' date_label], 'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Helvetica');
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
xlim([min(spot_grid) max(spot_grid)]);

end
