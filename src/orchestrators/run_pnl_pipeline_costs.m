function pnl = run_pnl_pipeline_costs(portfolios, risk_results, vanilla_opt, mkt, N_CERT, spreads)
% RUN_PNL_PIPELINE_COSTS Same P&L explain as run_pnl_pipeline, but including the
% bid-offer transaction costs (passed via the spreads struct). Prints a header so
% it is clear the figures now account for transaction costs.
%
%   spreads - struct .cert/.van/.ssdf/.spot with full bid-offer spreads
%             (e.g. 0.005/0.002/0.001/0.0001).

    fprintf('\n%s\n  P&L EXPLAIN — WITH BID-OFFER TRANSACTION COSTS\n%s\n', ...
        repmat('=',1,60), repmat('=',1,60));

    pnl = run_pnl_pipeline(portfolios, risk_results, vanilla_opt, mkt, N_CERT, spreads);
end
