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

% 1. Down-conversion
t = 0 : 1/conf.f_s : (length(rxsignal)-1)/conf.f_s;
rxsignal = rxsignal.*exp(-1j*2*pi*(conf.f_c * t'));
f_corner = 1.05*conf.bw;
filtered_rxsignal = 2*ofdmlowpass(rxsignal, conf, f_corner);

% 2. Frame synchronization
data_idx = frame_sync(filtered_rxsignal, conf);  % Index of the first data symbol
ndata = conf.os_factor*(conf.ncarriers + conf.cp_length)*conf.tot_symb; 
filtered_rxsignal = filtered_rxsignal(data_idx:data_idx + ndata - 1);

% 3. Series to Parallel
rxsignal_p = reshape(filtered_rxsignal , [conf.os_factor*(conf.ncarriers + conf.cp_length),conf.tot_symb] );

% 4. CP removal
rxsignal_p(1:conf.os_factor*conf.cp_length,:) = [];

% 5. OFDM demodulation
for i = 1 : conf.tot_symb
    rxsymbol(:,i) = osfft(rxsignal_p(:,i),conf.os_factor);
end

% 6. Channel estimation and equalization
[payload_data, H_hat, conf] = channel_equalization(rxsymbol, conf);

% plot 
show_plots(payload_data, rxsymbol, H_hat, conf)

% 7. Parallel to Series
payload_data = payload_data(:);

% discard uninformative bits that were added to fill the carriers 
total_nbits = conf.nsymbs*conf.ncarriers*conf.modulation_order; % expected number of bits
payload_data(end-((total_nbits-conf.nbits)/conf.modulation_order)+1:end) = [];

% 7. Demapping
rxbits = demapper(payload_data,conf.modulation_order);
