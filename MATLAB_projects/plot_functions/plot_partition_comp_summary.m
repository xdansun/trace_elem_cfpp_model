function plot_partition_comp_summary(comp_lit_mats_hg, comp_lit_mats_se, ...
                                comp_lit_mats_as, comp_lit_mats_cl)
%% Description
% plot the median result of the comparison of partitioning of trace
% elements to the gaseous phase using empirical HAPS data and bootstrap
% method using literature data. A more extensive boiler level result is in
% plot_mats_lit_partition_comp
% 
% inputs
% comp_lit_mats_hg (table) - boilers with the median gas phase
% partitioning calculated using HAPS data and calculated using
% bootstrapping approach along with the differences at the boiler level 
% other inputs are the same as comp_lit_mats_hg but for Se, As, and Cl. 
%
% outputs
% Figure in pdf form 

%
%%
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.3 0.2 0.7 0.7]) % x pos, y pos, x width, y height

plot_array = [median(comp_lit_mats_hg.gas_dif) ...
    median(comp_lit_mats_se.gas_dif) ...
    median(comp_lit_mats_as.gas_dif) ...
    median(comp_lit_mats_cl.gas_dif)];

bar(plot_array)

xlabel('Trace elements');
% ylabel(['Partitioning comparison' char(10) 'percent difference (%)']);
% ylabel(['Partitioning validation:' char(10) 'Median difference in gas' char(10) 'partitioning coefficient (%)']);
ylabel(['Median difference in gas' char(10) 'partitioning coefficient']);

a=gca;
set(a,'FontName','Arial','FontSize',13)
set(a,'box','off','color','none')
% axis([0 5 -35 0]); 

b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
axis([0 5 0 0.3]); 
% axis([0 5 0 0.03]); 
% ylim([0 0.4]);

a.XTick = 1:4;
a.XTickLabel = {'Hg','Se','As','Cl'};

print('../Figures/Fig4B_part_comp','-dpdf','-r300') % save figure