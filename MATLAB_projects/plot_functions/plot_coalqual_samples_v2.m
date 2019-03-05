function plot_data = plot_coalqual_samples_v2(coal_var_county, coalqual_samples, TE)
%% Description:
% illustrate variation in trace element concentrations in run-of-mill coal
% by plotting all coalqual samples at 5 counties as an example and for all
% samples in COALQUAL. Choose counties by range of concentrations at
% relevant percentiles 
% 
% input
% coal_var_county - differnce of minimum and maximum coal concentrations at
% each county 
% coalqual_samples - all upper level samples from COALQUAL 
% TE (str) - pollutant of interest 
%
% output
% plot_data (array) - data output of the plots 
% SI Figure in pdf 

%% 
coal_var_county = sortrows(coal_var_county,TE,'ascend'); 
if strcmp(TE,'Cl') == 0 % not Cl trace element 
    counties_to_plot = [38 38+76 38+2*76 38+3*76 38+4*76]; 
else
    counties_to_plot = [25 25+51 25+2*51 25+3*51 25+4*51]; 
end 
% initialize arrays 
plot_data = zeros(1000,size(counties_to_plot,2));
sample_sizes = zeros(1,6); 

% define data to plot for each county 
for i = 1:size(counties_to_plot,2)
    idx = coalqual_samples.fips_code == coal_var_county.counties(counties_to_plot(i));
    sample_sizes(i) = sum(idx);
    if strcmp(TE,'Hg') == 1
        plot_data(1:sum(idx),i) = coalqual_samples.Hg(idx,1);
    elseif strcmp(TE,'Se') == 1
        plot_data(1:sum(idx),i) = coalqual_samples.Se(idx,1);
    elseif strcmp(TE,'As') == 1
        plot_data(1:sum(idx),i) = coalqual_samples.As(idx,1);
    elseif strcmp(TE,'Cl') == 1
        plot_data(1:sum(idx),i) = coalqual_samples.Cl(idx,1);
    else
        error('incorrect trace element input');
    end
   
end
% define data for all samples in COALQUAL 
plot_data(1:size(coalqual_samples,1),end+1) = table2array(coalqual_samples(:,TE));
sample_sizes(6) = size(coalqual_samples,1) - sum(isnan(table2array(coalqual_samples(:,TE)))); 
fprintf('Sample sizes for x ticks, %s: %1.0f %1.0f %1.0f %1.0f %1.0f %1.0f\n', TE, sample_sizes); 

plot_data(plot_data == 0) = nan; % set zeros to nan to avoid plotting issues

%% plot figure 
figure('Color','w','Units','inches','Position',[1.25 1.25 4 4]) % was 1.25
axes('Position',[0.15 0.15 0.7 0.8]) % x pos, y pos, x width, y height

boxplot(plot_data);
hold on;
set(gca,'FontName','Arial','FontSize',13)
a=gca;
xlim([0.5 size(counties_to_plot,2)+1.5]);
if strcmp(TE,'Hg') == 1
    ylim([0 1]); % hg % 1 for y max
elseif strcmp(TE,'Se') == 1
    ylim([0 20]); % se
elseif strcmp(TE,'As') == 1
    ylim([0 300]); % as
elseif strcmp(TE,'Cl') == 1
    ylim([0 2500]); % cl
else
    error('incorrect trace element input');
end

labels = cell(1,1);
for i = 1:size(counties_to_plot,2)
    labels(i,1) = {num2str(coal_var_county.counties(counties_to_plot(i)))};
end
labels(6,1) = {'All Counties'};
set(a,'XTickLabel',labels);
a.XTickLabelRotation = 45;

xlabel('FIPS county codes');
ylabel(strcat(TE,' concentration (ppm)'));

set(a,'box','off','color','none')
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

print(strcat('../Figures/SI_CQ_sample_boxplot_',TE),'-dpdf','-r300') % save figure (optional)


end 