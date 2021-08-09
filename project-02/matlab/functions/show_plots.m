function show_plots(payload_data, rxsymbol, H_hat, conf)
%
% show_plots(payload_data, H_hat, conf)
%   
%   Show all the useful plots 

% Constellations 
figure('name','constellations')
hold on 
for k = 1 : conf.nsymbs 
    plot(payload_data(:,k), 'o');
end
xline(0,'--'); yline(0,'--');
xlim([-5 5]); ylim([-5 5]);
title('Received symbols with phase correction','interpreter','latex','FontSize',16);


% Channel magnitude and phase
f = 0 : conf.bw/conf.ncarriers : conf.bw*(1-1/conf.ncarriers);
f = f + conf.f_c - conf.bw/2;
figure('name','channel magnitude and phase')
subplot(2,1,1); plot(f,20*log10(abs(H_hat)./max(abs(H_hat))));
xlim([f(1) f(end)]); xline(conf.f_c,'--r')
xlabel('frequency/Hz','interpreter','latex','FontSize',16);
ylabel('amplitude/dB','interpreter','latex','FontSize',16);
title('Magnitude','interpreter','latex','FontSize',16);
grid on
subplot(2,1,2); plot(f,unwrap(angle(H_hat)));
xlim([f(1) f(end)]); xline(conf.f_c,'--r')
xlabel('frequency/Hz','interpreter','latex','FontSize',16);
ylabel('degrees','interpreter','latex','FontSize',16);
title('Phase','interpreter','latex','FontSize',16);
grid on

% Channel Impulse response 
t = 0 : 1/conf.f_s : conf.ncarriers/conf.f_s-1/conf.f_s;
figure('name','channel impulse response')
h_hat = ifft(H_hat,[],1);
plot(t,abs(h_hat))
xlim([t(1) t(end)]);
grid on 
title('Channel impulse response','interpreter','latex','FontSize',16);
xlabel('time/s','interpreter','latex','FontSize',16)

% Channel frequency response over time
channel_imp = rxsymbol./conf.txsymb;
chan_plot = [1 conf.ncarriers/2 conf.ncarriers];
t = 0 : 1/conf.f_spacing : 1/conf.f_spacing*(conf.tot_symb - 1);

figure('name','channel freq response vs time');
subplot(2,1,1);     
plot(t,20*log10(abs(channel_imp(chan_plot(:),:))./max(abs(channel_imp(chan_plot(:),:)),[],2)));
xlim([t(1) t(end)]);
grid on
xlabel('time/s','interpreter','latex','FontSize',16);
ylabel('amplitude/dB','interpreter','latex','FontSize',16);
title('Magnitude','interpreter','latex','FontSize',16);
subplot(2,1,2); plot(t,unwrap(angle(channel_imp(chan_plot,:))));
xlim([t(1) t(end)]);
grid on
xlabel('time/s','interpreter','latex','FontSize',16);
ylabel('degrees','interpreter','latex','FontSize',16);
title('Phase','interpreter','latex','FontSize',16);