function beginning_of_data = frame_sync(rx_signal, conf)

% Frame synchronizer.
% rx_signal is the noisy received signal, and L is the oversampling factor (L=1 in chapter 2, L=4 in all later chapters).
% The returned value is the index of the first data symbol in rx_signal.

if (rx_signal(1) == 0)
    warning('Signal seems to be noise-free. The frame synchronizer will not work in this case.');
    
end
% When processing an oversampled signal (L>1), the following is important:
% Do not simply return the index where T exceeds the threshold for the first time. Since the signal is oversampled, so will be the
% peak in the correlator output. So once we have detected a peak, we keep on processing the next L samples and return the index
% where the test statistic takes on the maximum value.
% The following two variables exist for exactly this purpose.

detection_threshold = 30;
current_peak_value = 0;
L = conf.os_factor_pre;
samples_after_threshold = L;
% matched filter 
rx_signal = conv(rx_signal, conf.pulse,'same');
for i = L * conf.npreamble + 1 : length(rx_signal)

    r = rx_signal(i - L *  conf.npreamble : L : i - L); % The part of the received signal that is currently inside the correlator.
    c = conf.preamble' * r;
    T = abs(c)^2 / abs(r' * r);
    
    if (T > detection_threshold || samples_after_threshold < L)
        samples_after_threshold = samples_after_threshold - 1;
        if (T > current_peak_value)
            beginning_of_data = i;
            current_peak_value = T;
        end
        if (samples_after_threshold == 0)
            return;
        end
    end
    
end

error('No synchronization sequence found.');
return