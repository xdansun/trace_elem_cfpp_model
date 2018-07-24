function legend_cell = plot_TE_partition_link(pm_removal, so2_removal, fgd_ww_ratio)
% calculate air, solid, and liquid removals 
% plots link based approach 

%% plot by air pollution control combination 
% 0 is irrelevant, 100 is csESP, 101 is csESP+ACI, 200 is hsESP, 400 is FF,
% 401 is FF + ACI , 1100 is wFGD + csESP, 1110 is SCR+csESP+wFGD, 1200 is
% wFGD + hsESP, 1210 is wFGD+hsESP+SCR, 1400 FF+wFGD, 1401 ACI+FF+wFGD, etc
% it may be worth only showing control combinations we have data for 

%% plot figure

pm_removal(20,2) = {500}; % update laird et al. for the DSI removals 
pm_removal(21,2) = {701}; % change codes on ACI studies so that the graph can be ordered correctly
pm_removal(22,2) = {702};  
pm_removal(11,2) = {703}; 
pm_removal(23,2) = {902}; % change codes on dFGD studies so they appear in the right order 
pm_removal(24,2) = {904}; 
pm_removal(25,2) = {903}; 
so2_removal{end,3} = [nan nan nan nan]; 

apcd_hg = floor(rem(table2array(cell2table(pm_removal(:,2)))/1,10)); % pull the hg control codes 
apcd_nox = floor(rem(table2array(cell2table(so2_removal(:,2)))/10,10)); % pull the nox control codes 
apcd_pm = floor(rem(table2array(cell2table(pm_removal(:,2)))/100,10)); % pull the pm control codes 
apcd_so2 = floor(rem(table2array(cell2table(so2_removal(:,2)))/1000,10)); % pull the so2 control codes 
pm_removal_apc = horzcat(pm_removal, table2cell(array2table(apcd_pm)), table2cell(array2table(apcd_hg))); 
so2_removal_apc = horzcat(so2_removal, table2cell(array2table(apcd_so2)), table2cell(array2table(apcd_nox))); 
% pm_removal_apc(20,2) = ; 
test = zeros(1,1); 

close all;
for k = 1:4
    plot_data = zeros(1,3); 
    legend_cell = cell(1,1); 
    idx = 1; 
    unique_pm = unique(apcd_pm); 
    for i = 1:size(unique_pm,1)
        apcd_index = find(apcd_pm == unique_pm(i)); 
        pm_removal_subset = pm_removal_apc(apcd_index,:);
        for j = 1:size(pm_removal_subset,1) 
            pm_removal_subset{j,6} = pm_removal_subset{j,3}(1,k);
        end 
        % need to order the studies by air pollution controls so that axis is formatted 
        pm_removal_subset = cell2table(pm_removal_subset);
        pm_removal_subset = sortrows(pm_removal_subset,'pm_removal_subset6','ascend'); % order by removal 
        pm_removal_subset = sortrows(pm_removal_subset,'pm_removal_subset5','ascend'); % order by hg control
        pm_removal_subset = sortrows(pm_removal_subset,'pm_removal_subset4','ascend'); % order by pm control
        pm_removal_subset = table2cell(pm_removal_subset);
        for j = 1:size(apcd_index,1)
            removal = pm_removal_subset{j,6};
            if isnan(removal) == 0
                plot_data(idx,:) = [removal 0 1-removal]; 
                test(idx,1) = pm_removal_subset{j,2};
                idx = idx + 1;
                legend_cell(idx,1) = pm_removal_subset(j,1);
            end 
        end 
    end
    unique_so2 = unique(apcd_so2); 
    for i = 1:size(unique_so2,1)
        apcd_index = find(apcd_so2 == unique_so2(i)); 
        so2_removal_subset = so2_removal_apc(apcd_index,:);
        for j = 1:size(so2_removal_subset,1) 
            so2_removal_subset{j,6} = so2_removal_subset{j,3}(1,k);
        end 
        % need to order the studies by air pollution controls so that axis is formatted 
        so2_removal_subset = cell2table(so2_removal_subset);
        so2_removal_subset = sortrows(so2_removal_subset,'so2_removal_subset6','ascend'); % order by removal 
        so2_removal_subset = sortrows(so2_removal_subset,'so2_removal_subset5','ascend'); % order by hg control
        so2_removal_subset = sortrows(so2_removal_subset,'so2_removal_subset4','ascend'); % order by pm control
        so2_removal_subset = table2cell(so2_removal_subset);
        for j = 1:size(apcd_index,1)
            removal = so2_removal_subset{j,6};
            if isnan(removal) == 0
                plot_data(idx,:) = [removal*(1-fgd_ww_ratio(k)) removal*fgd_ww_ratio(k) 1-removal]; % double check to make sure fgd_ww_ratio makes sense here 
                test(idx,1) = so2_removal_subset{j,2};
                idx = idx + 1;
                legend_cell(idx,1) = so2_removal_subset(j,1); 
                
            end 
        end 
    end
    
    % http://colorbrewer2.org/#type=diverging&scheme=RdYlBu&n=5
    color_scheme = [215 25 28;
                44 123 182;
                255 255 191]/255; 
            
    if k == 1 % if Hg 
        figure('Color','w','Units','inches','Position',[0.25 3.25 9.5 3]) % was 1.25
    elseif k == 2 % if Se
        figure('Color','w','Units','inches','Position',[0.25 3.25 4.5 3]) % was 1.25
    elseif k == 3 % if As
        figure('Color','w','Units','inches','Position',[0.25 3.25 3.8 3]) % was 1.25
    else
        figure('Color','w','Units','inches','Position',[0.25 3.25 3.2 3]) % was 1.25
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
        ylabel('Hg partitioning fraction');
%         legend('Solid','Liquid','Air');
%         legend boxoff;
    elseif k == 2
        ylabel('Se partitioning fraction');
    elseif k == 3
        ylabel('As partitioning fraction');
    elseif k == 4
        ylabel('Cl partitioning fraction');
    end
    
    print(strcat('../Figures/Fig2_TE_partition_by_study_',num2str(k)),'-dpdf','-r300'); 

end

end 

