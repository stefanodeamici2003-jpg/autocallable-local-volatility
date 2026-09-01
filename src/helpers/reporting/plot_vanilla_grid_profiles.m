function best = plot_vanilla_grid_profiles(profile_cert, profile_van, N_CERT, spot_t0, grid_T_fwd, w, date_label, best, scores)

if nargin < 8 || isempty(best) || nargin < 9 || isempty(scores)
    [best, scores] = select_optimal_vanilla_l2(profile_cert, profile_van, ...
        N_CERT, spot_t0, grid_T_fwd, w);
end

spot_grid   = profile_cert.spot_grid(:)';
mats        = unique(profile_van.maturity);
yr_label    = arrayfun(@(t) sprintf('%.0fY', round(t)), mats, 'UniformOutput', false);
ssdf_styles = {'-o', '-s', '-^'};

fprintf('\n%s\n  VANILLA GRID - probability-weighted L2 residual (Option A)\n%s\n', ...
    repmat('=',1,60), repmat('=',1,60));

for m = 1:numel(mats)
    sel   = find(abs(profile_van.maturity - mats(m)) < 1e-9);
    cols  = lines(numel(sel));
    fwd_m = grid_T_fwd(abs(grid_T_fwd(:,1) - mats(m)) < 1e-9, 2);

    figure('Name', sprintf('Vanilla grid %s - %s', yr_label{m}, date_label), ...
        'Position', [100 100 900 760]);
    ax1 = subplot(2,1,1); hold(ax1,'on');
    ax2 = subplot(2,1,2); hold(ax2,'on');

    fprintf('  Put maturity %s\n', yr_label{m});
    fprintf('    %-8s | %12s | %14s | %12s\n', 'K/F', 'Lw vega', 'Lw divsens', 'Lw total');

    for q = 1:numel(sel)
        c        = sel(q);
        net_vega = scores.net_vega(c, :);
        net_ds   = scores.net_div(:, :, c);
        Lw_vega  = scores.Lw_vega(c);
        Lw_div   = scores.Lw_div(c);
        Lw_total = scores.Lw_total(c);

        mny = profile_van.strike(c) / fwd_m(1);
        lbl = sprintf('K/F=%.0f%%', 100*mny);
        col = cols(q, :);

        plot(ax1, spot_grid, net_vega, '-o', 'Color', col, 'LineWidth', 1.3, ...
            'MarkerSize', 4, 'DisplayName', lbl);
        for tt = 1:3
            hv = 'off';
            if tt == 1
                hv = 'on';
            end
            plot(ax2, spot_grid, net_ds(tt, :), ssdf_styles{tt}, 'Color', col, ...
                'LineWidth', 1.2, 'MarkerSize', 4, 'DisplayName', lbl, 'HandleVisibility', hv);
        end

        fprintf('    %-8.0f | %12.2f | %14.4f | %12.2f\n', ...
            100*mny, Lw_vega, Lw_div, Lw_total);
    end

    decorate(ax1, spot_t0, 'Net Vega (EUR / 1pp)', ...
        sprintf('Portfolio net Vega vs Spot - put %s - %s', yr_label{m}, date_label));
    decorate(ax2, spot_t0, 'Net Div-Sens (EUR / EUR SSDF)', ...
        sprintf('Portfolio net Div-Sens (per tenor) - put %s - %s', yr_label{m}, date_label));
end

fprintf('  %s\n', repmat('-',1,54));
fprintf('  Best (min weighted L2): K/F=%.0f%%, K=%.4f EUR, T=%.0fY  (Lw total=%.2f)\n', ...
    100*best.moneyness, best.strike, round(best.maturity), best.Lw_total);
end

function decorate(ax, spot_t0, ylab, ttl)
yline(ax, 0, 'k-', 'HandleVisibility','off');
xline(ax, spot_t0, 'k:', 'Label','S0', 'HandleVisibility','off');
xlabel(ax, 'Spot ISP (EUR)'); ylabel(ax, ylab);
title(ax, ttl); legend(ax, 'Location','best'); grid(ax,'on'); box(ax,'on');
end
