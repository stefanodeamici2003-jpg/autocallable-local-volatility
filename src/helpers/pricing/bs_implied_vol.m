function sigma = bs_implied_vol(S, K, T, price, is_call)
% Implied volatility via Newton-Raphson (r = 0). Scalar inputs only.
% INPUTS: S       - scalar, forward price (with r = 0 the option is priced off the
%                   forward, so pass F here, not spot)
%         K       - scalar, strike
%         T       - scalar, time to maturity in years
%         price   - scalar, observed option price
%         is_call - logical, true for call, false for put (default: true)
% OUTPUTS: sigma   - scalar, implied vol (NaN if outside no-arb bounds or no convergence)
% NOTE:   put prices are converted to call via put-call parity before inversion

if nargin < 5, is_call = true; end

if ~is_call
    price = price + S - K;
end

if price < max(S - K, 0) - 1e-10 || price > S + 1e-10
    sigma = NaN;
    return;
end

% Brenner-Subrahmanyam ATM approximation as initial guess, floored at 0.15
% to avoid starting in a region where vega is numerically zero.
sigma = max(0.15, price * sqrt(2*pi/T) / S);

sqrtT = sqrt(T);
tol   = 1e-12;
for iter = 1:100
    st   = sigma * sqrtT;
    d1   = (log(S/K) + 0.5*sigma^2*T) / st;
    C    = S*normcdf(d1) - K*normcdf(d1 - st);
    vega = S * sqrtT * normpdf(d1);
    err  = C - price;
    if abs(err) < tol, return; end
    if vega < 1e-12, break; end  % deep OTM: vega → 0, Newton-Raphson diverges
    sigma = max(0.001, min(5.0, sigma - err/vega));
end

if abs(bs_call_price(S, K, T, sigma) - price) > 1e-5
    sigma = NaN;
end
end
