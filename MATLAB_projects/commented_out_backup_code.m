
%% check how many have retired for comparing coal purchases between 2010 and 2015 
% [num,txt,raw] = xlsread('EIA_860\3_1_Generator_Y2015.xlsx','Retired and Canceled');
% column_numbers = [3 7 24]; % identify columns of interest from raw data files
% row_start = 2; % spreadsheet starts on row 2
% % create a table of all the generators with certain columns of data 
% retire_generators = table_scrub(raw, column_numbers, row_start);
% % create Gen_ID
% col1 = 'Plant_Code'; 
% col2 = 'Generator_ID';
% retire_generators = merge_two_col(retire_generators, col1, col2, {'Plant_Gen'});
% %% 
% retire_generators = retire_generators(strcmp(retire_generators.Status,'RE'),:); 
% retire_plants = unique(retire_generators(:,{'Plant_Code'})); 
% foo = innerjoin(retire_plants, plant_trace_haps);
% test2 = innerjoin(foo, unique(coal_gen_boiler_apcd(:,{'Plant_Code'})));
% match_plants = innerjoin(plant_trace_haps, unique(coal_generators(:,{'Plant_Code'})));
% 
% %% check how many fuel switched
% [num,txt,raw] = xlsread('EIA_860\3_1_Generator_Y2015.xlsx','Operable');
% column_numbers = [3 7 8]; % identify columns of interest from raw data files
% row_start = 2; % spreadsheet starts on row 2
% all_generators = table_scrub(raw, column_numbers, row_start);

%% plot coal blends between plants, comparing 2010 and 2015 purchases 
% close all;
% amt_purch = amt_purch_2010;
% figure; 
% for i = 1:20
%     hold on;
%     ploty = amt_purch.coal_blend{i,1}; 
%     plotx = ones(size(ploty,1),1)*i;
%     plot(plotx, ploty,'*')
% 
%     for j = 1:size(plotx,1)
%         if j > 3
%             break;
%         end
%         txt1 = num2str(amt_purch.county{i,1}(j,1));
%         text(plotx(j)+0.1,ploty(j),txt1);
%     end
% end 
% 
% amt_purch = amt_purch_2015;
% figure; 
% for i = 1:20
%     hold on;
%     ploty = amt_purch.coal_blend{i,1}; 
%     plotx = ones(size(ploty,1),1)*i;
%     plot(plotx, ploty,'*')
% 
%     for j = 1:size(plotx,1)
%         if j > 3
%             break;
%         end
%         txt1 = num2str(amt_purch.county{i,1}(j,1));
%         text(plotx(j)+0.1,ploty(j),txt1);
%     end
% end 

%%
% amt_purch_2010 = innerjoin(amt_purch_2010, comp_cq_haps(:,{'Plant_Code'})); 
% % compile coal purchase data in 2015 for plants appearing in CQ and HAPS
% amt_purch_2015 = cell2table(cq_hg_2015(:,1:3)); 
% amt_purch_2015.Properties.VariableNames = {'Plant_Code','county','tons'};
% amt_purch_2015 = innerjoin(amt_purch_2015, amt_purch_2010(:,{'Plant_Code'})); 
% % for each county, truncate the number (not interested in difference
% % between ranks of coal) 
% amt_purch = amt_purch_2010
% for i = 1:size(amt_purch,1)
%     counties = amt_purch.county{i,1};
%     amt_purch.county{i,1} = round(counties);
% end 
% amt_purch_2010 = amt_purch; 
% % repeat for 2015
% amt_purch = amt_purch_2015;
% for i = 1:size(amt_purch,1)
%     counties = amt_purch.county{i,1};
%     amt_purch.county{i,1} = round(counties);
% end 
% amt_purch_2015 = amt_purch; 
% 
% % estimate coal blend per each county 
% amt_purch = amt_purch_2010; 
% coal_blend = cell(size(amt_purch,1),1); 
% for i = 1:size(amt_purch,1)
%     coal_blend(i,1) = {amt_purch.tons{i,1}/sum(amt_purch.tons{i,1})};
% end 
% amt_purch(:,end+1) = coal_blend; 
% amt_purch.Properties.VariableNames(end) = {'coal_blend'};
% amt_purch_2010 = amt_purch; 
% 
% amt_purch = amt_purch_2015; 
% coal_blend = cell(size(amt_purch,1),1); 
% for i = 1:size(amt_purch,1)
%     coal_blend(i,1) = {amt_purch.tons{i,1}/sum(amt_purch.tons{i,1})};
% end 
% amt_purch(:,end+1) = coal_blend; 
% amt_purch.Properties.VariableNames(end) = {'coal_blend'};
% amt_purch_2015 = amt_purch; 
% 
% %% number of counties in 2010 that appeared again in 2015
% frac = zeros(size(amt_purch_2010,1),1); 
% for i = 1:size(amt_purch_2010,1)
%     counties_2010 = amt_purch_2010.county{i,1};
%     counties_2015 = amt_purch_2015.county{i,1};
%     for j = 1:size(counties_2010,1)
%         idx = counties_2010(j,1) == counties_2015; 
%         if sum(idx > 0)
%             1
%         else 
%             frac(i) = frac(i) + 1; 
%         end 
%     end 
%     % num
%     frac(i) = frac(i)/size(counties_2010,1);
% end
% histogram(frac,'BinMethod','fd')
% 
% 
% %% estimate the squared error for each plant 
% % amt_purch = amt_purch_2010;
% dif = zeros(size(amt_purch_2010,1),1); 
% for i = 21% 1:size(amt_purch_2010,1)
%     counties_2010 = amt_purch_2010.county{i,1};
%     counties_2015 = amt_purch_2015.county{i,1};
%     coal_blend_2010 = amt_purch_2010.coal_blend{i,1};
%     coal_blend_2015 = amt_purch_2015.coal_blend{i,1};
%     num = zeros(size(counties_2010,1),1); 
%     for j = 1:size(counties_2010,1)
%         idx = counties_2010(j,1) == counties_2015; 
%         if sum(idx == 0)
%             num(j) = coal_blend_2010(j,1)^2; 
%         else
%             num(j) = (coal_blend_2015(idx,1) - coal_blend_2010(j))^2; 
%         end 
%     end 
%     % num
%     dif(i) = sum(num)/sum(coal_blend_2010.*coal_blend_2010); 
% end
% 
% plot(dif,'*');

