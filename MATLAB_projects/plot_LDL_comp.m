function plot_LDL_comp(coal_gen_boiler_apcd, coal_purchases_2015)
%% Description 
% Compare the concentration of trace elements in the coal blend at the
% plant level for each trace elements under different assumptions of what
% the lower detection limit (default is 0.7) 
% 
% this analysis is done with uncorrelated assumptions (assumes trace
% elements are independent of each other) 
% 
% input
% coal_gen_boiler_apcd (table): plant:boiler:gen:fuel:apcd
% coal_purchases_2015 (table): all coal purchases made in 2015 
% 
% output
% SI Figure in pdf 

%% 
LDL_flag = 0.7;
[cq_hg_2015, cq_se_2015, cq_as_2015, cq_cl_2015] = ...
    coalqual_dist_uncorrelated(coal_gen_boiler_apcd, coal_purchases_2015, 0, LDL_flag);

trials = 10000;
boot_cq_TE = boot_coal_blend_conc_uncorr(coal_gen_boiler_apcd, cq_hg_2015, cq_se_2015, cq_as_2015, cq_cl_2015, trials);

boiler_input = zeros(size(boot_cq_TE,1),4);
for k = 1:4
    for i = 1:size(boot_cq_TE,1)
        boiler_input(i,k) = median(boot_cq_TE{i,k+1}); 
    end 
end
% LDL = 0
% create discrete distributions of trace element concentrations in coal 
LDL_flag = 0; % LDL flag = 0.7 means do nothing, LDL flag 1 means set all LDLs to zero 
[cq_hg0, cq_se0, cq_as0, cq_cl0] = coalqual_dist_uncorrelated(coal_gen_boiler_apcd, coal_purchases_2015, 0, LDL_flag);

% bootstrap TE concentrations in coal blends for all plants in analysis 
boot_cq_TE = boot_coal_blend_conc_uncorr(coal_gen_boiler_apcd, cq_hg0, cq_se0, cq_as0, cq_cl0, trials);

plant_ppm0 = zeros(size(boot_cq_TE,1),4);
for k = 1:4
    for i = 1:size(boot_cq_TE,1)
        plant_ppm0(i,k) = median(boot_cq_TE{i,k+1}); 
    end 
end
% LDL = 1
LDL_flag = 1; 
[cq_hg1, cq_se1, cq_as1, cq_cl1] = coalqual_dist_uncorrelated(coal_gen_boiler_apcd, coal_purchases_2015, 0, LDL_flag);

% bootstrap TE concentrations in coal blends for all plants in analysis 
boot_cq_TE = boot_coal_blend_conc_uncorr(coal_gen_boiler_apcd, cq_hg1, cq_se1, cq_as1, cq_cl1, trials);

plant_ppm1 = zeros(size(boot_cq_TE,1),4);
for k = 1:4
    for i = 1:size(boot_cq_TE,1)
        plant_ppm1(i,k) = median(boot_cq_TE{i,k+1}); 
    end 
end 

%% plot cdf showing LDL = 0, LDL = 0.7, and LDL = 1
close all; 
figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height
for k = 1:4
    subplot(2,2,k);
%     color = {'r','k','b','g'}; 
    hold on;
    if k == 1
        set(gca, 'Position', [0.15 0.6 0.3 0.33])
    elseif k == 2
        set(gca, 'Position', [0.6 0.6 0.3 0.33])
    elseif k == 3
        set(gca, 'Position', [0.15 0.15 0.3 0.33])
    elseif k == 4
        set(gca, 'Position', [0.6 0.15 0.3 0.33])
    end 
    
    divide_array = [0.6 9 60 1600]; % defined based on the max_trace, based on 25th and 75th percentile 
    hold on; 

%     plotx = sort(plant_ppm(:,k));
%     plotx = sort(plant_ppm1(:,k) - plant_ppm0(:,k));
%     temp = array2table([plant_ppm0(:,k) plant_ppm1(:,k)]);
    plotx0 = sort(plant_ppm0(:,k));
    plotx1 = sort(plant_ppm1(:,k));
    
%     ploty = linspace(0,1,size(plotx,1)); 
     
%     h = plot(plotx,linspace(0,1,size(plotx,1)),'-');
%     set(h,'LineWidth',1.8,'Color',color{k});
    h = plot(plotx0,linspace(0,1,size(plotx0,1)),'-');
    set(h,'LineWidth',1.8,'Color','r');
    h = plot(plotx1,linspace(0,1,size(plotx1,1)),':');
    set(h,'LineWidth',1.8,'Color','k');

%     plot(plotx25,ploty,':','Color',color{k},'MarkerSize',5,'LineWidth',1.8);
%     plot(plotx75,ploty,':','Color',color{k},'MarkerSize',5,'LineWidth',1.8);

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
        xlabel(['Median Hg concentration' char(10) 'in coal blend (ppm)']); 
    elseif k == 2
        xlabel(['Median Se concentration' char(10) 'in coal blend (ppm)']); 
    elseif k == 3
        xlabel(['Median As concentration' char(10) 'in coal blend (ppm)']); 
    elseif k == 4
        xlabel(['Median Cl concentration' char(10) 'in coal blend (ppm)']); 
    end 
    legend({'0\timesLDL','1\timesLDL'},'Location','SouthEast'); legend boxoff; 
    grid off;
    title('');

end 

print('../Figures/Fig_conc_LDL_cdf','-dpdf','-r300')

end 