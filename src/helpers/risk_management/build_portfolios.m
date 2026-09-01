function portfolios = build_portfolios(greeks, mkt_t0, ts, N_CERT, vanilla_opt)
% Construct delta / dividend / vega hedge portfolios A, B, C, D for a SHORT position
% of N_CERT = -200 Autocallable Reverse Convertibles (notional €100k each = €20M total).
%
% All ratios are computed at t0 and held static (no rebalancing).
%
% Portfolio A: delta hedge   — ISP shares only
% Portfolio B: delta + div   — shares + SSDF contracts
% Portfolio C: delta+div+vega — shares + SSDF + ATMF 3Y vanilla put
% Portfolio D: delta+div+vega — shares + SSDF + optimal 3Y vanilla put
%
% INPUTS: greeks      - struct with fields: .cert, .vanilla, .ssdf
%         mkt_t0      - struct: spot, d (3×1), ssdf.{y2026,y2027,y2028}
%         ts          - term sheet (uses ts.notional for printing)
%         N_CERT      - scalar, number of certificates (e.g. -200 for short position)
%         vanilla_opt - optional struct with field .greeks for Portfolio D
% OUTPUTS: portfolios  - struct with substructs A, B, C and optionally D

if nargin < 5
    vanilla_opt = [];
end

risk_t0 = greeks.cert;
risk_t0.vanilla = greeks.vanilla;
van_delta = greeks.vanilla.delta;
ssdf_greeks = greeks.ssdf;
ssdf_greeks.delta_ssdf = greeks.ssdf.delta;
ssdf_greeks.vega_ssdf = greeks.ssdf.vega;

S0       = mkt_t0.spot;
ssdf_vec = [mkt_t0.ssdf.y2026; mkt_t0.ssdf.y2027; mkt_t0.ssdf.y2028];
notional_total = abs(N_CERT) * ts.notional;   % €20M

%% Portfolio A — delta hedge (ISP shares only)
h_spot_A    = -N_CERT * risk_t0.delta;
cost_spot_A = h_spot_A * S0;
net_delta_A = N_CERT * risk_t0.delta + h_spot_A;   % = 0 by construction

portfolios.A.h_spot    = h_spot_A;
portfolios.A.cost_spot = cost_spot_A;
portfolios.A.net_delta = net_delta_A;

%% Portfolio B — delta + dividend sensitivity hedge
% h_ssdf_contracts_B [contracts]: cancel certificate's div sensitivity exactly.
h_ssdf_contracts_B = -N_CERT * risk_t0.div_sens;       % 3×1, number of SSDF contracts per tenor
h_ssdf_B           = h_ssdf_contracts_B .* ssdf_vec;   % EUR of SSDF investment (cash value)
delta_da_SSDF      = sum(h_ssdf_contracts_B .* ssdf_greeks.delta_ssdf);

h_spot_B    = -(N_CERT * risk_t0.delta + delta_da_SSDF);
cost_spot_B = h_spot_B * S0;
cost_ssdf_B = sum(h_ssdf_B);                 % EUR (cost for SSDF instruments)

net_delta_B  = N_CERT * risk_t0.delta + h_spot_B + delta_da_SSDF;
net_divsens_B = N_CERT * risk_t0.div_sens + h_ssdf_contracts_B;   % = 0 by construction

portfolios.B.h_spot      = h_spot_B;
portfolios.B.h_ssdf      = h_ssdf_B;
portfolios.B.cost_spot   = cost_spot_B;
portfolios.B.cost_ssdf   = cost_ssdf_B;
portfolios.B.net_delta   = net_delta_B;
portfolios.B.net_divsens = net_divsens_B;

%% Portfolio C — delta + dividend + vega hedge
% h_van [contracts on 1 share each]: cancel certificate's parallel vega.
h_van    = -N_CERT * risk_t0.vega / risk_t0.vanilla.vega;
cost_van = h_van * risk_t0.vanilla.price;     % EUR

