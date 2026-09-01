function payoffs = payoff_autocallable(S_paths, sim_dates, ts)
% Path-wise payoffs for the Knock-In Autocallable Reverse Convertible.
% INPUTS: S_paths   - N_paths×N_sim, simulated paths
%         sim_dates - 1×N_sim, dates in years from t0
%         ts        - struct: strike, barrier, autocall_lvl, coupon_level,
%                             coupon_rate, notional, T1, T2, T3
% OUTPUTS: payoffs   - N_paths×1, total EUR payoff per path (r=0, no discounting)

N_paths = size(S_paths, 1);

[~, idx1] = min(abs(sim_dates - ts.T1));
[~, idx2] = min(abs(sim_dates - ts.T2));
[~, idx3] = min(abs(sim_dates - ts.T3));

S1 = S_paths(:, idx1);
S2 = S_paths(:, idx2);
S3 = S_paths(:, idx3);

payoffs    = zeros(N_paths, 1);
memory     = zeros(N_paths, 1);
alive      = true(N_paths, 1);
coupon_eur = ts.coupon_rate * ts.notional;

% Year 1
memory(alive) = memory(alive) + coupon_eur;
pays = alive & (S1 >= ts.coupon_level);
payoffs(pays) = payoffs(pays) + memory(pays);
memory(pays)  = 0;
ac = alive & (S1 >= ts.autocall_lvl);
payoffs(ac) = payoffs(ac) + ts.notional;
alive(ac)   = false;

% Year 2
memory(alive) = memory(alive) + coupon_eur;
pays = alive & (S2 >= ts.coupon_level);
payoffs(pays) = payoffs(pays) + memory(pays);
memory(pays)  = 0;
ac = alive & (S2 >= ts.autocall_lvl);
payoffs(ac) = payoffs(ac) + ts.notional;
alive(ac)   = false;

% Year 3
memory(alive) = memory(alive) + coupon_eur;
pays = alive & (S3 >= ts.coupon_level);
payoffs(pays) = payoffs(pays) + memory(pays);
memory(pays)  = 0;
no_ki = alive & (S3 >= ts.barrier);
ki    = alive & (S3 <  ts.barrier);
payoffs(no_ki) = payoffs(no_ki) + ts.notional;
payoffs(ki)    = payoffs(ki)    + ts.notional .* S3(ki) ./ ts.strike;

end
