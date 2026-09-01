function print_pricing(p, notional, Z_95)
if nargin < 3; Z_95 = 1.96; end

SEP  = repmat('─', 1, 72);
SEP3 = ['  ' repmat('─',1,11) repmat(['  ' repmat('─',1,13)],1,3)];

fprintf('\n%s\n', SEP);
fprintf('  <strong>MONTE CARLO PRICING</strong>   <strong>%s</strong>   spot = <strong>%.4f</strong> EUR\n', p.date, p.spot);
fprintf('%s\n', SEP);

put_block('Put ATMF', p.lv_atmf, Z_95*p.se_lv_atmf, p.bs_atmf, p.an_atmf, p.spot, SEP3);
put_block('Put 80%',  p.lv_80,   Z_95*p.se_lv_80,   p.bs_80,   p.an_80,   p.spot, SEP3);

% Autocallable
SEP_AC = ['  ' repmat('─',1,11) '  ' repmat('─',1,13) '  ' repmat('─',1,19)];
fprintf('\n  <strong>Autocallable</strong> (%% of notional)\n');
fprintf('%s\n', SEP_AC);
fprintf('  %-11s  %13s  %s\n', 'Model', 'Price', '95% CI');
fprintf('%s\n', SEP_AC);

lv_ac_pct = p.lv_ac / notional * 100;
bs_ac_pct = p.bs_ac / notional * 100;
fprintf('  %-11s  %12.2f%%  [%7.2f , %7.2f]\n', 'LV-MC', lv_ac_pct, ...
    (p.lv_ac - Z_95*p.se_lv_ac) / notional * 100, (p.lv_ac + Z_95*p.se_lv_ac) / notional * 100);
fprintf('  %-11s  %12.2f%%  [%7.2f , %7.2f]\n', 'BS-MC', bs_ac_pct, ...
    (p.bs_ac - Z_95*p.se_bs_ac) / notional * 100, (p.bs_ac + Z_95*p.se_bs_ac) / notional * 100);
fprintf('%s\n\n', SEP_AC);
end

function put_block(title, lv, lv_ci_abs, bs, an, spot, SEP3)
lv_pct = lv / spot * 100;
lv_ci  = lv_ci_abs / spot * 100;
bs_pct = bs / spot * 100;
an_pct = an / spot * 100;

fprintf('\n  <strong>%s</strong> (%% of spot)\n', title);
fprintf('%s\n', SEP3);
fprintf('  %-11s  %13s  %13s  %13s\n', 'Model', '1Y', '2Y', '3Y');
fprintf('%s\n', SEP3);
fprintf('  %-11s  %12.2f%%  %12.2f%%  %12.2f%%\n', 'LV-MC', lv_pct(1), lv_pct(2), lv_pct(3));
fprintf('  %-11s  [%5.2f,%5.2f]  [%5.2f,%5.2f]  [%5.2f,%5.2f]\n', 'CI 95%%', ...
    lv_pct(1)-lv_ci(1), lv_pct(1)+lv_ci(1), ...
    lv_pct(2)-lv_ci(2), lv_pct(2)+lv_ci(2), ...
    lv_pct(3)-lv_ci(3), lv_pct(3)+lv_ci(3));
fprintf('  %-11s  %12.2f%%  %12.2f%%  %12.2f%%\n', 'BS-MC', bs_pct(1), bs_pct(2), bs_pct(3));
fprintf('  %-11s  %12.2f%%  %12.2f%%  %12.2f%%\n', 'BS-an', an_pct(1), an_pct(2), an_pct(3));
fprintf('%s\n', SEP3);
end
