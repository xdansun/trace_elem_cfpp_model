function plot_wfgd_comp(boot_plt_emis_hg, boot_plt_emis_se, boot_plt_emis_as, boot_plt_emis_cl)
%% Description: 
% plot average fleet level mass flow rate into the wfgd waste stream using
% results from the bootstrap analysis and the Environmental Assessment of
% the Effluent Limitation Guidelines (see below)
% 
% inputs:
% boot_emis_hg (table) - Table of Hg mass flow rates and generation
% normalized mass flow rates at the plant level to solid, liquid, and gas
% with generation at the boiler
% the other inputs are the same as boot_emis_hg, but for se, as and cl
%
% outputs:
% Figure in pdf form 
%% summarize ELG results In the Environmental Assessment of the Effluent
% Limitation Guidelines, the Environmental Protection Agency estimates flue
% gas desulfurization wastewater discharge from 88 coal plants.18 They
% report the average plant FGD wastewater discharge as 2.5 kg Hg/yr, 641 kg
% Se/yr, 4.3 kg As/yr and 4.6 million kg Cl/yr. See Table 3-4? 3-3. One of
% those tables in chapter 3 of the Environmental Assessment of the ELGs. 

% plot results
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.3 0.2 0.7 0.7]) % x pos, y pos, x width, y height

elg_fgd = [2.5 641 4.3 4.6e6]; 
fgd_tot = zeros(size(boot_plt_emis_hg,1),4); 
for i = 1:size(boot_plt_emis_hg,1)
    fgd_tot(i,1) = boot_plt_emis_hg.emis_mg{i,1}(1,2);
end 
for i = 1:size(boot_plt_emis_se,1)
    fgd_tot(i,2) = boot_plt_emis_se.emis_mg{i,1}(1,2);
end 
for i = 1:size(boot_plt_emis_as,1)
    fgd_tot(i,3) = boot_plt_emis_as.emis_mg{i,1}(1,2);
end 
for i = 1:size(boot_plt_emis_cl,1)
    fgd_tot(i,4) = boot_plt_emis_cl.emis_mg{i,1}(1,2);
end 
fgd_avg = zeros(1,4); 
for k = 1:4
    fgd_avg(1,k) = sum(fgd_tot(:,k))/sum(fgd_tot(:,k) > 0)/1e6; 
end 

plot_array = (fgd_avg - elg_fgd)./elg_fgd*100;
bar(plot_array)

xlabel('Trace elements');
% ylabel(['FGD waste stream validation:' char(10) 'Median difference in liquid' char(10) 'phase mass flow rate (%)']);
ylabel(['FGD waste stream validation:' char(10) 'Difference in liquid' char(10) 'phase mass flow rate (%)']);

a=gca;
set(a,'FontName','Arial','FontSize',13)
set(a,'box','off','color','none')
xlim([0 5]);
ylim([-100 400]);
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

a.XTick = 1:4;
a.XTickLabel = {'Hg','Se','As','Cl'};

print('../Figures/Fig4D_fgd_ww_comp_min','-dpdf','-r300') % save figure
