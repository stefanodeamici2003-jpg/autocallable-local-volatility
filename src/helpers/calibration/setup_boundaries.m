function [S_low, S_high] = setup_boundaries(forward, sigma_atm, T, std_val)
% Compute LV grid bounds at ±std_val standard deviations of the forward in log-strike.
% Nodes are then placed inside [S_low, S_high] by select_adaptive_nodes.
% INPUTS: forward   - scalar, forward price at maturity
%         sigma_atm - scalar, ATM implied volatility
%         T         - scalar, time to maturity in years
%         std_val   - scalar, half-width in standard deviations
% OUTPUTS: S_low     - scalar, lower bound
%         S_high    - scalar, upper bound

hw     = std_val * sigma_atm * sqrt(T);
S_low  = forward * exp(-hw);
S_high = forward * exp(hw);
end
