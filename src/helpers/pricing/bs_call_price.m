function C = bs_call_price(S, K, T, sigma)
% Black-Scholes call price with r = 0. Vectorized over K.
% INPUTS: S     - scalar, spot price
%         K     - scalar or vector, strike(s)
%         T     - scalar, time to maturity in years
%         sigma - scalar, volatility
% OUTPUTS: C     - same size as K, call price(s)

if sigma * sqrt(T) < 1e-10
    C = max(S - K, 0);
    return;
end
d1 = (log(S./K) + 0.5*sigma^2*T) / (sigma*sqrt(T));
C  = S.*normcdf(d1) - K.*normcdf(d1 - sigma*sqrt(T));
end
