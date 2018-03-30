%% description:
% perform cluster analysis for states in COALQUAL without Cl concentration
% data 

%% overhead
% clear; clc; close all; 

%% input raw upper level COALQUAL data and remove most columns to simplify the analysis 
[num,txt,raw] = xlsread('CQ_upper_level.xlsx.'); 

upper_level = cell2table(raw(2:end,:));
upper_level.Properties.VariableNames = raw(1,:); 

% input upper level COALQUAL data with FIPS codes 
[num,txt,raw] = xlsread('coalqual_upper_wfips.xlsx'); 

coal_table_wfips = cell2table(raw(2:end,:));
coal_table_wfips.Properties.VariableNames = raw(1,:); 

% combine province and region data to the coal_table_wfips
coal_table_fips_region = innerjoin(coal_table_wfips, upper_level(:,[1 6 7])); 

%% from analysis in the mass_bal_main_script, 

% https://www.census.gov/geo/reference/ansi_statetables.html
% 4 is AZ - Rocky mountain province
% 17 is IL - Eastern Interior
% 18 is IN - Eastern interior
% 29 is MO - Western interior
% 47 is TN - multiple basins
% glossary of provinces: https://pubs.usgs.gov/circ/c891/glossary.htm
% map of reserves: https://pubs.usgs.gov/circ/c891/figures/figure7.htm
% however, these reserves apparently means whether or not there are
% economically extractable coal there... it's not clear if they have any
% special geographical distinctions 
% another resource if needed: https://igws.indiana.edu/Coal/Mercury.cfm


%% perform cluster analysis 
% Arizona is part of the Colorado Plateau, which includes Arizona, Utah,
% Colorado, and New Mexico 
az = coal_table_fips_region(strcmp(coal_table_fips_region.Province, 'ROCKY MOUNTAIN') == 1 & ...
    (strcmp(coal_table_fips_region.State, 'Arizona') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Utah') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Colorado') == 1 | ...
    strcmp(coal_table_fips_region.State, 'New Mexico') == 1), :); 
az = az(isnan(az.Cl) == 0,:); 
az_cl = nan(1500,3); 
rank = {'LIGNITE','SUBBITUMINOUS','BITUMINOUS'}; 
for i = 1:3
    foo = az.Cl(strcmp(az.EstimatedRank, rank{i})); 
    az_cl(1:size(foo,1),i) = foo; 
end

% Illinois and Indiana are both part of the
% Illinois Basin, which includes Illinois, Indiana, and Kentucky 

% eastern interior only has bituminous coal, which is fine, because coal
% plants in model dataset only purchase bituminous coal from this region 
il = coal_table_fips_region(strcmp(coal_table_fips_region.Province, 'INTERIOR') == 1 & ...
    strcmp(coal_table_fips_region.Region, 'EASTERN') == 1 & ...
    (strcmp(coal_table_fips_region.State, 'Illinois') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Indiana') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Kentucky') == 1), :);
il = il(isnan(il.Cl) == 0,:); 
il_cl = nan(1500,3); 
rank = {'LIGNITE','SUBBITUMINOUS','BITUMINOUS'}; 
for i = 1:3
    foo = il.Cl(strcmp(il.EstimatedRank, rank{i})); 
    il_cl(1:size(foo,1),i) = foo; 
end

% Missouri is part of the Western Interior, which includes Iowa, Nebraska,
% Kansas, Missouri, Oklahoma, and Arkansas 

% western interior only has bituminous coal, which is fine, because coal
% plants in model dataset only purchase bituminous coal from this region
mo = coal_table_fips_region(strcmp(coal_table_fips_region.Province, 'INTERIOR') == 1 & ...
    strcmp(coal_table_fips_region.Region, 'WESTERN') == 1 & ...
    (strcmp(coal_table_fips_region.State, 'Iowa') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Nebraska') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Kansas') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Missouri') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Oklahoma') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Arkansas') == 1), :);
mo = mo(isnan(mo.Cl) == 0,:); 
mo_cl = nan(1500,3); 
rank = {'LIGNITE','SUBBITUMINOUS','BITUMINOUS'}; 
for i = 1:3
    foo = mo.Cl(strcmp(mo.EstimatedRank, rank{i})); 
    mo_cl(1:size(foo,1),i) = foo; 
end

