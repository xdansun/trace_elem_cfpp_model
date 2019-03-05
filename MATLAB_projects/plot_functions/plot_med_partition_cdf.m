function med_array = plot_med_partition_cdf(boot_remov_hg, boot_remov_se, boot_remov_as, boot_remov_cl)
%% Description
% plot a cdf of the partitioning coefficient to the solid, liquid, gas
% at the boiler level
%
% inputs
% boot_remov_hg (cell) - all boilers in analysis with bootstrapped partitioning
% coefficients. Column 1 is the plant, column 2 is the boiler, and column 3
% are the bootstrapped partitioning coefficients to solid, liquid, and gas.
%
% outputs
% med_array (array) - plot outputs 
%% 
med_array = nan(1000,12);
prctl_25 = nan(1000,12);
prctl_75 = nan(1000,12);

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

    for i = 1:size(boot_remov_TE,1)
        TE_phases = boot_remov_TE{i,3};
        TE_phases(isnan(TE_phases(:,2)),2) = 0; % set all liquid nan removals to zero  
        col_idx = ((k-1)*3+1):((k-1)*3+3); 
        med_array(i,col_idx) = median(TE_phases,'omitnan'); 
        prctl_25(i,col_idx) = prctile(TE_phases,25); % prctile treats NaNs as missing values and removes them
        prctl_75(i,col_idx) = prctile(TE_phases,75); % prctile treats NaNs as missing values and removes them
    end 
end 

%% create a histogram/cdf of coalqual blends by plant 
close all;
figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.15 0.15 0.8 0.8]) % x pos, y pos, x width, y height
for k = 1:4 
    subplot(2,2,k);
    color = {'r','k','b','g'}; 

    % trace_coal_input = table2array(boot_cq_TE(:,trace_name_ppm)); 
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