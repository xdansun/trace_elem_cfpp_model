function [part_by_apc_link, part_by_apc_whole] = plot_link_vs_whole_partition(pm_removal, so2_removal, lit_phases_by_TE, fgd_ww_ratio)

%% solve for the median partition coefficients by each air pollution control device 
% using the linked based approach 

% find apcd codes from the literature studies 
lit_apcds = table2array(cell2table(pm_removal(:,2))); 
lit_hg = floor(rem(lit_apcds,10)); % pull the ACI control codes 
lit_pm = floor(rem(lit_apcds/100,10)); % pull the pm control codes 
lit_apcds = table2array(cell2table(so2_removal(:,2))); 
lit_nox = floor(rem(lit_apcds/10,10)); % pull the NOx control codes 
lit_so2 = floor(rem(lit_apcds/1000,10)); % pull the so2 control codes 

% find apcd codes based on part_by_apc_link
part_by_apc_link = [100 200 400 101 201 401 1100 1200 1400 1110]'; % note that 200 and 1200 (hsESP combinations) have no HAPS data
apcd_so2 = floor(rem(part_by_apc_link/1000,10)); % pull the so2 control codes 
apcd_pm = floor(rem(part_by_apc_link/100,10)); % pull the pm control codes 
apcd_nox = floor(rem(part_by_apc_link/10,10)); % pull the NOx control codes 
apcd_hg = floor(rem(part_by_apc_link,10)); % pull the ACI control codes 
part_by_apc_link = table2cell(array2table(part_by_apc_link)); 

for k = 2:4 % for Se, As, and Cl 
    for i = 1:size(part_by_apc_link,1)
        idx_pm = lit_pm == apcd_pm(i); % for Hg this will include ACI
        pm_studies = pm_removal(idx_pm == 1,:); 
        pm_studies_te = zeros(size(pm_studies,1),1); 
        for j = 1:size(pm_studies,1)
            % collect trace element partitioning for each study that includes the PM control
            pm_studies_te(j) = pm_studies{j,3}(1,k); 
        end 
        pm_studies_te = pm_studies_te(~isnan(pm_studies_te)); 

        if apcd_so2(i) > 0
            idx_so2 = lit_so2 == apcd_so2(i); % for Hg this will include SCR
            so2_studies = so2_removal(idx_so2 == 1,:); 
            so2_studies_te = zeros(size(so2_studies,1),1); 
            for j = 1:size(so2_studies,1)
                % collect trace element partitioning for each study that includes the SO2 control
                so2_studies_te(j) = so2_studies{j,3}(1,k); 
            end 
            so2_studies_te = so2_studies_te(~isnan(so2_studies_te)); 
        else
            so2_studies_te = nan; 
        end 

        % calculate median partitioning based on coefficients collected for
        % each air pollution control combination 
        if apcd_so2(i) > 0 
            pm = median(pm_studies_te,1,'omitnan'); 
            wfgd = median(so2_studies_te,1,'omitnan'); 
            solid = pm+(1-pm)*wfgd*(1-fgd_ww_ratio(k));
            liq = (1-pm)*wfgd*(fgd_ww_ratio(k));
            part_by_apc_link{i,k+1} = [solid liq 1-solid-liq]; 
        else
            solid = median(pm_studies_te,1,'omitnan'); 
            part_by_apc_link{i,k+1} = [solid 0 1-solid];
        end 

    end 

