function txbits = mapper(txbits, modulation_order)
% PSK Mapper
%
%   txbits = mapper(txbits, modulation_order)
%
%   txbits  : Information bits
%   modulation_order :  1 -> BPSK
%                       2 -> QPSK
%

switch modulation_order
    case 1 % BPSK
        txbits = 1 - 2 * txbits;
    case 2 % QPSK
       bits = 2*(txbits-0.5);
       txbits   = 1/sqrt(2)*(bits(1:2:end) + 1j*bits(2:2:end)); 
end