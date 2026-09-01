% PDE & MC Node Sweep Analysis
%   Calibrates the Local Volatility model for different values of N_NODES
%   and measures calibration error, pricing impact, and computation time.

base_dir = fileparts(mfilename('fullpath'));
addpath(genpath(base_dir));

data_dir = fullfile(base_dir, '..', 'Project5_Autocallable', 'Market Data');

% Constants & Dates & Contract Specifications
SIGMA_ATM = 0.255;
TOL       = 1e-4;
MAX_ITER  = 150;
NY        = 250;
NT        = 250;
N_PATHS   = 100000;
NT_MC     = 250;
Z_95      = 1.96;      % 95% confidence interval multiplier (standard normal)

calib_dates = [datetime(2026,3,5); datetime(2026,3,6); datetime(2026,3,9)];
div_dates   = [datetime(2026,5,18); datetime(2027,5,24); datetime(2028,5,22)];
obs_dates   = [datetime(2027,3,5); datetime(2028,3,5); datetime(2029,3,5)];
maturity    = datetime(2029,3,5);

% T_obs(i,j) = yearfrac from calib_dates(i) to obs_dates(j), Act/365
T_obs = zeros(3, 3);
for i = 1:3
    T_obs(i,:) = yearfrac(calib_dates(i), obs_dates, 3)';
end

% Term structure baseline specifications (independent of spot)
ts.notional     = 100000;
ts.coupon_rate  = NaN;
ts.barrier_pct  = 0.70;
ts.coupon_pct   = 0.70;

% Load market data & bootstrap dividends
files = {'05mar2026.xlsx', '06mar2026.xlsx', '09mar2026.xlsx'};
mkt   = cellfun(@(f) load_market_data(fullfile(data_dir, f)), files, 'UniformOutput', false);

for i = 1:3
    m = mkt{i};
    mkt{i}.d = bootstrap_dividends(m.spot, [m.ssdf.y2026; m.ssdf.y2027; m.ssdf.y2028]);
end

% Complete term structure fields that depend on market spot
ts.strike       = mkt{1}.spot;
ts.barrier      = ts.barrier_pct * ts.strike;
ts.autocall_lvl = ts.strike;
ts.coupon_level = ts.coupon_pct * ts.strike;

% Baseline Calib & Fair Coupon Solving
m = mkt{1};
tau_divs_t0 = yearfrac(calib_dates(1), div_dates, 3);
mkt{1}.div_dates = tau_divs_t0;
forward_t0 = compute_forward(m.spot, m.d, div_dates, maturity);

fprintf('Calibrating baseline LV model...\n');
[sigma_nodes_71, nodes_K_71] = calibrate_lv( ...
    m.smile.moneyness, m.smile.iv, m.spot, forward_t0, SIGMA_ATM, m.ttm, ...
    m.d, tau_divs_t0, 71, TOL, MAX_ITER, NY, NT, false);

% Set sweep reference structure
ts_sweep    = ts;
ts_sweep.T1 = T_obs(1,1);
ts_sweep.T2 = T_obs(1,2);
ts_sweep.T3 = T_obs(1,3);

% Simulate paths under baseline to find fair coupon rate
fprintf('Solving for fair coupon rate under baseline model...\n');
fair_coupon = solve_fair_coupon( ...
    m.spot, nodes_K_71, sigma_nodes_71, ts_sweep, NT_MC, [], ...
    tau_divs_t0, m.d, N_PATHS, [ts_sweep.T1, ts_sweep.T2, ts_sweep.T3]);

ts_sweep.coupon_rate = fair_coupon;
fprintf('Solved baseline fair coupon rate: %.2f%% p.a.\n', fair_coupon * 100);

% Parallel Node Sweep
node_counts = 17:3:71;   % [17, 20, 23, ..., 71]
n_sweep     = numel(node_counts);

% Pre-allocate results
calib_err   = zeros(n_sweep, 1);   % calibration error
ac_price    = zeros(n_sweep, 1);   % price (%)
ac_price_se = zeros(n_sweep, 1);   % standard error (%)
calib_time  = zeros(n_sweep, 1);   % time (s)
calib_iters = zeros(n_sweep, 1);   % iteration count

