function [payload_data, H_hat, conf] = channel_equalization(signal, conf)
% Channel estimation and equialization
%
%   [payload_data, conf] = channel_equalization(signal, conf)
%
%   signal : data symbols 
%   conf    : universal configuration structure
%   payload_data : eualized signal
%   H_hat : channel estimation 

payload_data = zeros(conf.ncarriers, conf.nsymbs);
npilot = 0;
data_indx = 0;

% ****************** BLOCK-TYPE *******************************************
if conf.training_type == 0  
    
    % loop over the index of each pilot in signal
    for i = [1 : conf.pilot_int + 1 : size(signal,2)] 
        npilot = npilot + 1;
        H_hat(:,npilot) = signal(:,i)./conf.training;
        h_hat(:,npilot) = ifft(H_hat(:,npilot));
        
        for k = 1 : conf.pilot_int 
            data_indx = data_indx + 1;
            if data_indx > conf.nsymbs  
                % after the last received pilot the number of sybols may be
                % less than conf.pilot_int. We need to get out of the for
                % loops in order not to save unexpected data 
                continue
            end
            symb_indx = i + k;
            payload_data(:,data_indx) = signal(:,symb_indx)./abs(H_hat(:,npilot));
            payload_data(:,data_indx) = payload_data(:,data_indx).*exp(-1j*mod(angle(H_hat(:,npilot)),2*pi));
        end    
    end
% ****************** BLOCK-TYPE VITERBI ***********************************    
elseif conf.training_type == 1  
    % initial phase estimation 
    for i = [1 : conf.pilot_int + 1 : size(signal,2)] % loop over the index of each pilot in signal
        npilot = npilot + 1;
        H_hat(:,npilot) = signal(:,i)./conf.training;
        
        % Viterbi-Viterbi and channel equalization
        for k = 1 : conf.pilot_int 
            data_indx = data_indx + 1;
            if data_indx > conf.nsymbs
                % after the last received pilot the number of sybols may be
                % less than conf.pilot_int. We need to get out of the for
                % loops in order not to save unexpected data 
                continue
            end
            symb_indx = i + k;  % index to the current symbol in "signal"
            payload_data(:,data_indx) = signal(:,symb_indx);  % current symbol
            
            % Phase estimation    
            % viterbi-viterbi algorithm
            deltaTheta = 1/4*angle(-payload_data(:,data_indx).^4) + pi/2*(-1:4);
            if k == 1
                % get the initial phase estimation theta0 from H_hat
                theta = mod(angle(H_hat(:,npilot)),2*pi);
            else 
                theta = theta_hat(:,data_indx-1);
            end
            [~, ind] = min(abs(deltaTheta - theta),[],2);
            indvec = (0:conf.ncarriers-1).*6 + ind'; 
            deltaTheta = deltaTheta';
            theta0 = deltaTheta(indvec)';
            % Lowpass filter phase
            theta_hat(:,data_indx) = mod(0.01.*theta0 + 0.99.*theta, 2*pi);
            % Phase correction
            payload_data(:,data_indx) = payload_data(:,data_indx) .* exp(-1j * theta_hat(:,data_indx))./abs(H_hat(:,npilot)); 
        end
    end
% ****************** COMB_TYPE ********************************************
elseif conf.training_type == 2 
    % separate data in even and odd indexed data
    int_o = [2 : 2 : conf.ncarriers];   % odd
    int_e = [1 : 2 : conf.ncarriers];   % even
    H_hat_p = zeros(conf.ncarriers, 2*conf.nsymbs);
    
    for i = 1 : 2*conf.nsymbs
        if mod(i,2) ~= 0
            y = signal(int_o,i);
            H_hat_p(int_o,i) = y./conf.train_odd;
            payload_data(1:conf.ncarriers/2,ceil(i/2)) = signal(int_e,i);
        else 
            y = signal(int_e,i);
            H_hat_p(int_e,i) = y./conf.train_even;
            payload_data(conf.ncarriers/2+1:end,ceil(i/2)) = signal(int_o,i);
        end
    end
    
    H_hat = zeros(conf.ncarriers, conf.nsymbs);
    for i = 1:conf.ncarriers/2
        temp = H_hat_p(int_e(i),:);
        H_hat(i,:) = temp(temp~=0);
        temp = H_hat_p(int_o(i),:);
        H_hat(i+conf.ncarriers/2,:) = temp(temp~=0);  
    end
    for i = 1 : conf.nsymbs
        payload_data(:,i) = payload_data(:,i)./abs(H_hat(:,i));
        payload_data(:,i) = payload_data(:,i).*exp(-1j*mod(angle(H_hat(:,i)),2*pi));
    end
     temp = H_hat(1:conf.ncarriers/2,:);
     H_hat(int_o,:) = H_hat(conf.ncarriers/2+1:end,:);
     H_hat(int_e,:) = temp;
% ****************** NO_PHASE TRACKING ************************************
else 
    % channel estimation
    H_hat = signal(:,1)./conf.training;
    % channel compensation 
    for k = 1 : conf.nsymbs 
        payload_data(:,k) = signal(:,k+1)./abs(H_hat);
        payload_data(:,k) = payload_data(:,k).*exp(-1j*mod(angle(H_hat),2*pi));
    end
end