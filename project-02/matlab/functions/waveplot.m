function waveplot(mfsignal,sampleidx,samples,conf)
% WAVEPLOT waveform plotter
%   waveplot(mfsignal,sampleidx,samples,conf) plots the waveform
%
%   mfsignal    : Output of matched filter
%   sampleidx   : Indices of sampling points
%   samples     : phase corrected samples
%   conf        : Configuration Variable
%

plotstart = max(sampleidx(1)-10*(conf.os_factor),0);
plotend   = min(sampleidx(end)+10*(conf.os_factor),length(mfsignal));
plotrange = plotstart:plotend;

% Plot the matchedfiltered signal in complex domain
figure(1)
title('Plot MF output')
plot(mfsignal)

% Plot magnitude and phase of the matched filtered signal
figure(2)
subplot(2,1,1)
plot(abs(mfsignal))
ylabel('Magnitude','FontSize',12)
subplot(2,1,2)
plot(angle(mfsignal))
ylabel('Phase','FontSize',12)

% Overview plot
figure(3)
subplot(4,1,1)
data    = abs(mfsignal(plotrange));
upto    = ceil(max(data)) + 1;
stairs(plotrange,data)
xsmplpts = [sampleidx; sampleidx];
ysmplpts = [0;upto]*ones(1,length(sampleidx));
line(xsmplpts,ysmplpts);
axis([plotstart plotend 0 upto])
ylabel('MF: Magnitude','FontSize',12)

subplot(4,1,2)
data = angle(mfsignal(plotrange));
stairs(plotrange,data);
xsmplpts = [sampleidx ; sampleidx];
ysmplpts = [-4;4]*ones(1,length(sampleidx));
line(xsmplpts,ysmplpts);
axis([plotstart plotend -4 4])
ylabel('MF: Phase','FontSize',12)

subplot(4,1,3)
data = abs(samples);
upto = ceil(max(data)) + 1;
stairs(sampleidx,data)
axis([plotstart plotend 0 upto])
ylabel('Samples: Magnitude','FontSize',12)

subplot(4,1,4)
data = angle(samples);
stairs(sampleidx,data)
axis([plotstart plotend -4 4])
ylabel('Samples: Phase','FontSize',12)

% Plot the whole signal
figure(4)
plot(mfsignal(sampleidx) ,'x ');
title('Scatter Plot Samples')

% Plot the whole signal
figure(5)
plot(samples,'x ');
axis equal
title('Scatter Plot phase corrected Samples')
