function [conc_stats_hg, conc_stats_se, conc_stats_as, conc_stats_cl] = ...
    plot_med_coal_blend(boot_cq_TE, TE_input_dg)
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
figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height
for k = 1:4
    subplot(2,2,k);
    color = {'r','k','b','g'}; 
    hold on;
    if k == 1
        trace_coal_input = conc_stats_hg;
    elseif k == 2
        trace_coal_input = conc_stats_se;
    elseif k == 3
        trace_coal_input = conc_stats_as;
    elseif k == 4
        trace_coal_input = conc_stats_cl;
    end
    if k == 1
        set(gca, 'Position', [0.15 0.6 0.3 0.33])
    elseif k == 2
        set(gca, 'Position', [0.6 0.6 0.3 0.33])
    elseif k == 3
        set(gca, 'Position', [0.15 0.15 0.3 0.33])
    elseif k == 4
        set(gca, 'Position', [0.6 0.15 0.3 0.33])
    end 
    
    divide_array = [0.6 18 120 2100]; % defined based on the max_trace, based on 25th and 75th percentile 
%     divide_array = [3 100 1500 9000]; % defined based on the max_trace, based on min max
    scale = max(divide_array); 

    hold on; 

    plotx = trace_coal_input.median; %*scale/divide_array(k);
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
    
%     plotx25 = plotx25*scale/divide_array(k);
%     plotx75 = plotx75*scale/divide_array(k);
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

    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)

    linspace(0, divide_array(k), 5)
    a.XTick = linspace(0, divide_array(k), 5);
    
    linkaxes([a b])
    axis([0 divide_array(k) 0 1]);

    ylabel('F(x)'); 
    if k == 1
        xlabel('Hg concentration (ppm)'); 
    elseif k == 2
        xlabel('Se concentration (ppm)'); 
    elseif k == 3
        xlabel('As concentration (ppm)'); 
    elseif k == 4
        xlabel('Cl concentration (ppm)'); 
    end 
    legend({'median',['25th-75th',char(10),'percentile']},'Location','SouthEast'); legend boxoff; 
    grid off;
    title('');

end 

print('../Figures/Fig3_coal_conc_cdf','-dpdf','-r300')

%% calculate trace element ppm in coal blend of Daniel G (maybe delete later)
temp = TE_input_dg;
temp(temp.Coal == 0,:) = [];
dg_ppm_blr = temp.Plant_ID; 
dg_ppm_blr(:,end+1) = temp.Share_Mercury./(temp.Coal*2000/2.2)*1e6;
dg_ppm_blr(:,end+1) = temp.Share_Selenium./(temp.Coal*2000/2.2)*1e6;
dg_ppm_blr(:,end+1) = temp.Share_Arsenic./(temp.Coal*2000/2.2)*1e6;
dg_ppm_blr(:,end+1) = temp.Share_Chloride./(temp.Coal*2000/2.2)*1e6;
dg_ppm_plt = unique(dg_ppm_blr(:,1));
for i = 1:size(dg_ppm_plt,1)
    idx = find(dg_ppm_blr(:,1) == dg_ppm_plt(i));
    for k = 1:4
        dg_ppm_plt(i,k+1) = dg_ppm_blr(idx(1),k+1); 
    end 
end 

%% plot Daniel G like in Figure 3 of the main paper 
figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height
for k = 1:4
    subplot(2,2,k);
    color = {'r','k','b','g'}; 
    hold on;
    if k == 1
        trace_coal_input = conc_stats_hg;
    elseif k == 2
        trace_coal_input = conc_stats_se;
    elseif k == 3
        trace_coal_input = conc_stats_as;
    elseif k == 4
        trace_coal_input = conc_stats_cl;
    end
    if k == 1
        set(gca, 'Position', [0.15 0.6 0.3 0.33])
    elseif k == 2
        set(gca, 'Position', [0.6 0.6 0.3 0.33])
    elseif k == 3
        set(gca, 'Position', [0.15 0.15 0.3 0.33])
    elseif k == 4
        set(gca, 'Position', [0.6 0.15 0.3 0.33])
    end 

    divide_array = [0.6 9 60 2100]; % defined based on the max_trace, based on 25th and 75th percentile 
    scale = max(divide_array); 

    hold on; 

    plotx = trace_coal_input.median; %*scale/divide_array(k);
    ploty = linspace(0,1,size(plotx,1));
    plot(plotx,ploty,'r-','LineWidth',1.8);
    plotx = sort(dg_ppm_plt(:,k+1)); %*scale/divide_array(k);
    ploty = linspace(0,1,size(plotx,1)); 
    plot(plotx,ploty,'k--','LineWidth',1.8); 

    set(gca,'FontName','Arial','FontSize',14)
    a=gca;

    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)

    linspace(0, divide_array(k), 5)
    a.XTick = linspace(0, divide_array(k), 5);
    
    linkaxes([a b])
    axis([0 divide_array(k) 0 1]);

    ylabel('F(x)'); 
    if k == 1
        xlabel('Hg concentration (ppm)'); 
        legend({'bootstrap approach','Median approach'},'Location','SouthEast'); legend boxoff; 
    elseif k == 2
        xlabel('Se concentration (ppm)'); 
    elseif k == 3
        xlabel('As concentration (ppm)'); 
    elseif k == 4
        xlabel('Cl concentration (ppm)'); 
    end 
    
    grid off;
    title('');
    
    print('../Figures/Fig_comp_med_boot_coal','-dpdf','-r300')

end 

end 