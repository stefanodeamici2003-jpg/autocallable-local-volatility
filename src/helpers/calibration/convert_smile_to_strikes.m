function [K, IV] = convert_smile_to_strikes(smile_M, smile_IV, S0)
% Convert vol smile from moneyness to absolute strikes.
% INPUTS: smile_M  - Nx1 vector, moneyness M = K/S0
%         smile_IV - Nx1 vector, implied volatilities
%         S0       - scalar, current spot price
% OUTPUTS: K        - Nx1 vector, absolute strikes = M * S0
%         IV       - Nx1 vector, implied volatilities (unchanged)

K  = smile_M * S0;
IV = smile_IV;
end
