function pnl = run_pnl_pipeline(portfolios, risk_results, vanilla_opt, mkt, N_CERT, spreads)
% RUN_PNL_PIPELINE Compiles prices and executes the P&L Explain reporting module.
%
%   INPUTS:
%       portfolios   - Struct containing portfolios weights and configurations
%       risk_results - Cell array of Greeks structures for each valuation date
%       vanilla_opt  - Struct containing optimal vanilla contract parameters and Greeks
%       mkt          - Cell array of market data structures
%       N_CERT       - Quantity of certificate to hedge (e.g., -200)
%       spreads      - Optional bid-offer struct (.cert/.van/.ssdf/.spot); [] = no costs
%
%   OUTPUTS:
%       pnl          - Struct containing detailed P&L explain attribution results

    prices_struct.cert_t0  = risk_results{1}.cert.price;
    prices_struct.cert_t1  = risk_results{2}.cert.price;
    prices_struct.cert_t2  = risk_results{3}.cert.price;
    
    prices_struct.van_t0   = risk_results{1}.vanilla.price;
    prices_struct.van_t1   = risk_results{2}.vanilla.price;
    prices_struct.van_t2   = risk_results{3}.vanilla.price;
    
    prices_struct.van_opt_t0 = vanilla_opt.all_greeks{1}.price;
    prices_struct.van_opt_t1 = vanilla_opt.all_greeks{2}.price;
    prices_struct.van_opt_t2 = vanilla_opt.all_greeks{3}.price;
    
    prices_struct.spot_t0  = mkt{1}.spot;
    prices_struct.spot_t1  = mkt{2}.spot;
    prices_struct.spot_t2  = mkt{3}.spot;
    
    prices_struct.ssdf_t0  = [mkt{1}.ssdf.y2026; mkt{1}.ssdf.y2027; mkt{1}.ssdf.y2028];
    prices_struct.ssdf_t1  = [mkt{2}.ssdf.y2026; mkt{2}.ssdf.y2027; mkt{2}.ssdf.y2028];
    prices_struct.ssdf_t2  = [mkt{3}.ssdf.y2026; mkt{3}.ssdf.y2027; mkt{3}.ssdf.y2028];

    if nargin < 6, spreads = []; end

    pnl = compute_pnl(portfolios, prices_struct, N_CERT, spreads);
    print_pnl(pnl, mkt, N_CERT);
end
