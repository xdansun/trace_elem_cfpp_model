% 03/14/2017
% this script is designed to look at coal purchases from EIA 923 - Schedule
% 5: Fuel Receipts to exminae the percentage of the fleet that has
% undergone coal preparation 

clear; clc; 
warning('off'); 
%% read in 2015 coal purchases data
[num,txt,raw] = xlsread('EIA_923_2015/EIA923_Schedules_2_3_4_5_M_12_2015_Final.xlsx',...
    'Page 5 Fuel Receipts and Costs');
column_numbers = [3:5 8:12 16:20]; % identify columns of interest 
row_start = 5; % identify row number in which spreadsheet starts; index is the row of the header
all_purchases_2015 = table_scrub(raw, column_numbers, row_start); % create table from raw data 

%% calculate fraction of all coal purchases from preparation plants 
coal_purchases_2015 = all_purchases_2015(strcmp(all_purchases_2015.FUEL_GROUP,'Coal'),:); % coal purchases only 
total_amt = sum(coal_purchases_2015.QUANTITY); % total amount of coal purchased 

prep_purchases_2015 = coal_purchases_2015(strcmp(coal_purchases_2015.Coalmine_Type,'P'),:); 
total_prep = sum(prep_purchases_2015.QUANTITY); 
total_prep/total_amt; % 0.0566 only about 6% of coal purchased is from a coal preparation plant 

%% read in 2014 coal purchase data 
[num,txt,raw] = xlsread('EIA_923_2014/EIA923_Schedules_2_3_4_5_M_12_2014_Final_Revision.xlsx',...
    'Page 5 Fuel Receipts and Costs');
column_numbers = [3:5 8:12 16:20]; % identify columns of interest 
row_start = 5; % identify row number in which spreadsheet starts; index is the row of the header
all_purchases_2014 = table_scrub(raw, column_numbers, row_start); % create table from raw data 
coal_purchases_2014 = all_purchases_2014(strcmp(all_purchases_2014.FUEL_GROUP,'Coal'),:); % coal purchases only 

%% calculate fraction of all coal purchases from preparation plants 
total_amt(2) = sum(coal_purchases_2014.QUANTITY); % total amount of coal purchased 
total_prep(2) = sum(coal_purchases_2014.QUANTITY(strcmp(coal_purchases_2014.Coalmine_Type,'P'),:)); 
total_prep./total_amt % 0.0537 only about 5% of coal purchased is from a coal preparation plant 

%% read in 2013 coal purchase data 
[num,txt,raw] = xlsread('EIA_923_2013/EIA923_Schedules_2_3_4_5_2013_Final_Revision.xlsx',...
    'Page 5 Fuel Receipts and Costs');
column_numbers = [3:5 8:12 16:20]; % identify columns of interest 
row_start = 5; % identify row number in which spreadsheet starts; index is the row of the header
all_purchases_2013 = table_scrub(raw, column_numbers, row_start); % create table from raw data 
coal_purchases_2013 = all_purchases_2013(strcmp(all_purchases_2013.FUEL_GROUP,'Coal'),:); % coal purchases only 

%% calculate fraction of all coal purchases from preparation plants 
total_amt(3) = sum(coal_purchases_2013.QUANTITY); % total amount of coal purchased 
total_prep(3) = sum(coal_purchases_2013.QUANTITY(strcmp(coal_purchases_2013.COALMINE_TYPE,'P'),:)); 
total_prep./total_amt % 0.0533 only about 5% of coal purchased is from a coal preparation plant 

%% read in 2012 coal purchase data 
[num,txt,raw] = xlsread('EIA_923_2012/EIA923_Schedules_2_3_4_5_2012_Final_Release_12.04.2013.xlsx',...
    'Page 5 Fuel Receipts and Costs');
column_numbers = [3:5 8:12 16:20]; % identify columns of interest 
row_start = 5; % identify row number in which spreadsheet starts; index is the row of the header
all_purchases_2012 = table_scrub(raw, column_numbers, row_start); % create table from raw data 
coal_purchases_2012 = all_purchases_2012(strcmp(all_purchases_2012.FUEL_GROUP,'Coal'),:); % coal purchases only 

%% calculate fraction of all coal purchases from preparation plants 
total_amt(4) = sum(coal_purchases_2012.QUANTITY); % total amount of coal purchased 
total_prep(4) = sum(coal_purchases_2012.QUANTITY(strcmp(coal_purchases_2012.COALMINE_TYPE,'P'),:)); 
total_prep./total_amt % 

%% read in 2011 coal purchase data 
[num,txt,raw] = xlsread('EIA_923_2011/EIA923_Schedules_2_3_4_5_2011_Final_Revision.xlsx',...
    'Page 5 Fuel Receipts and Costs');
column_numbers = [3:5 8:12 16:20]; % identify columns of interest 
row_start = 5; % identify row number in which spreadsheet starts; index is the row of the header
all_purchases_2011 = table_scrub(raw, column_numbers, row_start); % create table from raw data 
coal_purchases_2011 = all_purchases_2011(strcmp(all_purchases_2011.FUEL_GROUP,'Coal'),:); % coal purchases only 

%% calculate fraction of all coal purchases from preparation plants 
total_amt(5) = sum(coal_purchases_2011.QUANTITY); % total amount of coal purchased 
total_prep(5) = sum(coal_purchases_2011.QUANTITY(strcmp(coal_purchases_2011.COALMINE_TYPE,'P'),:)); 
total_prep./total_amt % 0.0566 only about 6% of coal purchased is from a coal preparation plant 

%% read in 2010 coal purchase data 
[num,txt,raw] = xlsread('EIA_923_2010/EIA923 SCHEDULES 2_3_4_5 Final 2010_edited.xlsx',...
    'Page 5 Fuel Receipts and Cost');
