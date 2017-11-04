function [conc_stats_hg, conc_stats_se, conc_stats_as, conc_stats_cl] = ...
    plot_med_coal_blend(boot_cq_TE)
%% do the following
% distribution of each plant 
% find the median, min, max, 25th %, and 75th %
% sort by medians with plant info and the above percentiles 
% plot cdf 
% plot 25th and 75th distributions in the same manner, use triangle for
% 25th, square for 75th; see if it needs to be broken down further 
conc_stats_hg = 0; 
conc_stats_se = 0; 
conc_stats_as = 0; 
conc_stats_cl = 0; 
for k = 1:4
    TE_conc_stats = zeros(size(boot_cq_TE,1),6); 
    TE_conc_stats(:,1) = table2array(cell2table(boot_cq_TE(:,1))); 
    for i = 1:size(boot_cq_TE,1)
        TE_conc_stats(i,2) = median(boot_cq_TE{i,k+1},'omitnan'); 
        TE_conc_stats(i,3) = prctile(boot_cq_TE{i,k+1},25); % prctile treats NaNs as missing values and removes them
        TE_conc_stats(i,4) = prctile(boot_cq_TE{i,k+1},75); % prctile treats NaNs as missing values and removes them
        TE_conc_stats(i,5) = min(boot_cq_TE{i,k+1}); % prctile treats NaNs as missing values and removes them
        TE_conc_stats(i,6) = max(boot_cq_TE{i,k+1}); % prctile treats NaNs as missing values and removes them
    end 
    TE_conc_stats = array2table(TE_conc_stats); 
    TE_conc_stats.Properties.VariableNames = {'Plant_Code','median','percentile_25','percentile_75','min','max'}; 
    TE_conc_stats = sortrows(TE_conc_stats,'median','ascend');
    TE_conc_stats(isnan(TE_conc_stats.median),:) = []; % remove plants without TE information 
    if k == 1
        conc_stats_hg = TE_conc_stats;
    elseif k == 2
        conc_stats_se = TE_conc_stats;
    elseif k == 3
        conc_stats_as = TE_conc_stats;
    elseif k == 4
        conc_stats_cl = TE_conc_stats;
    end 
end 

%% alternate method with 25th and 75th percentiles 
% close all;
for k = 1:4
    if k == 1
        trace_coal_input = conc_stats_hg;
    elseif k == 2
        trace_coal_input = conc_stats_se;
    elseif k == 3
        trace_coal_input = conc_stats_as;
    elseif k == 4
        trace_coal_input = conc_stats_cl;
    end
    
    figure('Color','w','Units','inches','Position',[1.25 5.25 4 4]) % was 1.25
    axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height
%     trace_name_ppm = {'Hg_ppm','Se_ppm','As_ppm','Cl_ppm'}; 
    color = {'r','k','b','g'}; 

    divide_array = [0.6 18 120 2100]; % defined based on the max_trace, based on 25th and 75th percentile 
%     divide_array = [3 100 1500 9000]; % defined based on the max_trace, based on min max
    scale = max(divide_array); 

    hold on; 

    plotx = trace_coal_input.median*scale/divide_array(k);
    ploty = linspace(0,1,size(plotx,1)); 
     
    if k == 1
        h = plot(plotx,ploty,'-');
    elseif k == 2
        h = plot(plotx,ploty,'-');
    elseif k == 3
        h = plot(plotx,ploty,'-');
    elseif k == 4
        h = plot(plotx,ploty,'-');
    end 
    set(h,'LineWidth',1.8,'Color',color{k});

    plotx25 = sort(trace_coal_input.percentile_25,'ascend');
    plotx75 = sort(trace_coal_input.percentile_75,'ascend');
    
    plotx25 = plotx25*scale/divide_array(k);
    plotx75 = plotx75*scale/divide_array(k);
%     plotx25 = trace_coal_input.min*scale/divide_array(k);
%     plotx75 = trace_coal_input.max*scale/divide_array(k);
    ploty = linspace(0,1,size(plotx25,1));

%     max_trace = max(trace_coal_input.percentile_75);
%     max_trace = max(trace_coal_input.max);
%     display([k, max_trace])
    
    plot(plotx25,ploty,':','Color',color{k},'MarkerSize',5,'LineWidth',1.8);
    plot(plotx75,ploty,':','Color',color{k},'MarkerSize',5,'LineWidth',1.8);

    set(gca,'FontName','Arial','FontSize',14)
    a=gca;
    axis([0 scale 0 1]); 
    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    a.XTick = [0 525 1050 1575 2100]; 
    a.XTickLabel = {'1','2','3','4'}; % placeholder as xtick labels are manipulated manually
    linkaxes([a b])

    ylabel('F(x)'); 
    if k == 1
        xlabel('Mercury concentration (ppm)'); 
    elseif k == 2
        xlabel('Selenium concentration (ppm)'); 
    elseif k == 3
        xlabel('Arsenic concentration (ppm)'); 
    elseif k == 4
        xlabel('Chlorine concentration (ppm)'); 
    end 
    legend({'median','25th-75th percentile'},'Location','SouthEast'); legend boxoff; 
    grid off;
    title('');

    print(strcat('../Figures/Fig3_coal_conc_cdf_',num2str(k)),'-dpdf','-r300')

end 
end 