function d = bootstrap_dividends(spot, ssdf_vec)
% Bootstrap proportional dividend yields from SSDF prices.
% INPUTS: spot     - scalar, spot price
%         ssdf_vec - Nx1 vector, SSDF prices in chronological order
% OUTPUTS: d        - Nx1 vector, proportional dividend yields
% NOTE:   SSDF_i = d_i * E[S(tau_i^-)], where E[S(tau_i^-)] = spot * prod(1-d_j, j<i)
%         Sequential bootstrap: d_i = SSDF_i / F_i, then update F_i+1 = F_i*(1-d_i)

n = length(ssdf_vec);
d = zeros(n, 1);
F = spot;
for i = 1:n
    d(i) = ssdf_vec(i) / F;
    F    = F * (1 - d(i));
end
end