end 
%% for mercury 
for k = 1
    for i = 1:size(part_by_apc_link,1)
        idx_pm = int8(lit_pm == apcd_pm(i)) + int8(lit_hg == apcd_hg(i)); % for Hg this will include ACI
        pm_studies = pm_removal(idx_pm == 2,:); 
        pm_studies_te = zeros(size(pm_studies,1),1); 
        for j = 1:size(pm_studies,1) % collect trace element partitioning for each study that includes the PM control
            pm_studies_te(j) = pm_studies{j,3}(1,k); 
        end 
        pm_studies_te = pm_studies_te(~isnan(pm_studies_te)); 

        if apcd_so2(i) > 0  
            idx_so2 = int8(lit_so2 == apcd_so2(i)) + int8(lit_nox == apcd_nox(i)); % for Hg this will include SCR
            so2_studies = so2_removal(idx_so2 == 2,:); 
            so2_studies_te = zeros(size(so2_studies,1),1); 
            for j = 1:size(so2_studies,1) % collect trace element partitioning for each study that includes the SO2 control
                so2_studies_te(j) = so2_studies{j,3}(1,k); 
            end 
            so2_studies_te = so2_studies_te(~isnan(so2_studies_te)); 
        else
            so2_studies_te = nan; 
        end 

        % calculate median partitioning based on coefficients collected for
        % each air pollution control combination 
        if apcd_so2(i) > 0 
            pm = median(pm_studies_te,1,'omitnan'); 
            wfgd = median(so2_studies_te,1,'omitnan'); 
            solid = pm+(1-pm)*wfgd*(1-fgd_ww_ratio(k));
            liq = (1-pm)*wfgd*(fgd_ww_ratio(k));
            part_by_apc_link{i,k+1} = [solid liq 1-solid-liq]; 
        else
            solid = median(pm_studies_te,1,'omitnan'); 
            part_by_apc_link{i,k+1} = [solid 0 1-solid]; 
        end 

    end 

end 
%% solve for the median partition coefficients by each air pollution control device 
% for the system wide approach 
lit_apcds = table2array(cell2table(lit_phases_by_TE(:,2))); 
lit_pm = floor(rem(lit_apcds/100,10)); % pull the pm control codes 
lit_so2 = floor(rem(lit_apcds/1000,10)); % pull the so2 control codes 
part_by_apc_whole = [100 200 400 101 201 401 1100 1200 1400 1110]'; % note that 200 and 1200 (hsESP combinations) have no HAPS data
apcd_so2 = floor(rem(part_by_apc_whole/1000,10)); % pull the so2 control codes 
apcd_pm = floor(rem(part_by_apc_whole/100,10)); % pull the pm control codes 
part_by_apc_whole = table2cell(array2table(part_by_apc_whole)); 
k = 1; % for mercury 
for i = 1:size(part_by_apc_whole,1)
    idx = lit_apcds == part_by_apc_whole{i,1}; 
    studies = lit_phases_by_TE(idx == 1,k+2);
    studies_te = zeros(size(studies,1),3); 
    for j = 1:size(studies,1)
        studies_te(j,:) = studies{j,1}; 
    end 
    part_by_apc_whole{i,k+1} = median(studies_te,1,'omitnan'); 
end 
for k = 2:4 % for Se, As, and Cl 
    for i = 1:size(part_by_apc_whole,1)
        idx = int8(lit_pm == apcd_pm(i)) + int8(lit_so2 == apcd_so2(i)); % only care that the PM control and SO2 control match 
        studies = lit_phases_by_TE(idx == 2,k+2);
        studies_te = zeros(size(studies,1),3);
        for j = 1:size(studies,1)
            studies_te(j,:) = studies{j,1};
        end
        part_by_apc_whole{i,k+1} = median(studies_te,1,'omitnan');
    end
end 

%% plot the results for linked based process
% http://colorbrewer2.org/#type=diverging&scheme=RdYlBu&n=5
color_scheme = [215 25 28; 
                44 123 182;
                255 255 191]/255; 
