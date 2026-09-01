function F = compute_forward(spot, d, div_dates, target_date)
% Forward price at target_date with discrete proportional dividends.
% INPUTS: spot        - scalar, current spot price
%         d           - Nx1 vector, proportional dividend yields
%         div_dates   - Nx1 datetime, ex-dividend dates
%         target_date - datetime scalar, target date
% OUTPUTS: F           - scalar, forward price

F = spot * prod(1 - d(div_dates <= target_date));
end