fprintf('\nRunning node sweep for N = %d to %d nodes...\n', node_counts(1), node_counts(end));

parfor k = 1:n_sweep
    addpath(genpath(base_dir));
    N = node_counts(k);
    
    t_start = tic;
    [sigma_n, nodes_K_n, iters_n, calib_err(k)] = calibrate_lv( ...
        m.smile.moneyness, m.smile.iv, m.spot, forward_t0, ...
        SIGMA_ATM, m.ttm, m.d, tau_divs_t0, ...
        N, TOL, MAX_ITER, NY, NT, false, [ts_sweep.barrier; ts_sweep.autocall_lvl]);
    calib_time(k) = toc(t_start);
    calib_iters(k) = iters_n;
    
    % Autocallable MC pricing
    [S_paths, sim_dates] = simulate_paths_MC( ...
        m.spot, nodes_K_n, sigma_n, ts_sweep.T3, NT_MC, [], ...
        tau_divs_t0, m.d, N_PATHS, true, [ts_sweep.T1, ts_sweep.T2, ts_sweep.T3]);
    payoffs        = payoff_autocallable(S_paths, sim_dates, ts_sweep);
    ac_price(k)    = mean(payoffs) / ts_sweep.notional * 100;
    ac_price_se(k) = std(payoffs)  / sqrt(N_PATHS) / ts_sweep.notional * 100;
end

% Print Console Table
fprintf('\n%s\n  NODE SWEEP RESULTS (Reference Date: %s)\n%s\n', ...
    repmat('=',1,72), m.date, repmat('=',1,72));
fprintf('%-8s %-15s %-20s %-12s %-8s\n', 'N_nodes', 'Calib_err(%)', 'Price (% of notional)', 'Time (s)', 'Iters');
fprintf('%-72s\n', repmat('-',1,72));
for k = 1:n_sweep
    fprintf('%-8d %-15.4f %6.2f ± %-8.3f %-12.1f %-8d\n', ...
        node_counts(k), calib_err(k)*100, ac_price(k), Z_95 * ac_price_se(k), calib_time(k), calib_iters(k));
end
fprintf('%-72s\n', repmat('-',1,72));

% Plot Trade-offs
figure('Name', 'Trade-off Analysis: Number of Local Volatility Nodes');

% Panel 1 — Calibration error
subplot(3, 1, 1);
semilogy(node_counts, calib_err * 100, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
yline(TOL * 100, 'r--', 'Standard Tol (0.01%)', 'LineWidth', 1.1, 'LabelHorizontalAlignment', 'right');
yline(0.05, 'm--', 'Relaxed Tol (0.05%)', 'LineWidth', 1.1, 'LabelHorizontalAlignment', 'right');
ylabel('max|IV_{mkt} - IV_{mod}| (%)');
title('Residual Calibration Error');
grid on;

% Panel 2 — Autocallable price
subplot(3, 1, 2);
ci_low  = ac_price(end) - Z_95 * ac_price_se(end);
ci_high = ac_price(end) + Z_95 * ac_price_se(end);
fill([node_counts(1), node_counts(end), node_counts(end), node_counts(1)], ...
     [ci_low, ci_low, ci_high, ci_high], ...
     [0.8 0.9 1.0], 'FaceAlpha', 0.4, 'EdgeColor', 'none', 'DisplayName', '95% CI Baseline (71 nodes)');
hold on;
errorbar(node_counts, ac_price, Z_95 * ac_price_se, 'k-o', 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'k', 'DisplayName', 'Sweep Prices');
ylabel('Price (% of notional)');
title('Autocallable Price (LV-MC)');
legend('Location', 'southeast');
grid on;

% Panel 3 — Calibration time
subplot(3, 1, 3);
bar(node_counts, calib_time, 'FaceColor', [0.4 0.7 0.4], 'EdgeColor', [0.3 0.6 0.3]);
xlabel('Number of LV Nodes'); ylabel('Time (s)');
title('Calibration CPU Time');
grid on;

sgtitle('Local Volatility Node Sweep Trade-off');
