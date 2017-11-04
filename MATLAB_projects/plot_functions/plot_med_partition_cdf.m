function plot_med_partition_cdf(boot_remov_hg, boot_remov_se, boot_remov_as, boot_remov_cl)
%% do the following
% distribution of each plant 
% find the median, min, max, 25th %, and 75th %
% sort by medians with plant info and the above percentiles 
% plot cdf 
% plot 25th and 75th distributions in the same manner, use triangle for
% 25th, square for 75th; see if it needs to be broken down further 
remov_stats_hg = 0; 
remov_stats_se = 0; 
remov_stats_as = 0; 
remov_stats_cl = 0; 
med_array = nan(400,12);
prctl_25 = nan(400,12);
prctl_75 = nan(400,12);

for k = 1:4
    if k == 1
        boot_remov_TE = boot_remov_hg; 
    elseif k == 2
        boot_remov_TE = boot_remov_se; 
    elseif k == 3
        boot_remov_TE = boot_remov_as; 
    elseif k == 4
        boot_remov_TE = boot_remov_cl; 
    end 
%     TE_conc_stats = cell(1,5); 

%     TE_conc_stats(:,1) = table2array(boot_remov_TE(:,1));
%     TE_conc_stats(:,2) = cell2table(boot_remov_TE(:,2));
    for i = 1:size(boot_remov_TE,1)
        TE_phases = boot_remov_TE{i,3};
        TE_phases(isnan(TE_phases(:,2)),2) = 0; % set all liquid nan removals to zero 
%         if sum(isnan(TE_phases(:,3))) > 0 
%             1
%         end 
        col_idx = ((k-1)*3+1):((k-1)*3+3); 
        med_array(i,col_idx) = median(TE_phases,'omitnan'); 
        prctl_25(i,col_idx) = prctile(TE_phases,25); % prctile treats NaNs as missing values and removes them
        prctl_75(i,col_idx) = prctile(TE_phases,75); % prctile treats NaNs as missing values and removes them
%         TE_conc_stats(i,4) = {min(TE_phases)}; % prctile treats NaNs as missing values and removes them
%         TE_conc_stats(i,5) = {max(TE_phases)}; % prctile treats NaNs as missing values and removes them
    end 
%     TE_conc_stats = array2table(TE_conc_stats); 
%     TE_conc_stats = horzcat(cell2table(boot_remov_TE(:,1:2)), TE_conc_stats); 
%     TE_conc_stats.Properties.VariableNames = {'Plant_Code','Plant_Boiler','median','percentile_25','percentile_75','min','max'}; 
%     TE_conc_stats = sortrows(TE_conc_stats,'median','ascend');
%     TE_conc_stats(isnan(TE_conc_stats.median),:) = []; % remove plants without TE information 
%     if k == 1
%         remov_stats_hg = TE_conc_stats;
%     elseif k == 2
%         remov_stats_se = TE_conc_stats;
%     elseif k == 3
%         remov_stats_as = TE_conc_stats;
%     elseif k == 4
%         remov_stats_cl = TE_conc_stats;
%     end 
end 

%%
% % create a histogram/cdf of coalqual blends by plant 
close all;
figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.15 0.15 0.8 0.8]) % x pos, y pos, x width, y height
for k = 1:4 
    subplot(2,2,k);
    trace_name_ppm = {'Hg_ppm','Se_ppm','As_ppm','Cl_ppm'}; 
    color = {'r','k','b','g'}; 

    % trace_coal_input = table2array(boot_cq_TE(:,trace_name_ppm)); 
    % % format long;
    % max_trace = max(trace_coal_input)

%     divide_array = [0.6 9 60 1500]; % defined based on the max_trace, but it's an arbitrary rule, so there's no way to automate this process
%     scale = max(divide_array); 

    hold on; 

    col_idx = ((k-1)*3+1):((k-1)*3+3); 
    plot_med = sort(med_array(:,col_idx));
    plot_med(isnan(plot_med(:,1)),:) = []; 
%     plotx = trace_coal_input.median*scale/divide_array(k);
    ploty = linspace(0,1,size(plot_med,1)); 
    
%     max_trace = max(trace_coal_input.median);
%     display([k, max_trace]);

    plot(plot_med(:,1),ploty,'-','LineWidth',1.8,'Color',color{2});
    plot(plot_med(:,2),ploty,':','LineWidth',1.8,'Color',color{3});
    plot(plot_med(:,3),ploty,'-.','LineWidth',1.8,'Color',color{1});

    set(gca,'FontName','Arial','FontSize',14)
    a=gca;
    axis([0 1 0 1]); 
    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    % a.XTickLabel = {'1','2','3','4'}; % placeholder as xtick labels are manipulated manually
    linkaxes([a b])

    if k == 1
        xlabel('Hg partitioning'); 
    elseif k == 2
        xlabel('Se partitioning'); 
    elseif k == 3
        xlabel('As partitioning'); 
    elseif k == 4
        xlabel('Cl partitioning'); 
    end 
    ylabel('F(x)'); 
    legend({'Solid','Liquid','Gas'},'Location','SouthEast'); legend boxoff; 
    grid off;
    title('');

end 

print('../Figures/TE_partition_by_boiler_cdf','-dpdf','-r300')
end 