%% compare coal purchases in 2010 and in 2015
% % comp_cq_haps = innerjoin(boot_cq_TE_2010_tbl, plant_trace_haps); % merge HAPS data with CQ bootstrap  
% % compile coal purchase data in 2010 for plants appearing in CQ and HAPS
% amt_purch_2010 = cell2table(cq_hg_2010(:,1:3)); 
% amt_purch_2010.Properties.VariableNames = {'Plant_Code','county','tons'};
% % iterate through all plants to make sure that all plants have actual
% % county data 
% flag = zeros(size(amt_purch_2010,1),1); 
% for i = 1:size(amt_purch_2010,1)
%     if size(amt_purch_2010.county{i,1},1) == 0
%         flag(i) = 1; 
%     end 
% end 
% amt_purch_2010(flag == 1,:) = []; 
% % amt_purch_2010 = innerjoin(amt_purch_2010, comp_cq_haps(:,{'Plant_Code'})); 
% 
% amt_purch_2015 = cell2table(cq_hg_2015(:,1:3)); 
% amt_purch_2015.Properties.VariableNames = {'Plant_Code','county','tons'};
% amt_purch_2015 = innerjoin(amt_purch_2015, amt_purch_2010(:,{'Plant_Code'})); 
% 
% %% number of counties that appeared in 2010 or 2015 but not in both 
% frac = zeros(size(amt_purch_2010,1),1); 
% for i = 1:size(amt_purch_2010,1) % for each plant in 2010 
%     counties_2010 = amt_purch_2010.county{i,1};
%     counties_2015 = amt_purch_2015.county{i,1};
%     counties = unique(vertcat(counties_2010, counties_2015)); 
%     for j = 1:size(counties,1)
%         idx1 = counties(j,1) == counties_2010; 
%         idx2 = counties(j,1) == counties_2015; 
%         if sum(idx1 > 0) && sum(idx2 > 0)
%             1;
%             frac(i) = frac(i) + 1; % count number of counties that appear in both 2010 and 2015 
%         else
%             1;
%         end 
%     end 
%     % num
%     frac(i) = frac(i)/size(counties,1); % estimate purchase fraction 
% end
% 
% %% plot figure 
% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height
% 
% plotx = sort(frac);
% ploty = linspace(0,1,size(plotx,1));
% 
% % histogram(frac,'BinWidth',0.1)
% plot(plotx, ploty,'k','LineWidth',1.6);
% 
% set(gca,'FontName','Arial','FontSize',14)
% a=gca;
% axis([0 1 0 1]);
% set(a,'box','off','color','none')
% b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
% axes(a)
% linkaxes([a b])
% 
% ylabel('F(x)');
% xlabel('Purchase fraction');
% 
% grid off;
% title('');
% 
% print(strcat('Figures/purchase_fraction_cdf'),'-dpdf','-r300')


