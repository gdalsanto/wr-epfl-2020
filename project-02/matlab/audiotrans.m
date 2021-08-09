clear all; close all; clc
addpath ./functions
% % % % %
% Wireless Receivers: algorithms and architectures
% Audio Transmission Framework 
%
%
%   3 operating modes:
%   - 'matlab' : generic MATLAB audio routines (unreliable under Linux)
%   - 'native' : OS native audio system
%       - ALSA audio tools, most Linux distrubtions
%       - builtin WAV tools on Windows 
%   - 'bypass' : no audio transmission, takes txsignal as received signal
nframe = 1;
for i = 1:length(nframe)
    
    % -------------------------------------------------------------------
    % *********************** Config ************************************
    
    conf.audiosystem = 'matlab'; % Values: 'matlab','native','bypass'

    conf.f_s        = 48000;                % sampling rate  
    conf.f_sym_pre  = 500;                  % preamble symbol rate
    conf.nframes    = 1;                    % number of frames
    conf.modulation_order = 2;              % BPSK:1, QPSK:2
    conf.ncarriers  = 2^10;                 % number of sub carriers 
    conf.nbits      = 10*conf.ncarriers+6;  % number of bits (even numbers only)
    conf.cp_length  = 64;                   % length of cyclic prefix
    conf.f_spacing  = 5;                    % spacing frequency
    conf.f_c        = 8e3;                  % carrier frequency
    conf.bw         = ceil((conf.ncarriers +1)/2)*...
                        conf.f_spacing;     % baseband bandwidth
    conf.npreamble  = 100;                  % preamble length
    conf.bitsps     = 16;                   % bits per audio sample
    
    
    % training obtions for channel estimation and phase tracking 
    % conf.training_type = 0 : block-type training 
    % conf.training_type = 1 : block-type training with Viterbi-Viterbi
    % conf.training_type = 2 : comb-type training chess-board
    % conf.training_type = 3 : send one pilot only. no phase tracking
    conf.training_type = 3;     
    % number of data symbols to be transm. within two training symbols (-1)
    conf.pilot_int = 20;                                     

    % -------------------------------------------------------------------
    % Init Section
    % oversampling factor for OFDM symbols
    conf.os_factor  = conf.f_s/conf.f_spacing/conf.ncarriers;   
    % oversampling factor for preamble
    conf.os_factor_pre = conf.f_s/conf.f_sym_pre;
    
    if mod(conf.os_factor_pre,1) ~= 0
       disp('WARNING: Sampling rate must be a multiple of the symbol rate'); 
    end
    
    conf.data_length    = conf.nbits/conf.modulation_order;   % data length
    conf.nsymbs         = ceil(conf.data_length/...
                            conf.ncarriers);       % number of OFDM symbols 

    if conf.training_type == 3
        conf.npilots = 1;
    else 
        conf.npilots    = ceil(conf.nsymbs/...
                            conf.pilot_int);       % number of training symbols
    end
 
    if conf.training_type == 2
        conf.tot_symb = 2*conf.nsymbs;
    else
        conf.tot_symb = conf.nsymbs +  conf.npilots;
    end
    
    %------------------------------------------------------------------
    conf.preamble	= 1 - 2*lfsr_framesync(conf.npreamble); % preamble - BPSK 
    conf.training	= 1 - 2*randi([0 1],conf.ncarriers,1);  % training sequence - BPSK
    % pulse shape
    tx_filterlen = 10*conf.os_factor_pre;   % single-side bandwidth
    rolloff_factor = 0.22;
    conf.pulse      = rrc(conf.os_factor_pre, ...
                        rolloff_factor, tx_filterlen);      % pulse
    % *********************** End Config *******************************
    
    % Initialize result structure with zero
    res.biterrors   = zeros(conf.nframes,1);
    res.rxnbits     = zeros(conf.nframes,1);
    
    % Results
    for k=1:conf.nframes
        % Generate random data
        txbits = randi([0 1],conf.nbits,1);
        
        % Transmission
        [txsignal, conf] = tx(txbits,conf,k);
        % % % % % % % % % % % %
        % Begin
        % Audio Transmission
        %

        % normalize values
        peakvalue       = max(abs(txsignal));
        normtxsignal    = txsignal / (peakvalue + 0.3);

        % create vector for transmission
        rawtxsignal = [ zeros(conf.f_s,1) ; normtxsignal ;  zeros(conf.f_s,1) ]; % add padding before and after the signal
        rawtxsignal = [  rawtxsignal  zeros(size(rawtxsignal)) ]; % add second channel: no signal
        txdur       = length(rawtxsignal)/conf.f_s; % calculate length of transmitted signal

        % wavwrite(rawtxsignal,conf.f_s,16,'./data/out.wav')   
        audiowrite('./data/out.wav',rawtxsignal,conf.f_s)  

        % Platform native audio mode 
        if strcmp(conf.audiosystem,'native')

            % Windows WAV mode 
            if ispc()
                disp('Windows WAV');
                wavplay(rawtxsignal,conf.f_s,'async');
                disp('Recording in Progress');
                rawrxsignal = wavrecord((txdur+1)*conf.f_s,conf.f_s);
                disp('Recording complete')
                rxsignal = rawrxsignal(1:end,1);

            % ALSA WAV mode 
            elseif isunix()
                disp('Linux ALSA');
                cmd = sprintf('arecord -c 2 -r %d -f s16_le  -d %d in.wav &',conf.f_s,ceil(txdur)+1);
                system(cmd); 
                disp('Recording in Progress');
                system('aplay  ./data/out.wav')
                pause(2);
                disp('Recording complete')
                rawrxsignal = wavread('in.wav');
                rxsignal    = rawrxsignal(1:end,1);
            end

        % MATLAB audio mode
        elseif strcmp(conf.audiosystem,'matlab')
            disp('MATLAB generic');
            playobj = audioplayer(rawtxsignal,conf.f_s,conf.bitsps);
            recobj  = audiorecorder(conf.f_s,conf.bitsps,1);
            record(recobj);
            disp('Recording in Progress');
            playblocking(playobj)
            pause(0.5);
            stop(recobj);
            disp('Recording complete')
            rawrxsignal  = getaudiodata(recobj,'int16');
            rxsignal     = double(rawrxsignal(1:end))/double(intmax('int16')) ;

        elseif strcmp(conf.audiosystem,'bypass')
            rawrxsignal = rawtxsignal(:,1);
            rxsignal    = rawrxsignal;
        end
        %
        % End
        % Audio Transmission   
        % % % % % % % % % % % %

        [rxbits, conf]      = rx(rxsignal,conf);
        res.rxnbits(k)      = length(rxbits);  
        res.biterrors(k)    = sum(rxbits ~= txbits);

    end
   
   per(i) = sum(res.biterrors > 0)/conf.nframes
   ber(i) = sum(res.biterrors)/sum(res.rxnbits)+1e-6

end
