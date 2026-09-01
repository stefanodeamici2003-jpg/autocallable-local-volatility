function print_pnl(pnl, mkt, N_CERT)
SEP    = repmat('─', 1, 72);
notional_total = abs(N_CERT) * 100000;
has_D  = isfield(pnl, 'D');
DASH   = sprintf('%14s', '—');
W0     = 15;
n_cols = 3 + has_D;
TSEP   = ['  ' repmat('─',1,15) repmat(['  ' repmat('─',1,14)],1,n_cols)];

rowfmt = ['  %-*s' repmat('  %s', 1, n_cols) '\n'];
prow   = @(label, vals) fprintf(rowfmt, W0, label, vals{:});
hdr    = arrayfun(@(k) sprintf('Portfolio %c', 'A'+k-1), 1:n_cols, 'UniformOutput', false);

fprintf('\n%s\n', SEP);
fprintf('  <strong>P&L EXPLAIN</strong>   Static hedge built at t0 = <strong>%s</strong>\n', mkt{1}.date);
fprintf('%s\n', SEP);

for t_idx = 1:2
    m0  = mkt{1};
    mt  = mkt{t_idx + 1};
    fld = sprintf('t%d', t_idx);
    P   = cellfun(@(name) pnl.(name).(fld), [{'A','B','C'}, repmat({'D'}, 1, has_D)], 'UniformOutput', false);

    ssdf0 = [m0.ssdf.y2026; m0.ssdf.y2027; m0.ssdf.y2028];
    ssdft = [mt.ssdf.y2026; mt.ssdf.y2027; mt.ssdf.y2028];
    yr    = [2026; 2027; 2028];

    fprintf('  <strong>t%d = %s</strong>   Spot: <strong>%.4f</strong> → <strong>%.4f</strong>  (%+.1f%%)\n', ...
        t_idx, mt.date, m0.spot, mt.spot, (mt.spot/m0.spot - 1)*100);
    for i = 1:3
        fprintf('  SSDF %d:  %.4f → %.4f  (%+.1f%%)\n', yr(i), ...
            ssdf0(i), ssdft(i), (ssdft(i)/ssdf0(i)-1)*100);
    end
    fprintf('%s\n', SEP);

    fprintf(['  %-*s' repmat('  %14s',1,n_cols) '\n'], W0, 'Component', hdr{:});
    fprintf('%s\n', TSEP);
    prow('Cert P&L',    cellfun(@(p) fmt(p.cert,'eur'), P, 'UniformOutput', false));
    prow('Spot P&L',    cellfun(@(p) fmt(p.spot,'eur'), P, 'UniformOutput', false));
    prow('SSDF P&L',    [{DASH},       cellfun(@(p) fmt(p.ssdf,'eur'), P(2:end), 'UniformOutput', false)]);
    prow('Vanilla P&L', [{DASH, DASH}, cellfun(@(p) fmt(p.van,'eur'),  P(3:end), 'UniformOutput', false)]);
    if isfield(P{1}, 'tcost')
        prow('Txn cost', cellfun(@(p) fmt(p.tcost,'eur'), P, 'UniformOutput', false));
    end
    fprintf('%s\n', TSEP);
    prow('NET P&L', cellfun(@(p) fmt(p.total,'eur'), P, 'UniformOutput', false));
    fprintf(['  %-*s' repmat('  %13.2f%%',1,n_cols) '\n'], W0, '%% notional', ...
        cellfun(@(p) p.total/notional_total*100, P));
    fprintf('%s\n', SEP);
end
fprintf('\n');
end
