function [txsymb, conf] = train_insertion(txsymb, conf)
% Training symbols insertion
%
%   [txsymb, conf] = train_insertion(txsymb, conf)
%
%   txsymb  : data symbols (not ofdm modulated)
%   conf    : Universal configuration structure
%

if conf.training_type == 2
    % comb-trype training 
    indx_e = [1 : 2 : conf.ncarriers];
    indx_o = [2 : 2 : conf.ncarriers];
    conf.train_even = conf.training(indx_e);
    conf.train_odd = conf.training(indx_o);
    for i = 1 : 2*conf.nsymbs
        sym_start = (i-1)*conf.ncarriers/2 + 1;
        sym_end = i*conf.ncarriers/2;
        if mod(i,2) ~= 0
            temp(indx_e,i) = txsymb(sym_start:sym_end);
            temp(indx_o,i) = conf.train_odd;
        else
            temp(indx_o,i) = txsymb(sym_start:sym_end);
            temp(indx_e,i) = conf.train_even;
        end
    end
    txsymb = temp;
else
    % block-type training
    % series to parallel
    txsymb = reshape(txsymb,[conf.ncarriers conf.nsymbs]);
    for i = 0 : conf.npilots - 1
        if i == 0
           txsymb = [conf.training, txsymb];
        else 
           indx = i*conf.pilot_int+i;
           txsymb = [txsymb(:,1:indx), conf.training, txsymb(:,indx + 1 : end)];
        end
    end      
end