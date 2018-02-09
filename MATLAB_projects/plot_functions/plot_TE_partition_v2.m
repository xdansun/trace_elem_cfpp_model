function [lit_phases_by_TE, legend_cell] = plot_TE_partition_v2(lit_removal)
% description needed 

% calculate air, solid, and liquid removals 
% merge pm removal into so2 removal; use strcmp to determine which are
% worth adding 

%% plot by air pollution control combination 
% 0 is irrelevant, 100 is csESP, 101 is csESP+ACI, 200 is hsESP, 300 is FF,
% 301 is FF + ACI , 1100 is wFGD + csESP, 1110 is SCR+csESP+wFGD, 1200 is
% wFGD + hsESP, 1210 is wFGD+hsESP+SCR, 1300 FF+wFGD, 1301 ACI+FF+wFGD, etc
% it may be worth only showing control combinations we have data for 

%% convert lit_removal to cell for plot
lit_to_plot = cell2table(lit_removal); 
lit_to_plot.lit_removal2(11) = 703; % for the Flora study
lit_to_plot.lit_removal2(end-2) = 1000; % for the DSI study
lit_to_plot.lit_removal2(end-1) = 701; % set NRMRL to arbitrarily large apcd codes so that the plot can plot them in the correct order 
lit_to_plot.lit_removal2(end) = 702;
lit_to_plot = sortrows(lit_to_plot,'lit_removal1','ascend'); % plot by pollution combination 
lit_to_plot = sortrows(lit_to_plot,'lit_removal2','ascend'); % plot by pollution combination 
lit_removal = table2cell(lit_to_plot); 


%% calculate solids, liquids, and gas for each trace element 
gas = zeros(size(lit_removal,1),4);
liq = zeros(size(lit_removal,1),4);
solid = zeros(size(lit_removal,1),4);
for i = 1:size(lit_removal,1)
    gas(i,:) = lit_removal{i,7};
    liq(i,:) = lit_removal{i,6};
    solid(i,:) = lit_removal{i,3} + lit_removal{i,4} + lit_removal{i,5};
end 
gas(gas == 0) = nan; 
liq(liq == 0) = nan; 
solid(solid == 0) = nan; 

lit_phases = horzcat(lit_removal(:,1), lit_removal(:,2)); %,...
for i = 1:size(lit_phases,1)
    lit_phases(i,3) = {solid(i,:)}; 
    lit_phases(i,4) = {liq(i,:)}; 
    lit_phases(i,5) = {gas(i,:)}; 
    % double check that solid, liq, gases add up to one
    for k = 1:4
        if abs(solid(i,k) + liq(i,k) + gas(i,k) - 1) > 1e-5 && isnan(solid(i,k) + liq(i,k) + gas(i,k)) ~= 1 % if the phases do not add up to one or is not a number 
            [i,k]
            solid(i,k) + liq(i,k) + gas(i,k)
            error('problem'); 
        end 
    end 
end 
%     table2cell(array2table(solid)),table2cell(array2table(liq)),table2cell(array2table(gas))); 

lit_phases_by_TE = lit_removal(:,1:2); 
for k = 1:4
    for i = 1:size(lit_phases,1)
        lit_phases_by_TE(i,k+2) = {[solid(i,k) liq(i,k) gas(i,k)]}; 
    end 
end 
% lit_phases_by_TE = cell2table(lit_phases_by_TE); 
% lit_phases_by_TE = table2cell(lit_phases_by_TE); 
%% plot figure
% http://colorbrewer2.org/#type=diverging&scheme=RdYlBu&n=5
color_scheme = [215 25 28; 
                44 123 182;
                255 255 191]/255; 
close all;
for k = 1:4
    plot_data = zeros(1,3); 
    legend_cell = cell(1,1); 
    idx = 1; 
    unique_apcds = unique(table2array(cell2table(lit_phases_by_TE(:,2)))); 
    all_apcds = table2array(cell2table(lit_phases_by_TE(:,2)));
    for i = 1:size(unique_apcds,1)
        apcd_index = find(all_apcds == unique_apcds(i)); 
        lit_for_apcds = zeros(1,3);
        for j = 1:size(apcd_index,1)
            lit_for_apcds(j,:) = lit_phases_by_TE{apcd_index(j), k+2};
        end 
        lit_for_apcds = array2table(lit_for_apcds);
        lit_for_apcds = horzcat(cell2table(lit_phases_by_TE(apcd_index, 1)), lit_for_apcds);
        lit_for_apcds = sortrows(lit_for_apcds,'lit_for_apcds1','ascend');
        for j = 1:size(lit_for_apcds,1)
            if sum(isnan(lit_for_apcds{j,2:4})) < 3 % if there exists lit removal data for that TE
                plot_data(idx,:) = lit_for_apcds{j,2:4}; 
                idx = idx + 1;
                legend_cell(idx,1) = lit_for_apcds{j,1}; 
            end 
        end 
    end 
%     for i = 1:size(lit_phases_by_TE,1)
%         if sum(isnan(lit_phases_by_TE{i,k+2})) < 3 % if there exists lit removal data for that TE
%             plot_data(idx,:) = lit_phases_by_TE{i,k+2}; 
%             idx = idx + 1;
%             legend_cell(idx,1) = lit_phases_by_TE(i,1); 
%         end 
%     end 

    if k == 1
        figure('Color','w','Units','inches','Position',[0.25 3.25 9 3]) % was 1.25
    else
        figure('Color','w','Units','inches','Position',[0.25 3.25 3 3]) % was 1.25
    end 
    axes('Position',[0.15 0.35 0.8 0.6]) % x pos, y pos, x width, y height
    hold on;

    bar(plot_data,'stacked','BarWidth',0.5)
    colormap(color_scheme)

    set(gca,'FontName','Arial','FontSize',11)
    a=gca;
    a.XTick = (0:idx); % need to customize
    a.XTickLabel = legend_cell; 
    a.XTickLabelRotation = 45; 
    set(a,'box','off','color','none')
    %     xlim([0.5 3.5]);
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    linkaxes([a b])

    %     xlabel('air pollution control combinations');
    if k == 1
        ylabel('Hg removal fraction');
        legend('Solid','Liquid','Air');
        legend boxoff;
    elseif k == 2
        ylabel('Se removal fraction');
    elseif k == 3
        ylabel('As removal fraction');
    elseif k == 4
        ylabel('Cl removal fraction');
    end
    
    print(strcat('../Figures/Fig2_TE_partition_by_study_',num2str(k)),'-dpdf','-r300'); 

end

%% correct output
lit_phases_by_TE(11:14,2) = {101, 201, 401, 4000}; 

end 

