function plot_data = plot_boot_coal_blend(boot_cq_TE, TE)

%% DESCRIPTION NEEDED
% state purpose of script here. 

% TE is the trace element abbreviation for the plot we are generating 

%% combine the coalqual trace distribution 
plant_trace_coalqual = cell2table(boot_cq_TE); % convert plant_purch to a table for coalqual data to merge 
plant_trace_coalqual.Properties.VariableNames = {'Plant_Code',...
    'hg_cq_ppm','se_cq_ppm','as_cq_ppm','cl_cq_ppm'}; 

%% plot figure 
% choose 5 plants for illustration, ORISPL: 10, 59, 298, 594, 856
plants_to_plot = [10 87 298 594 856]; 
% plants_to_plot
plot_data = zeros(10000,size(plants_to_plot,2));
for i = 1:size(plants_to_plot,2)
    idx = plants_to_plot(i) == plant_trace_coalqual.Plant_Code;
    if strcmp(TE,'Hg') == 1
        plot_data(:,i) = plant_trace_coalqual.hg_cq_ppm{idx,1};
    elseif strcmp(TE,'Se') == 1
        plot_data(:,i) = plant_trace_coalqual.se_cq_ppm{idx,1};
    elseif strcmp(TE,'As') == 1
        plot_data(:,i) = plant_trace_coalqual.as_cq_ppm{idx,1};
    elseif strcmp(TE,'Cl') == 1
        plot_data(:,i) = plant_trace_coalqual.cl_cq_ppm{idx,1};
    else
        error('incorrect trace element input');
    end
   
end
plot_data(plot_data == 0) = nan;

figure('Color','w','Units','inches','Position',[1.25 5.25 4 4]) % was 1.25
axes('Position',[0.15 0.15 0.8 0.8]) % x pos, y pos, x width, y height

boxplot(plot_data);
hold on;
set(gca,'FontName','Arial','FontSize',13)
a=gca;
xlim([0.5 size(plants_to_plot,2)+0.5]);
if strcmp(TE,'Hg') == 1
    ylim([0 1]); % hg % 1 for y max
elseif strcmp(TE,'Se') == 1
    ylim([0 25]); % se
elseif strcmp(TE,'As') == 1
    ylim([0 500]); % as
elseif strcmp(TE,'Cl') == 1
    ylim([0 2500]); % cl
else
    error('incorrect trace element input');
end

labels = cell(1,1);
for i = 1:size(plants_to_plot,2)
    labels(i,1) = {num2str(plants_to_plot(i))};
end
set(a,'XTickLabel',labels);
a.XTickLabelRotation = 45;

xlabel('ORISPL Plant Code');
ylabel(strcat(TE,' concentration (ppm)'));

set(a,'box','off','color','none')
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

print(strcat('../Figures/Fig3_boot_CQ_boxplot_',TE),'-dpdf','-r300') % save figure (optional)


end 

%% plot figures 
% plot_cq_dist(plant_trace_coalqual, poll)

