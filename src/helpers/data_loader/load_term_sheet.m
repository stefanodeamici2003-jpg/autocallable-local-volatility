function [ts, dates] = load_term_sheet()
% LOAD_TERM_SHEET Defines contract specs, calibration and observation dates, and T_obs.
%
%   OUTPUTS:
%       ts    - Struct containing base term sheet specifications
%       dates - Struct containing calib_dates, div_dates, obs_dates, maturity, T_obs

    % Date specifications
    dates.calib_dates = [datetime(2026,3,5); datetime(2026,3,6); datetime(2026,3,9)];
    dates.div_dates   = [datetime(2026,5,18); datetime(2027,5,24); datetime(2028,5,22)];
    dates.obs_dates   = [datetime(2027,3,5); datetime(2028,3,5); datetime(2029,3,5)];
    dates.maturity    = datetime(2029,3,5);

    % T_obs(i,j) = yearfrac from calib_dates(i) to obs_dates(j), Act/365
    dates.T_obs = zeros(3, 3);
    for i = 1:3
        dates.T_obs(i,:) = yearfrac(dates.calib_dates(i), dates.obs_dates, 3)';
    end

    % Term sheet specifications (basic ones, non spot dependent)
    ts.notional     = 100000;
    ts.coupon_rate  = NaN;
    ts.barrier_pct  = 0.70;
    ts.coupon_pct   = 0.70;
end
