function plot_med_emf_cdf_plt_subrgn(boot_emis_hg, boot_emis_se, boot_emis_as, boot_emis_cl,subrgn)
%% DESCRIPTION NEEDED 

%% for each boiler, calculate the median emf of each trace element 
med_array = nan(400,12); 
for k = 1:4
    if k == 1
        boot_emis_TE = boot_emis_hg; 
    elseif k == 2
        boot_emis_TE = boot_emis_se; 
    elseif k == 3
        boot_emis_TE = boot_emis_as; 
    elseif k == 4
        boot_emis_TE = boot_emis_cl; 
    end 
    % exclude boiler 1010_5 
    % NEED TO ASK INES IF THIS IS THE APPROPRIATE WAY TO HANDLE THIS 
    % this boiler has large fuel consumption to generation, see histogram 
    % most coal boilers have fuel consumption to generation ~= 0-2
    % tons/MWh. Boiler 1010_5 has a ratio of almost 20. Therefore, it's
    % emission factors appears arbitrarily larger than all others 
%     histogram(coal_gen_boiler_wapcd_code.Fuel_Consumed./coal_gen_boiler_wapcd_code.Net_Generation_Year_To_Date); xlim([0 20]);
%     median(boot_emis_TE.emf_mg_MWh{strcmp(boot_emis_TE.Plant_Boiler,'1010_5'),1})
%     boot_emis_TE(strcmp(boot_emis_TE.Plant_Boiler,'1010_5'),:) = []; % this excludes 1010_5 from visualization 
    emfs_at_blr = boot_emis_TE.emf_mg_MWh; 
    
    emfs = zeros(size(emfs_at_blr,1),3); 
    for i = 1:size(emfs_at_blr,1)
        emfs(i,:) = median(emfs_at_blr{i,1},'omitnan'); 
        emfs(emfs < 0) = nan; % set negative emfs to negative numbers.
%         These are from boilers with negative emissions 
    end
   
    med_array(1:size(emfs),((k-1)*3+1):((k-1)*3+3)) = emfs;
end 

%% create cdf 

close all;
figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.15 0.15 0.75 0.75]) % x pos, y pos, x width, y height
color = {'r','k','b','g'};
for k = 1:4 
    subplot(2,2,k);
    hold on; 

    col_idx = ((k-1)*3+1):((k-1)*3+3); 
    plot_med = sort(med_array(:,col_idx));
%     plot_med(isnan(plot_med(:,1)),:) = []; 
    plotx1 = plot_med(~isnan(plot_med(:,1)),1)/1000; 
    plotx2 = plot_med(~isnan(plot_med(:,2)),2)/1000; 
    plotx3 = plot_med(~isnan(plot_med(:,3)),3)/1000; 
    ploty1 = linspace(0,1,size(plotx1,1)); 
    ploty2 = linspace(0,1,size(plotx2,1)); 
    ploty3 = linspace(0,1,size(plotx3,1)); 
    
%     max_trace = max(trace_coal_input.median);
%     display([k, max_trace]);

    plot(plotx1,ploty1,'-','LineWidth',1.8,'Color',color{2});
    plot(plotx2,ploty2,':','LineWidth',1.8,'Color',color{3});
    plot(plotx3,ploty3,'-.','LineWidth',1.8,'Color',color{1});

    set(gca,'FontName','Arial','FontSize',13)
    a=gca;
   
    if k == 1
        xlabel('Median Hg emission factor (g/MWh)'); 
    elseif k == 2
        xlabel('Median Se emission factor (g/MWh)'); 
    elseif k == 3
        xlabel('Median As emission factor (g/MWh)'); 
    elseif k == 4
        xlabel('Median Cl emission factor (g/MWh)'); 
    end 
    ylabel('F(x)'); 
%     if k == 1
    legend({'Solid','Liquid','Gas'},'Location','SouthEast'); legend boxoff;
%     end
    grid off;
    title(subrgn);
    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    linkaxes([a b])
    
    scale = [0.15 8 20 600];
    axis([0 scale(k) 0 1]);
    
end 
% if size(boot_emis_hg,2) > 4 && size(boot_emis_hg,1) > 0 % implies there are subrgns attached
%     suptitle(boot_emis_hg.egrid_subrgn{1,1});
print(strcat('../Figures/Fig_emf_plant_cdf_',subrgn),'-dpdf','-r300')
% else
%     print('Figures/dummy_TE_emf_cdf','-dpdf','-r300')
% end

end 