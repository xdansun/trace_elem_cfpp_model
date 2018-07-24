function plot_mats_lit_partition_comp(comp_lit_mats_hg, comp_lit_mats_se, ...
    comp_lit_mats_as, comp_lit_mats_cl)

%% DESCRIPTION NEEDED 

%% plot histogram comparing differences 
figure('Color','w','Units','inches','Position',[0.25 0.25 8 4]) % was 1.25
axes('Position',[0.18 0.18 0.75 0.75]) % x pos, y pos, x width, y height

subplot(1,2,1);
set(gca, 'Position', [0.1 0.2 0.33 0.7])
poll = {'Hg','Se','As','Cl'}; 
color = {'r','k','b','g'}; 

for k = 1:4
    if k == 1
        comp_lit_mats_TE = comp_lit_mats_hg; 
    elseif k ==2
        comp_lit_mats_TE = comp_lit_mats_se; 
    elseif k == 3
        comp_lit_mats_TE = comp_lit_mats_as;
    elseif k == 4
        comp_lit_mats_TE = comp_lit_mats_cl;
    end

    %     histogram(med_dif,'BinMethod','fd'); hold on;
    %     histogram(med_ppm_dif(:,k),'BinMethod','fd');
    % plot(1:size(plants_to_plot,2), comp_boot_cems_hg.cems_hg_emf_mg_MWh(plants_to_plot),'k^','LineWidth',1.5,'MarkerSize',8);

%     subplot(2,2,k);
    hold on;
    plotx = sort(comp_lit_mats_TE.haps_med_remov);
%     plotx = sort(comp_lit_mats_TE.haps_med_remov);
    ploty = linspace(0,1,size(plotx,1));

%     plot(plotx, ploty);

    if k == 1
        h = plot(plotx,ploty,'--');
    elseif k == 2
        h = plot(plotx,ploty,'-.');
    elseif k == 3
        h = plot(plotx,ploty,':');
    elseif k == 4
        h = plot(plotx,ploty,'-');
    end 
    set(h,'LineWidth',1.8,'Color',color{k});

    xlabel(['Median MATS ICR partitioning' char(10) 'fraction to solids and liquids']);
    ylabel('F(x)');

    set(gca,'FontName','Arial','FontSize',13)
    a=gca;
    set(a,'box','off','color','none')
    axis([0 1 0 1]);
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    linkaxes([a b])
    legend({'Mercury','Selenium','Arsenic','Chlorine'},'Location','NorthWest');
    legend boxoff;

end 

% print(strcat('../Figures/Fig_solid_liq_partition_mats'),'-dpdf','-r300') % save figure (optional)

%% plot histogram comparing differences 
% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.18 0.18 0.75 0.75]) % x pos, y pos, x width, y height

subplot(1,2,2);
set(gca, 'Position', [0.55 0.2 0.33 0.7])
poll = {'Hg','Se','As','Cl'}; 
color = {'r','k','b','g'}; 

for k = 1:4
    if k == 1
        comp_lit_mats_TE = comp_lit_mats_hg; 
    elseif k ==2
        comp_lit_mats_TE = comp_lit_mats_se; 
    elseif k == 3
        comp_lit_mats_TE = comp_lit_mats_as;
    elseif k == 4
        comp_lit_mats_TE = comp_lit_mats_cl;
    end

    %     histogram(med_dif,'BinMethod','fd'); hold on;
    %     histogram(med_ppm_dif(:,k),'BinMethod','fd');
    % plot(1:size(plants_to_plot,2), comp_boot_cems_hg.cems_hg_emf_mg_MWh(plants_to_plot),'k^','LineWidth',1.5,'MarkerSize',8);

%     subplot(2,2,k);
    hold on;
    plotx = sort(comp_lit_mats_TE.remov_dif);
    ploty = linspace(0,1,size(plotx,1));

%     plot(plotx, ploty);

    if k == 1
        h = plot(plotx,ploty,'--');
    elseif k == 2
        h = plot(plotx,ploty,'-.');
    elseif k == 3
        h = plot(plotx,ploty,':');
    elseif k == 4
        h = plot(plotx,ploty,'-');
    end 
    set(h,'LineWidth',1.8,'Color',color{k});

    xlabel(['Difference in median partitioning fraction' char(10) ...
        'to solids and liquids between literature based' char(10) ...
        'estimates and MATS ICR measurements']);
    ylabel('F(x)');

    set(gca,'FontName','Arial','FontSize',13)
    a=gca;
    set(a,'box','off','color','none')
    axis([-1 1 0 1]);
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    linkaxes([a b])
%     legend({'Mercury','Selenium','Arsenic','Chlorine'},'Location','SouthEast');
%     legend boxoff;

end 

print('../Figures/Fig_mats_lit_partition_comp','-dpdf','-r300') % save figure (optional)

end 
