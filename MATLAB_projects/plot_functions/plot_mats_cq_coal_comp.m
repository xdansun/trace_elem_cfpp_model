function plot_mats_cq_coal_comp(comp_cq_haps, med_ppm_dif)

%% DESCRIPTION NEEDED 

%% plot cdf of concentration of trace elements in MATS ICR 
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.18 0.18 0.75 0.75]) % x pos, y pos, x width, y height

divide_array = [0.6 15 40 2100]; % defined based on the max_trace, but it's an arbitrary rule, so there's no way to automate this process
scale = max(divide_array); 
color = {'r','k','b','g'}; 
hold on;

for k = 1:4
%     subplot(2,2,k);

    haps_ppm = table2cell(comp_cq_haps(:,k+5)); 
    haps_med_ppm = zeros(size(haps_ppm,1),1); 
    for i = 1:size(haps_ppm,1)
        haps_med_ppm(i) = median(haps_ppm{i,1}); 
    end 
    % plot(1:size(plants_to_plot,2), comp_boot_cems_hg.cems_hg_emf_mg_MWh(plants_to_plot),'k^','LineWidth',1.5,'MarkerSize',8); 

%     max(haps_med_ppm)

    plotx = sort(haps_med_ppm)*scale/divide_array(k); 
    plotx(isnan(plotx)) = []; 
    ploty = linspace(0,1,size(plotx,1));
    
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

end
ylabel('F(x)'); 
set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
% ylim([0 1]);
axis([0 scale 0 1]);
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
a.XTick = linspace(0, 2100, 5); 
% a.XTickLabel = {'1','2','3','4'};
% legend(['Difference between' char(10) 'bootstrap and MATS ICR'],'MATS ICR');
legend({'Mercury','Selenium','Arsenic','Chlorine'},'Location','SouthEast');
legend boxoff;

print('../Figures/FigS7_coal_mats_pdf','-dpdf','-r300') % save figure (optional)

%% plot cdf comparing difference between model estimates and MATS ICR 
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.18 0.18 0.75 0.75]) % x pos, y pos, x width, y height

divide_array = [0.3 15 20 1600]; % defined based on the max_trace, but it's an arbitrary rule, so there's no way to automate this process
scale = max(divide_array); 
color = {'r','k','b','g'}; 
hold on;

for k = 1:4
    plotx = sort(med_ppm_dif(:,k))*scale/divide_array(k); 
    plotx(isnan(plotx)) = []; 
    ploty = linspace(0,1,size(plotx,1));
    
%     [min(med_ppm_dif(:,k)) max(med_ppm_dif(:,k))]

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
%     plot(plotx, ploty,'r','LineWidth',2); hold on;
    
%     plotx = ; 
%     plotx(isnan(plotx)) = []; 
%     ploty = linspace(0,1,size(plotx,1));
%     
%     plot(plotx, ploty,'k','LineWidth',2);  

end
ylabel('F(x)'); 
set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
% ylim([0 1]);
axis([-scale scale 0 1]);
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
a.XTick = linspace(-scale, scale, 5); 
% a.XTickLabel = {'1','2','3','4'};
% legend(['Difference between' char(10) 'bootstrap and MATS ICR'],'MATS ICR');
legend({'Mercury','Selenium','Arsenic','Chlorine'},'Location','SouthEast');
legend boxoff;

print('../Figures/FigS7_comp_coal_mats_cq','-dpdf','-r300') % save figure (optional)


end 
