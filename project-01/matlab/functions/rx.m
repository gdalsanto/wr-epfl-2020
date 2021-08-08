function [rxbits conf] = rx(rxsignal,conf,k)
% Digital Receiver
%
%   [txsignal conf] = tx(txbits,conf,k) implements a complete causal
%   receiver in digital domain.
%
%   rxsignal    : received signal
%   conf        : configuration structure
%   k           : frame index
%
%   Outputs
%
%   rxbits      : received bits
%   conf        : configuration structure

% Down-conversion
t = 0:1/conf.f_s:(length(rxsignal)-1)/conf.f_s;
rxsignal = rxsignal .* exp(-1j*2*pi*(conf.f_c + conf.offset) * t');
rxsignal = 2*lowpass(rxsignal, conf);

% Matched filter
filtered_rx_signal = conv(rxsignal, conf.pulse,'same');

% Frame synchronization
[data_idx, theta0] = frame_sync(filtered_rx_signal, conf);  % Index of the first data symbol
payload_data = zeros(conf.data_length, 1);                  

% Phase correction
theta_hat = zeros(conf.data_length, 1);                     % estimated phase           
theta_hat(1) = theta0;                                      % initial phase estimator
data_phase_error = zeros(conf.data_length, 1);              % not corrected symbols

for k = 1 : conf.data_length
    
    payload_data(k) = filtered_rx_signal(data_idx);
    data_phase_error(k) = payload_data(k);
    % Phase estimation    
    % viterbi-viterbi algorithm
    deltaTheta = 1/4*angle(-payload_data(k)^4) + pi/2*(-1:4);
    [~, ind] = min(abs(deltaTheta - theta_hat(k)));
    theta0 = deltaTheta(ind);
    
    % Lowpass filter phase
    theta_hat(k+1) = mod(0.01*theta0 + 0.99*theta_hat(k), 2*pi);
    
    % Phase correction
    payload_data(k) = payload_data(k) * exp(-1j * theta_hat(k+1));  
    
    % Down-sampling 
    data_idx = data_idx + conf.os_factor;
end
rxbits = demapper(payload_data,conf.modulation_order);
