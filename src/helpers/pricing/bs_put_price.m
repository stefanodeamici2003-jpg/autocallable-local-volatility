function P = bs_put_price(S, K, T, sigma)
% Black-Scholes put price with r = 0, via put-call parity. Vectorized over K.
% INPUTS: S     - scalar, spot price
%         K     - scalar or vector, strike(s)
%         T     - scalar, time to maturity in years
%         sigma - scalar, volatility
% OUTPUTS: P     - same size as K, put price(s)

P = bs_call_price(S, K, T, sigma) - S + K;
end