column_numbers = [3:5 8:12 16:20]; % identify columns of interest 
row_start = 8; % identify row number in which spreadsheet starts; index is the row of the header
all_purchases_2010 = table_scrub(raw, column_numbers, row_start); % create table from raw data 
coal_purchases_2010 = all_purchases_2010(strcmp(all_purchases_2010.Fuel_Group,'Coal'),:); % coal purchases only 

%% calculate fraction of all coal purchases from preparation plants 
total_amt(6) = sum(coal_purchases_2010.Quantity); % total amount of coal purchased 
total_prep(6) = sum(coal_purchases_2010.Quantity(strcmp(coal_purchases_2010.CoalMine_Type,'P'),:)); 
total_prep./total_amt % 0.0566 only about 6% of coal purchased is from a coal preparation plant 

%% read in 2009 coal purchase data 
[num,txt,raw] = xlsread('EIA_923_2009/EIA923 SCHEDULES 2_3_4_5 M Final 2009_edited.xlsx',...
    'Page 5 Fuel Receipts and Cost');
column_numbers = [3:5 8:12 16:20]; % identify columns of interest 
row_start = 7; % identify row number in which spreadsheet starts; index is the row of the header
all_purchases_2009 = table_scrub(raw, column_numbers, row_start); % create table from raw data 
coal_purchases_2009 = all_purchases_2009(strcmp(all_purchases_2009.Fuel_Group,'Coal'),:); % coal purchases only 

%% calculate fraction of all coal purchases from preparation plants 
total_amt(7) = sum(coal_purchases_2009.Quantity); % total amount of coal purchased 
total_prep(7) = sum(coal_purchases_2009.Quantity(strcmp(coal_purchases_2009.CoalMine_Type,'P'),:)); 
total_prep./total_amt % 0.0566 only about 6% of coal purchased is from a coal preparation plant 

% note that in 2008, none of the plants are reported to be sourced from a
% preparation plant, and prior to 2008, none of the data is reported at all

%% plot the coal prep results 
close all; 
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.20 0.20 0.75 0.75]) % x pos, y pos, x width, y height

% plot(2015:-1:2009, total_prep./total_amt,'k.','MarkerSize',28)
bar(2015:-1:2009, total_prep./total_amt,'k','BarWidth',0.5); 
% bar(total_prep./total_amt,'k'); 

set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
 
% xlim([2008 2016]);
% ylim([0 0.1]); 
axis([2008.5 2015.5 0 0.08]); 
xlabel('Year'); 
ylabel('Fraction of coal purchased\newline that is prepared');


print('../../Figures/Fig_coal_prep','-dpdf','-r300') % save figure (optional)

%% analyze at the plant level how much coal is cleaned 
coal_prep_at_plant_level = unique(coal_purchases_2015.Plant_Id);
coal_prep_at_plant_level(:,2) = 0; 
coal_prep_at_plant_level(:,3) = 0; 
for i = 1:size(coal_prep_at_plant_level,1)
    if sum(prep_purchases_2015.Plant_Id == coal_prep_at_plant_level(i,1)) > 0
        coal_prep_at_plant_level(i,2) = sum(prep_purchases_2015.QUANTITY(prep_purchases_2015.Plant_Id == coal_prep_at_plant_level(i,1)));  
    end 
    coal_prep_at_plant_level(i,3) = sum(coal_purchases_2015.QUANTITY(coal_purchases_2015.Plant_Id == coal_prep_at_plant_level(i,1)));  
end 

coal_prep_at_plant_level(:,4) = coal_prep_at_plant_level(:,2)./coal_prep_at_plant_level(:,3); % calculate fraction of coal purchases that is prepared 
coal_prep_at_plant_level = array2table(coal_prep_at_plant_level); % convert to table 
coal_prep_at_plant_level.Properties.VariableNames = {'Plant_Code','coal_prep','total_coal_purch','frac_prep'}; 

%% calculate plant level generation in 2015 and pair with plant level data 
% read in 2015 generation data
[num,txt,raw] = xlsread('EIA_923_2015/EIA923_Schedules_2_3_4_5_M_12_2015_Final.xlsx',...
    'Page 4 Generator Data');
column_numbers = [1 16 96]; % identify columns of interest 
row_start = 6; % identify row number in which spreadsheet starts; index is the row of the header
plant_generation = table_scrub(raw, column_numbers, row_start); % create table from raw data 

%% calculate generation of cfpps at the plant level 
coal_generation_raw = plant_generation(strcmp(plant_generation.AER_Fuel_Type_Code, 'COL'),:); 
coal_generation = unique(coal_generation_raw.Plant_Id); % some plants are listed twice (likely because SUB and BIT are listed separately) 
coal_generation(:,2) = 0; 
for i = 1:size(coal_generation,1)
    coal_generation(i,2) = sum(coal_generation_raw.Net_Generation_Megawatthours(coal_generation_raw.Plant_Id == plant_list(i))); 
end 
coal_generation = array2table(coal_generation); 
coal_generation.Properties.VariableNames = {'Plant_Code','Gen_MWh'}; 

%% merge generation data with coal prep data 
coal_prep_plant_level_gen = innerjoin(coal_prep_at_plant_level, coal_generation); 

%% add up total generation that participates in coal prep 
gen_prep = sum(coal_prep_plant_level_gen.Gen_MWh(coal_prep_plant_level_gen.frac_prep > 0));
gen_total = sum(coal_prep_plant_level_gen.Gen_MWh); 
gen_prep/gen_total

%% save all output data 
save('coal_prep_data.mat'); 