% SSDF hedge in C also absorbs the vanilla's div sensitivity so that
% net_divsens_C ≈ 0 (not just net_divsens_B ≈ 0 with vanilla residual).
h_ssdf_contracts_C = -N_CERT * risk_t0.div_sens - h_van * risk_t0.vanilla.div_sens;
h_ssdf_C           = h_ssdf_contracts_C .* ssdf_vec;   % EUR of SSDF investment (cash value)
delta_da_SSDF_C   = sum(h_ssdf_contracts_C .* ssdf_greeks.delta_ssdf);
delta_da_van      = h_van * van_delta;

h_spot_C    = -(N_CERT * risk_t0.delta + delta_da_SSDF_C + delta_da_van);
cost_spot_C = h_spot_C * S0;
cost_ssdf_C = sum(h_ssdf_C);

net_delta_C  = N_CERT * risk_t0.delta + h_spot_C + delta_da_SSDF_C + delta_da_van;
net_divsens_C = N_CERT * risk_t0.div_sens + h_ssdf_contracts_C + h_van * risk_t0.vanilla.div_sens;
net_vega_C   = N_CERT * risk_t0.vega + h_van * risk_t0.vanilla.vega;   % = 0 by construction

portfolios.C.h_spot      = h_spot_C;
portfolios.C.h_ssdf      = h_ssdf_C;
portfolios.C.h_van       = h_van;
portfolios.C.cost_spot   = cost_spot_C;
portfolios.C.cost_ssdf   = cost_ssdf_C;
portfolios.C.cost_van    = cost_van;
portfolios.C.net_delta   = net_delta_C;
portfolios.C.net_divsens = net_divsens_C;
portfolios.C.net_vega    = net_vega_C;

%% Portfolio D — delta + dividend + vega hedge with optimal vanilla
if ~isempty(vanilla_opt)
    opt_vanilla = vanilla_opt.greeks;

    % Same construction as Portfolio C, replacing the ATMF vanilla by the
    % selected optimal 3Y vanilla.
    h_van_D    = -N_CERT * risk_t0.vega / opt_vanilla.vega;
    cost_van_D = h_van_D * opt_vanilla.price;     % EUR

    h_ssdf_contracts_D = -N_CERT * risk_t0.div_sens - h_van_D * opt_vanilla.div_sens;
    h_ssdf_D           = h_ssdf_contracts_D .* ssdf_vec;   % EUR of SSDF investment (cash value)
    delta_da_SSDF_D   = sum(h_ssdf_contracts_D .* ssdf_greeks.delta_ssdf);
    delta_da_van_D    = h_van_D * opt_vanilla.delta;

    h_spot_D    = -(N_CERT * risk_t0.delta + delta_da_SSDF_D + delta_da_van_D);
    cost_spot_D = h_spot_D * S0;
    cost_ssdf_D = sum(h_ssdf_D);

    net_delta_D  = N_CERT * risk_t0.delta + h_spot_D + delta_da_SSDF_D + delta_da_van_D;
    net_divsens_D = N_CERT * risk_t0.div_sens + h_ssdf_contracts_D + h_van_D * opt_vanilla.div_sens;
    net_vega_D   = N_CERT * risk_t0.vega + h_van_D * opt_vanilla.vega;   % = 0 by construction

    portfolios.D.h_spot      = h_spot_D;
    portfolios.D.h_ssdf      = h_ssdf_D;
    portfolios.D.h_van       = h_van_D;
    portfolios.D.cost_spot   = cost_spot_D;
    portfolios.D.cost_ssdf   = cost_ssdf_D;
    portfolios.D.cost_van    = cost_van_D;
    portfolios.D.net_delta   = net_delta_D;
    portfolios.D.net_divsens = net_divsens_D;
    portfolios.D.net_vega    = net_vega_D;
    portfolios.D.vanilla     = vanilla_opt;
end

%% Print
print_portfolios(portfolios, ts, N_CERT);
end
