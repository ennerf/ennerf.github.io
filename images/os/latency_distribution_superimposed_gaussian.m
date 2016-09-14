%% settings
style1 = 'b';
style2 = 'r--';
width = 1.5;
fontsize = 16;

xAxis = 'Latency [ms]';
yAxis = 'Probability [0-1]';
xLimits = [0 18];

% close all;
f = figure(1);

% only select actually visible rows
unfilteredData = data24hallwin;
indices = find(unfilteredData.getCountAtValueIteratedTo > 0);
selectionMask = 1:indices(end)+1;
data = unfilteredData(selectionMask, :);

% xLimits = [0 data.getValueIteratedTo(end) * 1E-6];

%% -----------------plot 1 (linear) -----------------
p1 = subplot(2,1,1);
hold off;

% real data
totalCount = sum(data.getCountAtValueIteratedTo);
data.probability = data.getCountAtValueIteratedTo / totalCount;
data.probability(data.probability == 0) = 1E-10;
plot(data.getValueIteratedTo * 1E-6, (data.probability), style1, 'LineWidth', width)
hold on;
grid on;

% sampled gaussian
x = 0:0.1:max(data.getValueIteratedTo * 1E-6);
samples = normpdf(x,0.55,0.37);
samples = samples / sum(samples);
plot(x, samples, style2, 'LineWidth', width);

set(p1,'fontsize',fontsize)
xlabel(xAxis);
ylabel(yAxis);
title('Windows Latency Distribution')
legend actual gaussian-fit
xlim(xLimits)


%% ----------------- plot 2 (semilog-y) -----------------
p2 = subplot(2,1,2);
hold off;

% real data
semilogy(data.getValueIteratedTo * 1E-6, (data.probability), style1, 'LineWidth', width)

hold on;
grid on;

% sampled gaussian
semilogy(x, samples, style2, 'LineWidth', width);

set(p2,'fontsize',fontsize)
title('Logarithmic View');
ylim([1E-8 1]);
xlabel(xAxis);
ylabel(yAxis);
xlim(xLimits)
