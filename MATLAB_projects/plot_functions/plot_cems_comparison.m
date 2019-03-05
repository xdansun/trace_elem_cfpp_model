function plot_cems_comparison(comp_boot_cems_hg)

%% DESCRIPTION 
% plot two figures: a histogram showing the boiler-level median generation
% normalized mercury emissions from bootstrap method and from CEMS; and a
% cdf showing the boiler-level difference between the bootstrap method and
% CEMS 
%
% inputs:
% comp_boot_cems_hg (table) - boiler level generation normalized mass flow
% rates of Hg in solid, liquid, and gas calculated using bootstrap analysis and
% gas phase emissions estimated from CEMS and the difference of those
% numbers 
%
% outputs:
% two figures in PDF form 

%% plot pdf (histogram) of CEMS emissions
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.15 0.25 0.7 0.7]) % x pos, y pos, x width, y height
% subplot(1,2,1); 
hold on;
% set(gca, 'Position', [0.1 0.2 0.33 0.7])
% histogram(comp_boot_cems_hg.cems_hg_emf_mg_MWh,'BinWidth',2,'FaceAlpha',0,'LineWidth',2,'LineStyle','-','EdgeColor',[0 0 1]);
% histogram(comp_boot_cems_hg.med_hg_emf_stack,'BinWidth',2,'LineWidth',2,'FaceAlpha',0,'EdgeColor',[1 0 0]); 

% histogram(comp_boot_cems_hg.cems_hg_emf_mg_MWh,'BinWidth',2,'FaceAlpha',0.5,'LineWidth',2,'LineStyle','-','FaceColor',[0 0 1],'EdgeColor',[0 0 1]);
% histogram(comp_boot_cems_hg.med_hg_emf_stack,'BinWidth',2,'LineWidth',2,'FaceAlpha',0.5,'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);  hold on;

histogram(comp_boot_cems_hg.cems_hg_emf_mg_MWh,'BinWidth',2,'FaceAlpha',0,'LineWidth',2,'LineStyle','-','EdgeColor',[0 0 1]);
histogram(comp_boot_cems_hg.med_hg_emf_stack,'BinWidth',2,'LineWidth',1,'FaceAlpha',0.33,'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);  hold on;

xlabel({'Hg emissions validation:', 'Generation normalized gas phase', 'Hg emissions (mg/MWh)'});
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
legend('CEMS',['Median bootstrapped', char(10), 'emissions']); 
legend boxoff;

print('../Figures/Fig6_cems_hg_comp_histo','-dpdf','-r300') % save figure (optional)

%%
% colormap(cool(6));
% pie(rand(6,1));
% legend('Jan','Feb','Mar','Apr','May','Jun');
% applyhatch(gcf,'|-+.\/',cool(6));

%% create CDF of differences in medians 
med_dif = comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh; % estimated - actual 

figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.15 0.25 0.7 0.7]) % x pos, y pos, x width, y height
% subplot(1,2,2); 
% set(gca, 'Position', [0.55 0.2 0.33 0.7])

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

print('../Figures/Fig6_cems_min_hg_cdf','-dpdf','-r300') % save figure (optional)
% print('../Figures/Fig6_cems_hg_cdf','-dpdf','-r300') % save figure (optional)


end 