close all;
all_data = part_by_apc_link;
for k = 1:4
    plot_data = zeros(1,3); 
    if k == 1
        for i = 1:size(all_data,1)
            plot_data(i,:) = all_data{i,k+1};
        end
    else
        part_data = all_data([1:3 7:9],:); % skip ACI and SCR specific air pollution control combinations 
        for i = 1:size(part_data,1)
            plot_data(i,:) = part_data{i,k+1};
        end
    end 

    if k == 1
        figure('Color','w','Units','inches','Position',[0.25 3.25 9 3]) % was 1.25
        axes('Position',[0.15 0.4 0.7 0.5]) % x pos, y pos, x width, y height
    else
        figure('Color','w','Units','inches','Position',[0.25 3.25 3 3]) % was 1.25
        axes('Position',[0.25 0.35 0.7 0.55]) % x pos, y pos, x width, y height
    end 
    hold on;

    bar(plot_data,'stacked','BarWidth',0.5)
    colormap(color_scheme)

    set(gca,'FontName','Arial','FontSize',11)
    a=gca;
    if k == 1
        a.XTick = (0:size(all_data,1)); % need to customize
        a.XTickLabel = {'','csESP','hsESP','FF','ACI+csESP','ACI+hsESP',...
            'ACI+FF','csESP+wFGD','hsESP+wFGD','FF+wFGD','SCR+csESP+wFGD',''}; 
    else 
        a.XTick = (0:size(part_data,1)); % need to customize
        a.XTickLabel = {'','csESP','hsESP','FF',...
            'csESP+wFGD','hsESP+wFGD','FF+wFGD',''}; 
    end 
    a.XTickLabelRotation = 45; 
    set(a,'box','off','color','none')
    ylim([0 1]);
    if k > 2 
        xlim([0 size(part_data,1)]);
    end 
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    linkaxes([a b])

    %     xlabel('air pollution control combinations');
    if k == 1
        ylabel('Hg partition fraction');
        legend('Solid','Liquid','Air');
        legend boxoff;
    elseif k == 2
        ylabel('Se partition fraction');
    elseif k == 3
        ylabel('As partition fraction');
    elseif k == 4
        ylabel('Cl partition fraction');
    end
    title('B');
    
    print(strcat('../Figures/Fig_med_part_by_apcd_link',num2str(k)),'-dpdf','-r300'); 

end

%% plot the results using whole system approach 
% http://colorbrewer2.org/#type=diverging&scheme=RdYlBu&n=5
color_scheme = [215 25 28; 
                44 123 182;
                255 255 191]/255; 
% close all;
all_data = part_by_apc_whole;
for k = 1:4
    plot_data = zeros(1,3); 
    if k == 1
        for i = 1:size(all_data,1)
            plot_data(i,:) = all_data{i,k+1};
        end
    else
        part_data = all_data([1:3 7:9],:); % skip ACI and SCR specific air pollution control combinations 
        for i = 1:size(part_data,1)
            plot_data(i,:) = part_data{i,k+1};
        end
    end 

    if k == 1
        figure('Color','w','Units','inches','Position',[0.25 3.25 9 3]) % was 1.25
        axes('Position',[0.15 0.4 0.7 0.5]) % x pos, y pos, x width, y height
    else
        figure('Color','w','Units','inches','Position',[0.25 3.25 3 3]) % was 1.25
        axes('Position',[0.25 0.35 0.7 0.55]) % x pos, y pos, x width, y height
    end 
    hold on;

    bar(plot_data,'stacked','BarWidth',0.5)
    colormap(color_scheme)

    set(gca,'FontName','Arial','FontSize',11)
    a=gca;
    if k == 1
        a.XTick = (0:size(all_data,1)); % need to customize
        a.XTickLabel = {'','csESP','hsESP','FF','ACI+csESP','ACI+hsESP',...
            'ACI+FF','csESP+wFGD','hsESP+wFGD','FF+wFGD','SCR+csESP+wFGD',''}; 
    else 
        a.XTick = (0:size(part_data,1)); % need to customize
        a.XTickLabel = {'','csESP','hsESP','FF',...
            'csESP+wFGD','hsESP+wFGD','FF+wFGD',''}; 
    end 
    a.XTickLabelRotation = 45; 
    set(a,'box','off','color','none')
    ylim([0 1]);
    if k > 2 
        xlim([0 size(part_data,1)]);
    end 
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    linkaxes([a b])

    %     xlabel('air pollution control combinations');
    if k == 1
        ylabel('Hg partition fraction');
        legend('Solid','Liquid','Air');
        legend boxoff;
    elseif k == 2
        ylabel('Se partition fraction');
    elseif k == 3
        ylabel('As partition fraction');
    elseif k == 4
        ylabel('Cl partition fraction');
    end
    title('A');
    
    print(strcat('../Figures/Fig_med_part_by_apcd_whole',num2str(k)),'-dpdf','-r300'); 

end

end 