function [prices, std_errs] = payoff_put(S_paths, sim_dates, spot, pct, T_vec, d, div_dates)
% Monte Carlo put prices at the three maturities in T_vec (r = 0).
% Strike is pct of a reference level set per maturity: by default the fixed spot
% (pct*spot); pass the dividend arguments d and div_dates to switch to
% forward-moneyness, where the strike becomes pct*F(T) with F the dividend forward.
% INPUTS: S_paths   - N_paths×N_sim, simulated paths
%         sim_dates - 1×N_sim, dates in years from t0
%         spot      - scalar, current spot price
%         pct       - scalar, strike as a fraction of the reference (e.g. 0.80, or 1.0 = ATMF)
%         T_vec     - 1×3, maturities in years from t0 (e.g. T_obs(i,:))
%         d         - (optional) Nd×1, proportional dividend yields; enables forward strike
%         div_dates - (optional) Nd×1, ex-dividend times in years; required together with d
% OUTPUTS: prices    - 1×3, [price_T1 price_T2 price_T3] in EUR
%         std_errs  - 1×3, std errors in EUR (optional)

use_forward = nargin >= 7 && ~isempty(d) && ~isempty(div_dates);

payoffs = cell(1, 3);
prices  = zeros(1, 3);
for n = 1:3
    [~, idx] = min(abs(sim_dates - T_vec(n)));
    if use_forward
        K = pct * spot * prod(1 - d(div_dates <= T_vec(n)));
    else
        K = pct * spot;
    end
    payoffs{n} = max(K - S_paths(:, idx), 0);
    prices(n)  = mean(payoffs{n});
end

if nargout > 1
    N = size(S_paths, 1);
    std_errs = [std(payoffs{1}), std(payoffs{2}), std(payoffs{3})] / sqrt(N);
end
end
