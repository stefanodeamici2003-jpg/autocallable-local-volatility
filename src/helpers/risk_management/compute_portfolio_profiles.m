function port_profiles = compute_portfolio_profiles( ...
    profile_cert, profile_van, portfolios, N_CERT, profile_van_opt)
% COMPUTE_PORTFOLIO_PROFILES Combine cert and vanilla risk profiles with hedge
% ratios to obtain the net vega and div sensitivity of each hedged portfolio.
%
% Portfolios A/B have no vanilla leg, so their vega profile equals that of the
% unhedged short cert.  Portfolio C (and D if present) adds the vanilla
% contribution using the ratios from build_portfolios.
%
% INPUTS:
%   profile_cert  - output of compute_risk_profile (autocallable)
%   profile_van   - output of compute_risk_profile (Portfolio C vanilla)
%   portfolios    - struct with .A, .B, .C (and optionally .D) hedge ratios
%   N_CERT        - number of short certificates (e.g. 200)
%   profile_van_opt - optional output of compute_risk_profile for Portfolio D

if nargin < 5 || isempty(profile_van_opt)
    profile_van_opt = profile_van;
end

n_spot = numel(profile_cert.spot_grid);

% Portfolio A — delta hedge (shares only)
port_profiles.A.vega        = N_CERT * profile_cert.vega;
port_profiles.A.vega_se     = abs(N_CERT) * profile_cert.vega_se;
port_profiles.A.div_sens    = N_CERT * profile_cert.div_sens;
port_profiles.A.div_sens_se = abs(N_CERT) * profile_cert.div_sens_se;

% Portfolio B — delta + SSDF (div hedged at S0; vega unhedged)
port_profiles.B.vega        = port_profiles.A.vega;
port_profiles.B.vega_se     = port_profiles.A.vega_se;
[~, idx_s0]                 = min(abs(profile_cert.spot_grid - profile_cert.spot_t0));
port_profiles.B.div_sens    = N_CERT * (profile_cert.div_sens - profile_cert.div_sens(:, idx_s0));
port_profiles.B.div_sens_se = abs(N_CERT) * profile_cert.div_sens_se;

% Portfolio C — delta + SSDF + ATMF 3Y vanilla
h_van_C = portfolios.C.h_van;
port_profiles.C.vega        = N_CERT * profile_cert.vega + h_van_C * profile_van.vega;
port_profiles.C.vega_se     = abs(N_CERT) * profile_cert.vega_se + abs(h_van_C) * profile_van.vega_se;
port_profiles.C.div_sens    = N_CERT * profile_cert.div_sens + portfolios.C.h_ssdf + h_van_C * profile_van.div_sens;
port_profiles.C.div_sens_se = abs(N_CERT) * profile_cert.div_sens_se + abs(h_van_C) * profile_van.div_sens_se;

% Portfolio D — delta + SSDF + optimal vanilla
% If the optimal vanilla is the same instrument as in C, Portfolio D = C.
% If portfolios.D is defined with a different vanilla, use it here;
if isfield(portfolios, 'D')
    h_van_D = portfolios.D.h_van;
    port_profiles.D.vega        = N_CERT * profile_cert.vega ...
                                  +  h_van_D * profile_van_opt.vega;
    port_profiles.D.vega_se     = abs(N_CERT) * profile_cert.vega_se ...
                                  + abs(h_van_D) * profile_van_opt.vega_se;
    port_profiles.D.div_sens    = N_CERT * profile_cert.div_sens ...
                                  +  portfolios.D.h_ssdf ...
                                  +  h_van_D * profile_van_opt.div_sens;
    port_profiles.D.div_sens_se = abs(N_CERT) * profile_cert.div_sens_se ...
                                  + abs(h_van_D) * profile_van_opt.div_sens_se;
end
end
