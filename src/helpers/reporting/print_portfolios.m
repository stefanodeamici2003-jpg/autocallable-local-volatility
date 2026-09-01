function print_portfolios(portfolios, ts, N_CERT)
SEP    = repmat('─', 1, 72);
has_D  = isfield(portfolios, 'D');
n_cols = 3 + has_D;
DASH   = sprintf('%14s', '—');
W      = 19;
notional_total = abs(N_CERT) * ts.notional;
SEP2   = ['  ' repmat('─',1,W) repmat(['  ' repmat('─',1,14)],1,n_cols)];

P   = cellfun(@(name) portfolios.(name), [{'A','B','C'}, repmat({'D'}, 1, has_D)], 'UniformOutput', false);
yr  = [2026; 2027; 2028];
eur = @(x) fmt(x, 'eur');
rowfmt = ['  %-*s' repmat('  %s', 1, n_cols) '\n'];
prow   = @(label, vals) fprintf(rowfmt, W, label, vals{:});

fprintf('\n%s\n', SEP);
fprintf('  HEDGE PORTFOLIOS   short %d certs × €%.0fk = €%.1fM\n', ...
    abs(N_CERT), ts.notional/1e3, notional_total/1e6);
fprintf('%s\n', SEP);

hdr = arrayfun(@(k) sprintf('Portfolio %c', 'A'+k-1), 1:n_cols, 'UniformOutput', false);
fprintf(['  %-*s' repmat('  %14s',1,n_cols) '\n'], W, 'Instrument', hdr{:});
fprintf('%s\n', SEP2);

prow('ISP shares', cellfun(@(p) eur(p.h_spot),    P, 'UniformOutput', false));
prow('cost (EUR)', cellfun(@(p) eur(p.cost_spot), P, 'UniformOutput', false));
fprintf('%s\n', SEP2);

for i = 1:3
    prow(sprintf('SSDF %d (EUR)', yr(i)), [{DASH}, cellfun(@(p) eur(p.h_ssdf(i)), P(2:end), 'UniformOutput', false)]);
end
prow('SSDF total (EUR)', [{DASH}, cellfun(@(p) eur(p.cost_ssdf), P(2:end), 'UniformOutput', false)]);
fprintf('%s\n', SEP2);

prow('Vanilla (contracts)', [{DASH,DASH}, cellfun(@(p) eur(p.h_van),    P(3:end), 'UniformOutput', false)]);
prow('Vanilla cost (EUR)',  [{DASH,DASH}, cellfun(@(p) eur(p.cost_van), P(3:end), 'UniformOutput', false)]);
fprintf('%s\n', SEP2);

tot    = zeros(1, n_cols);
tot(1) = P{1}.cost_spot;
tot(2) = P{2}.cost_spot + P{2}.cost_ssdf;
for c = 3:n_cols
    tot(c) = P{c}.cost_spot + P{c}.cost_ssdf + P{c}.cost_van;
end
prow('TOTAL COST (EUR)', arrayfun(eur, tot, 'UniformOutput', false));
fprintf(['  %-*s' repmat('  %13.2f%%',1,n_cols) '\n'], W, sprintf('%% of €%.0fM', notional_total/1e6), ...
    tot/notional_total*100);
fprintf('%s\n', SEP2);

fprintf('  Net greeks (target = 0)\n');
fprintf('%s\n', SEP2);
fprintf(['  %-*s' repmat('  %14.4f',1,n_cols) '\n'], W, 'Delta', cellfun(@(p) p.net_delta, P));
for i = 1:3
    prow(sprintf('Div SSDF %d', yr(i)), ...
        [{DASH}, arrayfun(@(c) sprintf('%14.4f', P{c}.net_divsens(i)), 2:n_cols, 'UniformOutput', false)]);
end
prow('Vega', [{DASH,DASH}, arrayfun(@(c) sprintf('%14.4f', P{c}.net_vega), 3:n_cols, 'UniformOutput', false)]);
fprintf('%s\n\n', SEP);
end