% cq_county_min_max = unique(coalqual_samples.fips_code);
% cq_county_min_max(1,:) = []; % remove first row, which is fips code = 0; 
% for i = 1:size(cq_county_min_max,1)
%     cq_county_min_max(i,2) = max(coalqual_samples.Hg(coalqual_samples.fips_code == cq_county_min_max(i,1))) - ...
%         min(coalqual_samples.Hg(coalqual_samples.fips_code == cq_county_min_max(i,1)));
%     cq_county_min_max(i,3) = max(coalqual_samples.Se(coalqual_samples.fips_code == cq_county_min_max(i,1))) - ...
%         min(coalqual_samples.Se(coalqual_samples.fips_code == cq_county_min_max(i,1)));
%     cq_county_min_max(i,4) = max(coalqual_samples.As(coalqual_samples.fips_code == cq_county_min_max(i,1))) - ...
%         min(coalqual_samples.As(coalqual_samples.fips_code == cq_county_min_max(i,1)));
%     cq_county_min_max(i,5) = max(coalqual_samples.Cl(coalqual_samples.fips_code == cq_county_min_max(i,1))) - ...
%         min(coalqual_samples.Cl(coalqual_samples.fips_code == cq_county_min_max(i,1)));
% end 
% 
% %% plot as cdf
% 
% close all;
% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.18 0.2 0.75 0.75]) % x pos, y pos, x width, y height
% 
% % divide_array = [0.6 15 40 2100]; % defined based on the max_trace, but it's an arbitrary rule, so there's no way to automate this process
% % scale = max(divide_array); 
% color = {'r','k','b','g'}; 
% hold on;
% 
% for k = 4%:4
% %     subplot(2,2,k);
% 
%     plotx = sort(cq_county_min_max(:,k+1)); 
%     plotx(isnan(plotx)) = []; 
%     ploty = linspace(0,1,size(plotx,1));
%     
%     if k == 1
%         h = plot(plotx,ploty,'--');
%     elseif k == 2
%         h = plot(plotx,ploty,'-.');
%     elseif k == 3
%         h = plot(plotx,ploty,':');
%     elseif k == 4
%         h = plot(plotx,ploty,'-');
%     end 
%     set(h,'LineWidth',1.8,'Color',color{k});
% 
% end
% ylabel('F(x)'); 
% xlabel({'Difference of max and min', 'concentration at each county (ppm)'}); 
% set(gca,'FontName','Arial','FontSize',13)
% a=gca;
% set(a,'box','off','color','none')
% % ylim([0 1]);
% % axis([0 scale 0 1]);
% axis([0 4000 0 1]);
% b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
% axes(a)
% linkaxes([a b])
% % a.XTick = linspace(0, 2100, 5); 
% % a.XTickLabel = {'1','2','3','4'};
% % legend(['Difference between' char(10) 'bootstrap and MATS ICR'],'MATS ICR');
% legendcells = {'Mercury','Selenium','Arsenic','Chlorine'};
% legend(legendcells(k),'Location','SouthEast');
% legend boxoff;
% 
% % histogram();
% 
% %% 
% cq_county_med = unique(coalqual_samples.fips_code);
% cq_county_med(1,:) = []; % remove first row, which is fips code = 0; 
% for i = 1:size(cq_county_med,1)
%     cq_county_med(i,2) = median(coalqual_samples.Hg(coalqual_samples.fips_code == cq_county_med(i,1)));
%     cq_county_med(i,3) = median(coalqual_samples.Se(coalqual_samples.fips_code == cq_county_med(i,1)));
%     cq_county_med(i,4) = median(coalqual_samples.As(coalqual_samples.fips_code == cq_county_med(i,1)));
%     cq_county_med(i,5) = median(coalqual_samples.Cl(coalqual_samples.fips_code == cq_county_med(i,1)));
% end 
% %%
% close all;
% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.18 0.18 0.75 0.75]) % x pos, y pos, x width, y height
% 
% % divide_array = [0.6 15 40 2100]; % defined based on the max_trace, but it's an arbitrary rule, so there's no way to automate this process
% % scale = max(divide_array); 
% color = {'r','k','b','g'}; 
% hold on;
% 
% for k = 4%:4
% %     subplot(2,2,k);
% 
%     plotx = sort(cq_county_med(:,k+1)); 
%     plotx(isnan(plotx)) = []; 
%     ploty = linspace(0,1,size(plotx,1));
%     
%     if k == 1
%         h = plot(plotx,ploty,'--');
%     elseif k == 2
%         h = plot(plotx,ploty,'-.');
%     elseif k == 3
%         h = plot(plotx,ploty,':');
%     elseif k == 4
%         h = plot(plotx,ploty,'-');
%     end 
%     set(h,'LineWidth',1.8,'Color',color{k});
% 
% end
% ylabel('F(x)'); 
% xlabel('Median concentration by county (ppm)'); 
% set(gca,'FontName','Arial','FontSize',13)
% a=gca;
% set(a,'box','off','color','none')
% % ylim([0 1]);
% % axis([0 scale 0 1]);
% b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
% axes(a)
% linkaxes([a b])
% % a.XTick = linspace(0, 2100, 5); 
% % a.XTickLabel = {'1','2','3','4'};
% % legend(['Difference between' char(10) 'bootstrap and MATS ICR'],'MATS ICR');
% legendcells = {'Mercury','Selenium','Arsenic','Chlorine'};
% legend(legendcells(k),'Location','SouthEast');
% legend boxoff;

