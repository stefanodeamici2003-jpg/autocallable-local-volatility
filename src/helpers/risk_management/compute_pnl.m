function pnl = compute_pnl(portfolios, prices, N_CERT, spreads)
% COMPUTE_PNL P&L explain for hedged portfolios A, B, C, D at t1 and t2.
%
% Static hedge: ratios are built at t0 and held constant (no rebalancing).
%
% spreads (optional) - struct .cert/.van/.ssdf/.spot with full bid-offer spreads
%   (e.g. 0.005/0.002/0.001/0.0001). When given, a one-time transaction P&L is
%   added per portfolio (price-taker / worst case): we EARN half the cert spread
%   (sold to the client at offer) and PAY half the spread on EVERY hedge leg
%   (spot, SSDF, vanilla), regardless of trade direction.
%
% INPUTS:
%   portfolios  - struct with .A, .B, .C, and optionally .D hedge ratios
%   prices      - struct with fields:
%     .cert_t0, .cert_t1, .cert_t2       scalar, certificate price (EUR)
%     .van_t0,  .van_t1,  .van_t2        scalar, vanilla 3Y put price (EUR)
%     .van_opt_t0, .van_opt_t1, .van_opt_t2  (optional, for Portfolio D)
%     .spot_t0, .spot_t1, .spot_t2       scalar, stock spot price (EUR)
%     .ssdf_t0, .ssdf_t1, .ssdf_t2      3×1 vector, SSDF market prices (EUR)
%   N_CERT      - number of certificates (e.g. -200 for short position)
%
% OUTPUTS: pnl - struct with fields:
%   .A.t1, .A.t2   struct with P&L components (cert, spot, ssdf, van, total)
%   .B.t1, .B.t2
%   .C.t1, .C.t2
%   .D.t1, .D.t2   (optional)

if nargin < 4, spreads = []; end

% Helper: P&L components at time t
function pl = pnl_at_t(h_spot, h_ssdf, h_van, price_cert_t, price_van_t, ...
                        price_cert_t0, price_van_t0, spot_t, spot_t0, ...
                        ssdf_t, ssdf_t0)

    delta_cert =  N_CERT * (price_cert_t - price_cert_t0);   % short position (N_CERT is negative)
    delta_spot =  h_spot * (spot_t - spot_t0);
    delta_ssdf =  sum(h_ssdf .* (ssdf_t ./ ssdf_t0 - 1));    % h_ssdf is EUR notional
    delta_van  =  h_van  * (price_van_t - price_van_t0);

    % One-time bid-offer transaction P&L (price-taker / worst case):
    % earn half the cert spread (sold at offer), pay half the spread on every
    % hedge leg traded (cost on gross notional, regardless of direction).
    if isempty(spreads)
        tc = 0;
    else
        tc = +(spreads.cert/2) * abs(N_CERT * price_cert_t0) ...
             -(spreads.spot/2) * abs(h_spot * spot_t0) ...
             -(spreads.ssdf/2) * sum(abs(h_ssdf)) ...
             -(spreads.van /2) * abs(h_van  * price_van_t0);
    end

    pl.cert  = delta_cert;
    pl.spot  = delta_spot;
    pl.ssdf  = delta_ssdf;
    pl.van   = delta_van;
    pl.tcost = tc;
    pl.total = delta_cert + delta_spot + delta_ssdf + delta_van + tc;
end

% Portfolio A
for t_idx = [1, 2]
    if t_idx == 1
        [pc, pv, s, ssdf] = deal(prices.cert_t1, prices.van_t1, ...
            prices.spot_t1, prices.ssdf_t1);
    else
        [pc, pv, s, ssdf] = deal(prices.cert_t2, prices.van_t2, ...
            prices.spot_t2, prices.ssdf_t2);
    end
    
    comp = pnl_at_t(portfolios.A.h_spot, zeros(3,1), 0, pc, pv, ...
        prices.cert_t0, prices.van_t0, s, prices.spot_t0, ssdf, prices.ssdf_t0);
    
    if t_idx == 1; pnl.A.t1 = comp; else; pnl.A.t2 = comp; end
end

% Portfolio B
for t_idx = [1, 2]
    if t_idx == 1
        [pc, pv, s, ssdf] = deal(prices.cert_t1, prices.van_t1, ...
            prices.spot_t1, prices.ssdf_t1);
    else
        [pc, pv, s, ssdf] = deal(prices.cert_t2, prices.van_t2, ...
            prices.spot_t2, prices.ssdf_t2);
    end
    
    comp = pnl_at_t(portfolios.B.h_spot, portfolios.B.h_ssdf, 0, pc, pv, ...
        prices.cert_t0, prices.van_t0, s, prices.spot_t0, ssdf, prices.ssdf_t0);
    
    if t_idx == 1; pnl.B.t1 = comp; else; pnl.B.t2 = comp; end
end

% Portfolio C
for t_idx = [1, 2]
    if t_idx == 1
        [pc, pv, s, ssdf] = deal(prices.cert_t1, prices.van_t1, ...
            prices.spot_t1, prices.ssdf_t1);
    else
        [pc, pv, s, ssdf] = deal(prices.cert_t2, prices.van_t2, ...
            prices.spot_t2, prices.ssdf_t2);
    end
    
    comp = pnl_at_t(portfolios.C.h_spot, portfolios.C.h_ssdf, portfolios.C.h_van, pc, pv, ...
        prices.cert_t0, prices.van_t0, s, prices.spot_t0, ssdf, prices.ssdf_t0);
    
    if t_idx == 1; pnl.C.t1 = comp; else; pnl.C.t2 = comp; end
end

% Portfolio D
if isfield(portfolios, 'D') && isfield(prices, 'van_opt_t0')
    for t_idx = [1, 2]
        if t_idx == 1
            [pc, pvo, s, ssdf] = deal(prices.cert_t1, prices.van_opt_t1, ...
                prices.spot_t1, prices.ssdf_t1);
        else
            [pc, pvo, s, ssdf] = deal(prices.cert_t2, prices.van_opt_t2, ...
                prices.spot_t2, prices.ssdf_t2);
        end
        
        comp = pnl_at_t(portfolios.D.h_spot, portfolios.D.h_ssdf, portfolios.D.h_van, pc, pvo, ...
            prices.cert_t0, prices.van_opt_t0, s, prices.spot_t0, ssdf, prices.ssdf_t0);
        
        if t_idx == 1; pnl.D.t1 = comp; else; pnl.D.t2 = comp; end
    end
end
end
