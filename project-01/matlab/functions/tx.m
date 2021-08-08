function [txsignal conf] = tx(txbits,conf,k)
% Digital Transmitter
%
%   [txsignal conf] = tx(txbits,conf,k) implements a complete transmitter
%   consisting of:
%       - modulator
%       - pulse shaping filter
%       - up converter
%   in digital domain.
%
%   txbits  : Information bits
%   conf    : Universal configuration structure
%   k       : Frame index
%

% Preamble
symbols = [conf.preamble; mapper(txbits, conf.modulation_order)];

% Oversample
symbols = upsample(symbols, conf.os_factor);

% Pulse shaping
txsignal = conv(symbols, conf.pulse','same');

% Up-conversion
t = 0:1/conf.f_s: (length(txsignal) - 1)/conf.f_s;
txsignal = real(txsignal .* exp(1j*2*pi*conf.f_c*t'));