% plant_top_county_purch = zeros(size(unique(coal_purchases_2010.Plant_Id),1), 14);
% plant_top_county_purch(:,1) = unique(coal_purchases_2010.Plant_Id); 
% for i = 1:size(plant_top_county_purch,1)
%     purchases_by_plant = coal_purchases_2010(coal_purchases_2010.Plant_Id == plant_top_county_purch(i,1),:); 
%     county_purch_at_plant = unique(purchases_by_plant.county); 
%     for j = 1:size(county_purch_at_plant,1)
%         county_purch_at_plant(j,2) = sum(purchases_by_plant.QUANTITY(purchases_by_plant.county == county_purch_at_plant(j)));
%     end 
%     plant_top_county_purch(i,2) = county_purch_at_plant(max(county_purch_at_plant(:,2)) == county_purch_at_plant(:,2),1); 
% end 
% 
% % for each plant, at each month, calculate fraction of coal from county
% % with most purchases divided by total purchases that month
% for i = 1:size(plant_top_county_purch,1)
%     purchases_by_plant = coal_purchases_2010(coal_purchases_2010.Plant_Id == plant_top_county_purch(i,1),:); 
%     for j = 1:12
%         purchases_month_by_plant = purchases_by_plant(purchases_by_plant.MONTH == j,:);
%         plant_top_county_purch(i,j+2) = sum(purchases_month_by_plant.QUANTITY(...
%             purchases_month_by_plant.county == plant_top_county_purch(i,2)),'omitnan')/...
%             sum(purchases_month_by_plant.QUANTITY,'omitnan'); 
%     end 
% end 
% 
% % keep power plants that are modeled in manuscript, merge generation 
% plant_top_county_purch = array2table(plant_top_county_purch); 
% plant_top_county_purch.Properties.VariableNames(1) = {'Plant_Code'}; 
% plant_top_county_purch = innerjoin(plant_top_county_purch, unique(plant_gen));
% plant_top_county_purch = table2array(sortrows(plant_top_county_purch,'Gen_MWh','descend'));
% 
% plant_top_county_purch(:,end+1) = 0;
% for i = 1:size(plant_top_county_purch,1)
%     plant_top_county_purch(i,end) = max(plant_top_county_purch(i,3:14)) - min(plant_top_county_purch(i,3:14));
% end 
% %% plot results for the first five plants 
% close all;
% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.2 0.18 0.75 0.75]) % x pos, y pos, x width, y height
% k = 1;
% % figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
% % axes('Position',[0.2 0.15 0.75 0.75]) % x pos, y pos, x width, y height
% % for k = 1:4 
% %     subplot(2,2,k);
% %     color = {'r','k','b','g'}; 
% %     hold on; 
% %     if k == 1
% %         set(gca, 'Position', [0.15 0.6 0.3 0.33])
% %     elseif k == 2
% %         set(gca, 'Position', [0.6 0.6 0.3 0.33])
% %     elseif k == 3
% %         set(gca, 'Position', [0.15 0.15 0.3 0.33])
% %     elseif k == 4
% %         set(gca, 'Position', [0.6 0.15 0.3 0.33])
% %     end 
% 
%     idx = (5*(k-1)+1):5*k;
%     
%     plot(1:12, plant_top_county_purch(idx, 3:14),'*--');
% 
%     xlabel('Months');
%     ylabel({'Fraction of coal purchase by','county that supplies the most coal'}); 
%     
%     set(gca,'FontName','Arial','FontSize',13)
%     a=gca;
%     set(a,'box','off','color','none')
%     b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
%     axes(a)
%     linkaxes([a b])
%     axis([1 12 0 1]);
%     a.XTick = 1:3:12; 
%     a.XTickLabel = {'Jan','April','Jul','Oct'};
%     legend(cellstr(num2str(plant_top_county_purch(idx,1), '%-d')));
%     legend boxoff;
% 
% % end 
% sum(plant_top_county_purch(1:20,15))/ann_coal_gen
% 
% %% plot difference between min and max of each plant 
% histogram(plant_top_county_purch(:,end),'BinWidth',0.1);
%     

