function plot_coal_comp_summary(med_ppm_dif, med_ppm_haps)
%% Description:
% plot summary of comparison of trace element concentration in coal blends calculated
% using empirical HAPS data and bootstrap method using COALQUAL data 
% 
% inputs
% med_ppm_dif (array) - median difference at the plant level of bootstrapped
% concentration of the coal blend for each trace element 
% med_ppm_haps (array) - median trace element concentrations at the plant
% level of the haps dataset 
%
% outputs
% Figure in pdf form 
%% 
close all; 
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.25 0.2 0.7 0.7]) % x pos, y pos, x width, y height

plot_array = median(med_ppm_dif./med_ppm_haps,'omitnan')*100;
bar(plot_array)

xlabel('Trace elements');
ylabel(['Median difference in' char(10) 'coal concentration (%)']);

a=gca;
set(a,'FontName','Arial','FontSize',13)
set(a,'box','off','color','none')
axis([0 5 0 100]); 
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

a.XTick = 1:4;
a.XTickLabel = {'Hg','Se','As','Cl'};

print('../Figures/Fig4A_coal_comp','-dpdf','-r300') % save figure 

end 
