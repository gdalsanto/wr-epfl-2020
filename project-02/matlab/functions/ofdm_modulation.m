function ofdm_symb = ofdm_modulation(symbols, conf)
% OFDM modulator
%
%   ofdm_symb = ofdm_modulation(symbols, conf)
%
%   symbols : data symbols 
%   conf    : universal configuration structure
%   ofdm_symb : ODFM symbols with cyclic prefix 

    ofdm_symb = zeros((conf.ncarriers + conf.cp_length)*conf.os_factor,size(symbols,2));
    for i = 1 : size(symbols,2)
        % ifft
        ofdm_symb(conf.os_factor*conf.cp_length+1:end,i) = osifft(symbols(:,i),conf.os_factor);
        % cyclic prefix
        ofdm_symb(1:conf.os_factor*conf.cp_length,i) = ofdm_symb(end-conf.os_factor*conf.cp_length+1:end,i);
    end
end