% Tennessee appears to be part of the Appalachian Basin and Gulf Coast.
% After reviewing EIA coal purchases, I find that plants purchase coal from
% only one county in Tennessee, Claiborne county, located on the
% northeastern edge of the state. Therefore, it’s part of the Appalachian
% Basin, which includes Tennessee, Kentucky, West Virginia, Virginia,
% Maryland, Ohio, and Pennsylvania.

% only bituminous coal present, which is fine because coal plants in model
% dataset only purchase bituminous coal from this region 
tn = coal_table_fips_region(strcmp(coal_table_fips_region.Province, 'EASTERN') == 1 & ...
    strcmp(coal_table_fips_region.Region, 'CENTRAL APPALACHIAN') == 1 & ...
    (strcmp(coal_table_fips_region.State, 'Kentucky') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Tennessee') == 1 | ...
    strcmp(coal_table_fips_region.State, 'Virginia') == 1 | ...
    strcmp(coal_table_fips_region.State, 'West Virginia') == 1),:); 

tn = tn(isnan(tn.Cl) == 0,:); 
tn_cl = nan(1500,3); 
rank = {'LIGNITE','SUBBITUMINOUS','BITUMINOUS'}; 
for i = 1:3 
    foo = tn.Cl(strcmp(tn.EstimatedRank, rank{i})); 
    tn_cl(1:size(foo,1),i) = foo; 
end

%% plot results 
te_cl = horzcat(az_cl, il_cl(:,3), mo_cl(:,3), tn_cl(:,3)); % concatenate concentrations 

close all; 
figure('Color','w','Units','inches','Position',[0.25 0.25 8 5]) % was 1.25
axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height

boxplot(te_cl);

ylim([0 3e3]); 

set(gca,'FontName','Arial','FontSize',14)
a=gca;

a.XTickLabel = {'CO Plateau-Lig (9)','CO Plateau-Sub (112)','CO Plateau-Bit (213)',...
    'Illinois Basin-Bit (139)','West Interior-Bit (24)','Central Applachian-Bit (1117)'}; 
a.XTickLabelRotation = 30;
ylabel(['[Cl] in COALQUAL' char(10) 'coal samples (ppm)']);


set(a,'box','off','color','none')
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

grid off;
title('');

%% of plants that purchase coal from these states 

% The figure Meagan was suggesting, which is the one that makes sense is to
% include in the x-axis your COALQUAL concentrations (for the COAL not for
% the PLANT), and on the y-axis your estimate of what that concentration is
% when you instead use the average EIA basin data for that coal type.

% plot_data = nan(1e4,2); 
% idx = 1; 
% for i = 1:size(te_cl,2)
%     avg = mean(te_cl(:,i),'omitnan');
%     for j = 1:size(te_cl,1)
%         ppm = te_cl(j,i); 
%         if isnan(ppm) == 1
%             break; 
%         else 
%             plot_data(idx,1) = ppm;
%             plot_data(idx,2) = avg; 
%             idx = idx+1; 
%         end 
%         
%     end 
% 
% end 

close all; 
figure('Color','w','Units','inches','Position',[0.25 0.25 5 5]) % was 1.25
axes('Position',[0.2 0.2 0.65 0.6]) % x pos, y pos, x width, y height

% plot(plot_data(:,1), plot_data(:,2),'*')
hold on;
style = {'c*','r*','k*','m*','g*','b*'};
for i = 1:6
    plot(te_cl(:,i),mean(te_cl(:,i),'omitnan')*ones(size(te_cl,1),1),style{i})
end 

axis([0 2e3 0 2e3]);


set(gca,'FontName','Arial','FontSize',14)
a=gca;

% a.XTickLabel = {'CO Plateau-Lig (9)','CO Plateau-Sub (112)','CO Plateau-Bit (213)',...
%     'East Interior-Bit (139)','West Interior-Bit (24)','Applachian Basin-Bit (1117)'}; 
% a.XTickLabelRotation = 30;
xlabel('[Cl] of coal sample (ppm)');
ylabel('Mean [Cl] at basin level (ppm)');


set(a,'box','off','color','none')
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
legend({'CO Plateau-Lig (9)','CO Plateau-Sub (112)','CO Plateau-Bit (213)',...
    'Illinois Basin-Bit (139)','West Interior-Bit (24)','Central Applachian-Bit (1117)'})
legend boxoff;

grid off;
title('');














