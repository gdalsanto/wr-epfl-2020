function [txsignal conf] = tx(txbits,conf,k)
% Digital Transmitter
%
%   [txsignal conf] = tx(txbits,conf,k) implements a complete transmitter
%   consisting of:
%       - modulator
%       - conditioning
%       - up converter
%   in digital domain.
%
%   txbits  : Information bits
%   conf    : Universal configuration structure
%   k       : Frame index
%

% 1. Fit the data according to the number of carriers
% the length of the data is ajusted by adding random bits
total_nbits = conf.nsymbs*conf.ncarriers*conf.modulation_order;     % expected number of bits
txbits = [txbits; randi([0 1],total_nbits-conf.nbits,1)];

% 2. Mapping
txsymb = mapper(txbits, conf.modulation_order);

% 3. Training symbols insertion 
[txsymb, conf] = train_insertion(txsymb, conf);

% save transmitted symbols for detailed channel analysis 
conf.txsymb = txsymb;   

% 4. OFDM Modulation
ofdm_symb = ofdm_modulation(txsymb, conf);

% 5. Parallel to Series
ofdm_symb = ofdm_symb(:);
 
% 6. Preamble insertion
preamble = conv(upsample(conf.preamble, conf.os_factor_pre), conf.pulse','same');

% 7. Power normalization 
P_pre = mean(abs(preamble).^2);         % preamble power
P_ofdm = mean(abs(ofdm_symb).^2);       % ofdm symbol power
% normalized transmitted signal 
txsignal = [preamble/sqrt(P_pre); ofdm_symb/sqrt(P_ofdm)];

% 8. Up-conversion
t = 0:1/conf.f_s: (length(txsignal) - 1)/conf.f_s;
% transmitted signal
txsignal = real(txsignal .* exp(1j*2*pi*conf.f_c*t'));

% plots
figure('name','txsignal-spectrum');
f = - conf.f_s/2 : conf.f_s/length(txsignal) : conf.f_s/2 - conf.f_s/length(txsignal);
plot(f,abs(fftshift(fft(txsignal))))
grid on
title('Transmitted signal - FFT','interpreter','latex','FontSize',16);
xlabel('frequency/Hz','interpreter','latex','FontSize',16);
ylabel('amplitude','interpreter','latex','FontSize',16);
xline(conf.f_c,'--r'); xline(- conf.f_c,'--r');
