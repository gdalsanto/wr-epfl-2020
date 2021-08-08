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

symbol_rate = [100,400,800,1200,1600,2000]; 
for i = 1:length(symbol_rate)

    conf.audiosystem = 'matlab'; % Values: 'matlab','native','bypass'

    conf.f_s     = 48000;                   % sampling rate  
    conf.f_sym   = symbol_rate(i);          % symbol rate
    conf.nframes = 1;                       % number of frames to transmit
    conf.modulation_order = 2;              % BPSK:1, QPSK:2
    conf.nbits   = conf.modulation_order*1000;    % number of bits 
    conf.f_c     = 4000;                    % carrier frequency

    conf.npreamble  = 100;
    conf.bitsps     = 16;                   % bits per audio sample
    conf.offset     = 0; 

    % Init Section
    conf.os_factor  = conf.f_s/conf.f_sym;
    if mod(conf.os_factor,1) ~= 0
       disp('WARNING: Sampling rate must be a multiple of the symbol rate'); 
    end
    conf.nsyms      = ceil(conf.nbits/conf.modulation_order);

    conf.data_length = conf.nbits/conf.modulation_order;    % data length
    conf.preamble = 1 - 2*lfsr_framesync(conf.npreamble);   % preamble
    % pulse shape
    tx_filterlen = 10*conf.os_factor;       % single-side bandwidth
    rolloff_factor = 0.22;
    conf.pulse = rrc(conf.os_factor, rolloff_factor, tx_filterlen);
    
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

        % Plot received signal for debgging
%         figure;
%         plot(rxsignal);
%         title('Received Signal')
%         grid on;

        %
        % End
        % Audio Transmission   
        % % % % % % % % % % % %

        [rxbits, conf]      = rx(rxsignal,conf);

        res.rxnbits(k)      = length(rxbits);  
        res.biterrors(k)    = sum(rxbits ~= txbits);

    end
   
   fprintf('symbol rate: %d\n',conf.f_sym )
   per(i) = sum(res.biterrors > 0)/conf.nframes
   ber(i) = sum(res.biterrors)/sum(res.rxnbits)+1e-6

end
 
 figure('Name', 'BER');
 semilogy(symbol_rate, ber);
 grid on
 xlabel('Symbol rate','interpreter','latex','FontSize',14);
 ylabel('BER','interpreter','latex','FontSize',14);
 ylim([1e-3,0.5]); xlim([100 2000])
 
 