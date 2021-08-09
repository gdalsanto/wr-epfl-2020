function [rxbits] = demapper(rx, modulation_order)
% PSK Demapper
%
%   txbits = demapper(txbits, modulation_order)
%
%   txbits  : Information bits
%   modulation_order :  1 -> BPSK
%                       2 -> QPSK
%
switch modulation_order
    case 1 % BPSK
        rxbits = 1-(rx > 0);
    case 2 % QPSK
        
        % Convert noisy QPSK symbols into a bit vector. Hard decisions.
        a = rx(:); % Make sure "a" is a column vector
        b = [real(a) imag(a)] > 0;
        
        % Convert the matrix "b" to a vector, reading the elements of "b" rowwise.
        b = b.';
        b = b(:);
        
        rxbits = double(b); % Convert data type from logical to double
end