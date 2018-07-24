function plot_med_coal_blend_egrid(boot_cq_TE_subrgn, subrgn_list)
%% do the following
% distribution of each plant 
% find the median, min, max, 25th %, and 75th %
% sort by medians with plant info and the above percentiles 
% plot cdf 
% plot 25th and 75th distributions in the same manner, use triangle for
% 25th, square for 75th; see if it needs to be broken down further 

for m = 1:size(subrgn_list,1)

    subrgn = subrgn_list{m,1}; 
    subrgn_cq = boot_cq_TE_subrgn(strcmp(boot_cq_TE_subrgn.egrid_subrgn,subrgn),:);
    boot_cq_TE = table2cell(subrgn_cq(:,1:5));
    
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

    % % create a histogram/cdf of coalqual blends by plant 
    % close all;
    if mod(m,3) == 1
        if m > 1
            print(strcat('../Figures/coal_cdf_subrgn_',int2str(m)),'-dpdf','-r300')
        end 
        figure('Color','w','Units','inches','Position',[0.25 0.25 10 2.7]) % was 1.25
    end 
    axes('Position',[0.2 0.2 0.7 0.7]) % x pos, y pos, x width, y height
    trace_name_ppm = {'Hg_ppm','Se_ppm','As_ppm','Cl_ppm'}; 
    color = {'r','k','b','g'}; 

    % trace_coal_input = table2array(boot_cq_TE(:,trace_name_ppm)); 
    % % format long;
    % max_trace = max(trace_coal_input)

    subplot(1,3,mod(m-1,3)+1); 
    divide_array = [0.6 9 60 1500]; % defined based on the max_trace, but it's an arbitrary rule, so there's no way to automate this process
    scale = max(divide_array); 

    hold on; 
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
        plotx = trace_coal_input.median*scale/divide_array(k);
        ploty = linspace(0,1,size(plotx,1)); 

        max_trace = max(trace_coal_input.median);
    %     display([k, max_trace]);

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

    set(gca,'FontName','Arial','FontSize',13)
    a=gca;
    axis([0 scale 0 1]); 
    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    a.XTickLabel = {'1','2','3','4'}; % placeholder as xtick labels are manipulated manually
    linkaxes([a b])

    xlabel('Trace element concentration (ppm)'); 
    ylabel('F(x)'); 
    title(subrgn); 
    if m == 1
        legend({'Mercury','Selenium','Arsenic','Chlorine'},'Location','SouthEast'); legend boxoff; 
    end 
    grid off;
    
    if m == size(subrgn_list,1)
            print(strcat('../Figures/coal_cdf_subrgn_',int2str(m)),'-dpdf','-r300')
    end 
   
end 

end 