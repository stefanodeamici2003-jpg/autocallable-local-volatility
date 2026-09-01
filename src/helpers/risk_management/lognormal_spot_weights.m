function w = lognormal_spot_weights(spot_grid, S0, F_tau, sigma, tau)
% LOGNORMAL_SPOT_WEIGHTS Risk-neutral lognormal transition-density weights on a spot grid.
%
% Under r=0 with known proportional dividends, the risk-neutral drift is pinned by
% the forward, so  ln(S_tau/S0) ~ N(mu, s^2)  with
%     s^2 = sigma^2 * tau,   mu = ln(F_tau/S0) - 0.5*s^2     ( => E[S_tau] = F_tau ).
%
% INPUTS: spot_grid - 1×n vector of spot levels (need not be uniform)
%         S0        - scalar, current spot
%         F_tau     - scalar, forward to horizon tau
%         sigma     - scalar, ATMF implied vol at horizon tau
%         tau       - scalar, weighting horizon in years
% OUTPUTS: w         - 1×n weights w_k = pdf(S_k)*dS_k, normalised to sum 1
%                     (the dS_k spacing makes it a proper measure on non-uniform grids).

S   = spot_grid(:)';
s2  = sigma^2 * tau;
s   = sqrt(s2);
mu  = log(F_tau / S0) - 0.5 * s2;

pdf = 1 ./ (S * s * sqrt(2*pi)) .* exp(-(log(S / S0) - mu).^2 / (2 * s2));
dS  = gradient(S);                 % central-difference spacing (handles non-uniform grid)
w   = pdf .* dS;
w   = w / sum(w);
end
