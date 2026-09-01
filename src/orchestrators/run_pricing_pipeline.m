function [ts, prices] = run_pricing_pipeline(mkt, ts, dates, NT_MC, N_PATHS, Z_95)
% RUN_PRICING_PIPELINE Solves for the fair coupon rates and prices instruments under LV and BS.
%
%   INPUTS:
%       mkt      - Cell array of market data structures
%       ts       - Struct containing contract term sheet specifications
%       dates    - Struct containing dates (calib_dates, div_dates, obs_dates, maturity, T_obs)
%       NT_MC    - Number of Monte Carlo time steps
%       N_PATHS  - Number of simulation paths
%       Z_95     - 95% confidence interval multiplier
%
%   OUTPUTS:
%       ts       - Updated term sheet struct with the solved fair coupon_rate
%       prices   - Struct array containing options and autocallable prices across dates

    T_obs     = dates.T_obs;
    div_dates = dates.div_dates;
    obs_dates = dates.obs_dates;
    
    ts_trade    = ts;
    ts_trade.T1 = T_obs(1,1);
    ts_trade.T2 = T_obs(1,2);
    ts_trade.T3 = T_obs(1,3);

    t_extra_t0 = [ts_trade.T1, ts_trade.T2, ts_trade.T3];   % autocallable observations

    % Find fair coupon under Local Volatility (LV) model
    [fair_coupon, price_fair, se_fair_coupon] = solve_fair_coupon( ...
        mkt{1}.spot, mkt{1}.nodes_K, mkt{1}.sigma_nodes, ts_trade, NT_MC, [], ...
        mkt{1}.div_dates, mkt{1}.d, N_PATHS, t_extra_t0);

    ts.coupon_rate = fair_coupon;

    % Find fair coupon under BS model with ATM Implied Volatility of the market
    iv_atm_mkt = interp1(mkt{1}.smile.moneyness, mkt{1}.smile.iv, 1.0);
    [fair_coupon_bs, price_fair_bs, se_fair_coupon_bs] = solve_fair_coupon( ...
        mkt{1}.spot, [], [], ts_trade, NT_MC, iv_atm_mkt, ...
        mkt{1}.div_dates, mkt{1}.d, N_PATHS, t_extra_t0);

    fprintf('\n%s\n  <strong>PAR PRICING COMPARISON</strong> (Fair Coupon Rate)\n%s\n', repmat('=',1,72), repmat('=',1,72));
    fprintf('%-30s | %-12s | %-24s\n', 'Pricing Model', 'Fair Coupon', '95% Confidence Interval');
    fprintf('%s\n', repmat('-',1,72));
    fprintf('%-30s |    %5.2f%%   |  [%6.2f, %6.2f] EUR\n', 'Local Volatility Model (LV)', fair_coupon*100, price_fair - Z_95*se_fair_coupon, price_fair + Z_95*se_fair_coupon);
    fprintf('%-30s |    %5.2f%%   |  [%6.2f, %6.2f] EUR\n', 'Black-Scholes Model (ATM IV)', fair_coupon_bs*100, price_fair_bs - Z_95*se_fair_coupon_bs, price_fair_bs + Z_95*se_fair_coupon_bs);
    fprintf('%s\n', repmat('=',1,72));

    fprintf('\n%s\n  MONTE CARLO PRICING\n%s\n', repmat('=',1,60), repmat('=',1,60));

    % Storage: array of structs, one per date.
    prices = repmat(struct( ...
        'date', '', 'spot', 0, ...
        'lv_atmf', [], 'se_lv_atmf', [], ...
        'lv_80',   [], 'se_lv_80',   [], ...
        'lv_ac',   0,  'se_lv_ac',   0, ...
        'bs_atmf', [], 'se_bs_atmf', [], ...
        'bs_80',   [], 'se_bs_80',   [], ...
        'bs_ac',   0,  'se_bs_ac',   0, ...
        'an_atmf', [], 'an_80',      []), 1, 3);

    for i = 1:3
        m = mkt{i};

        ts_curr    = ts;
        ts_curr.T1 = T_obs(i,1);
        ts_curr.T2 = T_obs(i,2);
        ts_curr.T3 = T_obs(i,3);

        t_extra_i = T_obs(i,:);

        [S_lv, sim_dates_lv] = simulate_paths_MC( ...
            m.spot, m.nodes_K, m.sigma_nodes, ts_curr.T3, NT_MC, [], ...
            m.div_dates, m.d, N_PATHS, true, t_extra_i);

        sigma_bs_80 = interp1(m.smile.moneyness, m.smile.iv, 0.8);
        [S_bs_80, sim_dates_bs_80] = simulate_paths_MC( ...
            m.spot, [], [], ts_curr.T3, NT_MC, sigma_bs_80, ...
            m.div_dates, m.d, N_PATHS, true, t_extra_i);

        [bs_80, se_bs_80]     = payoff_put(S_bs_80, sim_dates_bs_80, m.spot, 0.80, T_obs(i,:));
        [lv_atmf, se_lv_atmf] = payoff_put(S_lv, sim_dates_lv, m.spot, 1.0, T_obs(i,:), m.d, m.div_dates);
        [lv_80, se_lv_80]     = payoff_put(S_lv, sim_dates_lv, m.spot, 0.80, T_obs(i,:));

        payoffs_lv_ac = payoff_autocallable(S_lv, sim_dates_lv, ts_curr);
        lv_ac         = mean(payoffs_lv_ac);
        se_lv_ac      = std(payoffs_lv_ac) / sqrt(N_PATHS);

        bs_atmf    = zeros(3, 3);
        se_bs_atmf = zeros(3, 3);
        an_atmf    = zeros(1, 3);
        an_80      = zeros(1, 3);

        for j = 1:3
            Fj = compute_forward(m.spot, m.d, div_dates, obs_dates(j));
            iv_atmf = interp1(m.smile.moneyness, m.smile.iv, Fj / m.spot, 'linear', 'extrap');

            [S_bs, sim_dates_bs] = simulate_paths_MC( ...
                m.spot, [], [], ts_curr.T3, NT_MC, iv_atmf, ...
                m.div_dates, m.d, N_PATHS, true, t_extra_i);

            [bs_atmf(j,:), se_bs_atmf(j,:)] = payoff_put(S_bs, sim_dates_bs, m.spot, 1.0, T_obs(i,:), m.d, m.div_dates);
            an_atmf(j) = bs_put_price(Fj, Fj, T_obs(i,j), iv_atmf);
            an_80(j)   = bs_put_price(Fj, 0.80 * m.spot, T_obs(i,j), sigma_bs_80);
        end

        payoffs_bs_ac = payoff_autocallable(S_bs, sim_dates_bs, ts_curr);
        bs_ac         = mean(payoffs_bs_ac);
        se_bs_ac      = std(payoffs_bs_ac) / sqrt(N_PATHS);

        bs_atmf    = diag(bs_atmf);
        se_bs_atmf = diag(se_bs_atmf);

        prices(i).date       = m.date;     prices(i).spot       = m.spot;
        prices(i).lv_atmf    = lv_atmf;    prices(i).se_lv_atmf = se_lv_atmf;
        prices(i).lv_80      = lv_80;      prices(i).se_lv_80   = se_lv_80;
        prices(i).lv_ac      = lv_ac;      prices(i).se_lv_ac   = se_lv_ac;
        prices(i).bs_atmf    = bs_atmf;    prices(i).se_bs_atmf = se_bs_atmf;
        prices(i).bs_80      = bs_80;      prices(i).se_bs_80   = se_bs_80;
        prices(i).bs_ac      = bs_ac;      prices(i).se_bs_ac   = se_bs_ac;
        prices(i).an_atmf    = an_atmf;    prices(i).an_80      = an_80;
    end

    for i = 1:3
        print_pricing(prices(i), ts.notional, Z_95);
    end
end
