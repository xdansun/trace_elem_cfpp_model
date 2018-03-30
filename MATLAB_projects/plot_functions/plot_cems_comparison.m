function plot_cems_comparison(comp_boot_cems_hg)

%% DESCRIPTION NEEDED 

%% plot pdf (histogram) of CEMS emissions
figure('Color','w','Units','inches','Position',[0.25 0.25 8 4]) % was 1.25
% axes('Position',[0.15 0.15 0.8 0.8]) % x pos, y pos, x width, y height
subplot(1,2,1); 
hold on;
set(gca, 'Position', [0.1 0.2 0.33 0.7])
histogram(comp_boot_cems_hg.med_hg_emf_stack,'BinWidth',2,'LineWidth',2,'FaceAlpha',0,'EdgeColor',[1 0 0]);  hold on;
histogram(comp_boot_cems_hg.cems_hg_emf_mg_MWh,'BinWidth',2,'FaceAlpha',0,'LineWidth',2,'LineStyle','-','EdgeColor',[0 0 1]);

xlabel({'Gas phase Hg emissions', 'intensity (mg/MWh)'});
ylabel('Boilers'); 

set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
% axis([-25 75 0 70]); 
% axis([-20 80 0 1]); 
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
% a.XTickLabel = comp_boot_cems_hg.Plant_Boiler(plants_to_plot); % choose 5 boilers from 5 different plants 
legend(['Median bootstrapped', char(10), 'emissions'],'CEMS'); 
legend boxoff;

% print('../Figures/Fig6_cems_hg_comp_histo','-dpdf','-r300') % save figure (optional)

%% create CDF of differences in medians 
med_dif = comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh; % estimated - actual 

% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.15 0.15 0.8 0.8]) % x pos, y pos, x width, y height
subplot(1,2,2); 
set(gca, 'Position', [0.55 0.2 0.33 0.7])

plotx = sort(med_dif); 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'k','LineWidth',1.8);

idx = find(ploty >= 0.8); 
fprintf('%3.1f percent of boilers have less than %3.2f mg/MWh difference from CEMS\n', ploty(idx(1))*100, plotx(idx(1))); 

xlabel({'Difference of median bootstrapped', ... 
    'and CEMS gas phase Hg emissions',...
    'intensity (mg/MWh)'});
ylabel('F(x)'); 

set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
% axis([-25 75 0 70]); 
% axis([-20 60 0 1]); 
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

print('../Figures/Fig6_cems_hg_comp_cdf','-dpdf','-r300') % save figure (optional)


end 