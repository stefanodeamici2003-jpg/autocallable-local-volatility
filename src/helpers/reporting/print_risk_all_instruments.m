function print_risk_all_instruments(risk_res, mkt, ts, Z_95)
if nargin < 4; Z_95 = 1.96; end

SEP = repmat('─', 1, 72);
W1  = 16;
c   = @(x) strtrim(fmt(x, 'eur'));    % certificate: large EUR values
c4  = @(x) strtrim(fmt(x, 'eur4'));   % vanilla / SSDF: O(1) per-contract values
ssdf_years = {'SSDF 2026', 'SSDF 2027', 'SSDF 2028'};

fprintf('\n%s\n', SEP);
fprintf('  <strong>RISK GREEKS</strong>   <strong>%s</strong>   spot = <strong>%.4f</strong> EUR   bump = 1%%\n', mkt.date, mkt.spot);
fprintf('%s\n', SEP);

% Certificate
cert = risk_res.cert;
fprintf('\n  <strong>CERTIFICATE</strong>\n');
fprintf('  %-*s  %-20s  %s\n', W1, 'Greek', 'Value', '95% CI');
fprintf('%s\n', SEP);
fprintf('  %-*s  %s EUR\n',          W1, 'Price', c(cert.price));
fprintf('  %-*s  %.2f%% notional\n', W1, '',      cert.price / ts.notional * 100);
fprintf('  %-*s  [%s , %s] EUR\n',   W1, '',      c(cert.price - Z_95*cert.price_se), c(cert.price + Z_95*cert.price_se));
fprintf('\n');
fprintf('  %-*s  %s EUR/EUR    [%s , %s]\n', W1, 'Delta', ...
    c(cert.delta), c(cert.delta - Z_95*cert.delta_se), c(cert.delta + Z_95*cert.delta_se));
fprintf('\n');
fprintf('  %-*s  %s EUR/pp     [%s , %s] EUR/pp\n', W1, 'Vega', ...
    c(cert.vega), c(cert.vega - Z_95*cert.vega_se), c(cert.vega + Z_95*cert.vega_se));
fprintf('%s\n', SEP);
print_divsens(cert, c, W1, SEP, Z_95, ssdf_years);

% Vanilla Put
van = risk_res.vanilla;
fprintf('\n  <strong>VANILLA PUT</strong>   (ATMF 3Y, per contract)\n');
fprintf('  %-*s  %-20s  %s\n', W1, 'Greek', 'Value', '95% CI');
fprintf('%s\n', SEP);
fprintf('  %-*s  %s EUR    [%s , %s] EUR\n', W1, 'Price', ...
    c4(van.price), c4(van.price - Z_95*van.price_se), c4(van.price + Z_95*van.price_se));
fprintf('  %-*s  %+8.4f    [%+8.4f , %+8.4f]\n', W1, 'Delta', ...
    van.delta, van.delta - Z_95*van.delta_se, van.delta + Z_95*van.delta_se);
fprintf('  %-*s  %s EUR/pp    [%s , %s] EUR/pp\n', W1, 'Vega', ...
    c4(van.vega), c4(van.vega - Z_95*van.vega_se), c4(van.vega + Z_95*van.vega_se));
fprintf('%s\n', SEP);
print_divsens(van, c4, W1, SEP, Z_95, ssdf_years);

% SSDF Contracts
fprintf('\n  <strong>SSDF CONTRACTS</strong>   (delta ≈ 0, vega ≈ 0 by construction)\n');
fprintf('  %-*s  %s\n', W1, 'Instrument', 'Price (EUR)');
fprintf('%s\n', SEP);
yr = [2026; 2027; 2028];
for i = 1:3
    fprintf('  %-*s  %s EUR\n', W1, sprintf('SSDF %d', yr(i)), c4(risk_res.ssdf.price(i)));
end
fprintf('%s\n\n', SEP);
end

function print_divsens(X, fmtfn, W1, SEP, Z_95, ssdf_years)
fprintf('  Div Sensitivity  (EUR per EUR of SSDF)\n');
fprintf('%s\n', SEP);
for i = 1:3
    lo = X.div_sens(i) - Z_95*X.div_sens_se(i);
    hi = X.div_sens(i) + Z_95*X.div_sens_se(i);
    fprintf('  %-*s  %s    [%s , %s]\n', W1, ssdf_years{i}, fmtfn(X.div_sens(i)), fmtfn(lo), fmtfn(hi));
end
fprintf('%s\n', SEP);
end
