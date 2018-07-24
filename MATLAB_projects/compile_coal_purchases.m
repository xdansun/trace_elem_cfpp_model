function [coal_generator_boiler_table, coal_purchase_nowc_domestic] = ...
    compile_coal_purchases(coal_gen_boilers, ann_coal_gen, num_coal_plants, year)
% This script removes plants from coal_gen_boiler_wcutoff if they:
% use foreign fuels
% do not have reported coal purchases 
% use waste coal (WC) as a fuel source
% We then calculate the % generation of the fleet that we lose from
% removing those fuel sources. We must remove those fuel sources because we
% cannot approximate their trace element content if they were included. 
% There are two things we keep track of:
% 1. the main cfpp generator-boiler table which contains one-to-one mapping
% of the generator to the boiler
% 2. a list of all coal purchases made by the cfpps in the main cfpp
% generator-boiler table. Note that these are plants:fuel tables 
% This function then appends fips state and county codes to the coal
% purhcase table 
% 
% inputs:
% coal_gen_boiler_wcutoff - the main coal generator boiler link 
% ann_coal_gen - the annual generation from the entire coal fleet 
%
% outputs:
% coal_generator_boiler_table - a table containing cfpps at the generator
% level linked one-to-one with the boiler after imposing a capacity cutoff,
% removing plants without coal purchases, waste coal (wc) purchases, and
% foreign coal purchases 
% coal_purchase_nowc_domestic - a table of coal purchases that excludes
% waste coal purchases and foreign coal purchases. This table includes fips
% state and county codes. They link the plant to the fuel 

% turn off warnings (this decreases the run time by about a minute)
% total run time is about 4 minutes 
warning('off','all');
%% read in spreadsheet to determine plant blend information 
if year == 2015 
    [num,txt,raw] = xlsread('../data/EIA_923/EIA923_Schedules_2_3_4_5_M_12_2015_Final.xlsx',...
        'Page 5 Fuel Receipts and Costs');
    column_rows = [1:4 8:14 16:20]; % identify columns of interest (performed numerically)
    row_start = 5; % identify row number in which spreadsheet starts; index is the row of the header
    % create a table of all plants with fuel consumption and electricity generation  
    all_fuels = table_scrub(raw, column_rows, row_start); % create table from raw data
elseif year == 2016 
    [num,txt,raw] = xlsread('../data/eia9232016/EIA923_Schedules_2_3_4_5_M_12_2016_Final_Revision.xlsx',...
        'Page 5 Fuel Receipts and Costs');
    column_rows = [1:4 8:14 16:20]; % identify columns of interest (performed numerically)
    row_start = 5; % identify row number in which spreadsheet starts; index is the row of the header
    % create a table of all plants with fuel consumption and electricity generation  
    all_fuels = table_scrub(raw, column_rows, row_start); % create table from raw data
elseif year == 2010
    [num,txt,raw] = xlsread('../data/eia9232010/EIA923 SCHEDULES 2_3_4_5 Final 2010_edited.xlsx',...
    'Page 5 Fuel Receipts and Cost');
    column_rows = [1:4 8:14 16:20]; % identify columns of interest (performed numerically)
    row_start = 9; % identify row number in which spreadsheet starts; index is the row of the header
    % create a table of all plants with fuel consumption and electricity generation  
    all_fuels = table_scrub(raw, column_rows, row_start); % create table from raw data
else
    error('incorrect year, choose 2010 or 2015'); 
end 
%% find all power plants with international sources of fuel 
temp_fuels = table2cell(all_fuels(:,'FUEL_GROUP')); % create a dummy list of fuels for searching and indexing 
coal_fuels = all_fuels(find(strcmp('Coal',temp_fuels)),:); % select only coal purchases from all_fuels
state_fuels = table2cell(coal_fuels(:,'Coalmine_State')); % pull state information 
% create a list of coal sources that are foreign countries according to EIA
foreign_countries = {'AU','CL','CN','IS','PL','RS','UK','VZ','OC',''}; 
% create a list of all the plants with coal fuel 
plant_foreign_fuel = table2array(unique(coal_fuels(:,'Plant_Id'))); 
% add a column of zeros that will be the flag for international 
plant_foreign_fuel(:,end+1) = 0;  
for i = 1:size(coal_fuels,1) % for each coal fuel, flag any instance of foreign fuel 
    temp_plant = coal_fuels{i,'Plant_Id'}; 
    % if there is a fuel located internationally
    if sum(strcmp(state_fuels{i,1},foreign_countries)) > 0
        plant_foreign_fuel(plant_foreign_fuel == temp_plant,end) = 1; % mark the plant for having a foreign fuel 
    end 
end 
% reduce the plant markers to only plants marked with international fuel 
plant_foreign_fuel = plant_foreign_fuel(plant_foreign_fuel(:,2) == 1, 1);

clear temp_plant temp_fuels

% remove all power plants with international sources of fuel (note that
% there are 17 of these plants) and each instance of their purchase 
temp_cfpp_list = table2array(coal_fuels(:,'Plant_Id')); % plants with coal fuels 
temp_cfpp_list(:,end+1) = 0; % add a column 
for i = 1:size(plant_foreign_fuel,1) % for each power plant with international purchase 
    temp_cfpp_list(temp_cfpp_list(:,1)==plant_foreign_fuel(i),2) = 1; % mark the cfpp with foreign fuel 
end 
% create a table of all domestic coal purchases 
domestic_fuels = coal_fuels(temp_cfpp_list(:,2)==0,:);

%% remove all cfpps with foreign coals from the main coal_generator list 
% create a temporary list of coal plants from the main coal_generator list 
temp_cfpp_list = table2array(coal_gen_boilers(:,'Plant_Code')); 
temp_cfpp_list(:,end+1) = 0; % add a column for flag for international fuel 
for i = 1:size(plant_foreign_fuel,1) % for all plants with foreign fuels 
    temp_cfpp_list(temp_cfpp_list(:,1)==plant_foreign_fuel(i),2) = 1; % flag all coal plants 
end
coal_gen_boil_wcut_domestic = coal_gen_boilers(temp_cfpp_list(:,2)==0,:); % remove international fuel sources 

%% calculate generation missing from removing plants with international sources of coal 
% by comparing the sum of the generation of the new coal-generator-boiler
% table by the original coal generation from the entire fleet
plants_domestic = size(unique(coal_gen_boil_wcut_domestic.Plant_Code),1);
ann_domest_gen = sum(table2array(...
    coal_gen_boil_wcut_domestic(:,'Net_Generation_Year_To_Date'))); 
fprintf('total percent generation lost after international fuels cutoff: %3.2f %3.2f \n',...
    (num_coal_plants - plants_domestic)/num_coal_plants*100, ...   
    (ann_coal_gen-ann_domest_gen)/ann_coal_gen*100); 


%% remove all plants that do not have recorded coal purchases 
% create a temporary list of coal plants from the new coal_generator list 
temp_cfpp_list = table2array(coal_gen_boil_wcut_domestic(:,'Plant_Code')); 
temp_cfpp_list(:,end+1) = 0; % add a column for flag for coal purchases
% unique list of power plants from the domestic fuel purchases
plant_domestic_fuels = table2array(unique(domestic_fuels(:,'Plant_Id'))); 
% plant_domestic_fuels(:,end+1) = 0; 
for i = 1:size(plant_domestic_fuels,1) % for each cfpp with a coal purchase
    % flag all plants that appear in both the coal purchase and the main
    % coal generator-boiler list. These are the cfpps we can analyze which
    % have reported coal purchases 
    temp_cfpp_list(temp_cfpp_list(:,1)==plant_domestic_fuels(i),2) = 1; 
end 
% create a new table for coal-generator-boiler-wcutoff-wdomesticfuels 
coal_gen_boil_wfuels = coal_gen_boil_wcut_domestic(temp_cfpp_list(:,2)==1,:);

%% calculate generation and plants missing from throwing out plants without coal purchases
% and foreign fuels by comparing the generation of the new
% coal-generator-boiler table by the original coal generation from the
% entire fleet 
plants_no_fuels_gen = size(unique(coal_gen_boil_wfuels.Plant_Code),1); 
ann_no_fuels_gen = sum(table2array(...
    coal_gen_boil_wfuels(:,'Net_Generation_Year_To_Date'))); 

fprintf('total percent plants and generation lost after \nfuel purchase limitation: %3.2f %3.2f\n',...
    (num_coal_plants - plants_no_fuels_gen)/num_coal_plants*100, ...
    (ann_coal_gen-ann_no_fuels_gen)/ann_coal_gen*100); 

%% find all plants that use WC as a fuel source
% pull all coal purchases with energy sources 
temp_fuels = table2cell(domestic_fuels(:,'ENERGY_SOURCE'));
% find all purchases from domestic fuels for WC 
wc_fuels = domestic_fuels(find(strcmp('WC',temp_fuels)),:);
plant_wc_fuel = table2array(unique(wc_fuels(:,'Plant_Id'))); % create a list of all the plants with WC

%% create a new list of coal purchases that does not include WC
% create a dummy list of plants from the coal purchases
temp_cfpp_purchases = table2array(domestic_fuels(:,'Plant_Id')); 
temp_cfpp_purchases(:,end+1) = 0; % add a column to flag for wc 
for i = 1:size(plant_wc_fuel,1) % for each power plant with WC purchase
    temp_cfpp_purchases(temp_cfpp_purchases(:,1)==plant_wc_fuel(i),2) = 1; % flag the plant with WC purchase
end 
% create a table of coal purchases that are domestic and exclude wc 
coal_purchase_nowc_domestic = domestic_fuels(temp_cfpp_purchases(:,2)==0,:);

%% create a new list of cfpps without wc purchases 
% create a dummy list of cfpps from main coal-generator-boiler table 
temp_cfpp_list = table2array(coal_gen_boil_wfuels(:,'Plant_Code')); 
temp_cfpp_list(:,end+1) = 0; % add a column to flag for plants which burn wc 
for i = 1:size(plant_wc_fuel,1) % for each power plant with WC purchase
    temp_cfpp_list(temp_cfpp_list(:,1)==plant_wc_fuel(i),2) = 1; % flag the plant 
end 
% create a new coal-generator-boiler-wfuels-domestic-nowc-table
coal_generator_boiler_table = coal_gen_boil_wfuels(temp_cfpp_list(:,2)==0,:); 

%% calculate generation lost from removing plants with wc purchases
% compare the generation of the new coal-generator-boiler table by the
% original coal generation from the entire fleet
plants_no_wc_gen = size(unique(coal_generator_boiler_table.Plant_Code),1); 
ann_no_wc_gen = sum(table2array(...
    coal_generator_boiler_table(:,'Net_Generation_Year_To_Date'))); 
fprintf('total percent plants and generation lost after WC cutoff: %3.2f %3.2f\n',...
    (num_coal_plants - plants_no_wc_gen)/num_coal_plants*100,...
    (ann_coal_gen-ann_no_wc_gen)/ann_coal_gen*100); 

%% link up coal purchases with county and state fips codes 
% this is necessary to match up coalqual data by county 

% first, 

% open up list of states, counties, and their fips code 
fileID = fopen('../data/Misc_Data/national_county.txt'); 
temp = textscan(fileID,'%s%d%d%s%s','Delimiter',','); 

fclose(fileID); % close the file just in case

state_name = temp{1}; % state abbreviations in the first column
fips_state = temp{2}; % state fips number in the second column 

fips_state = horzcat(state_name, num2cell(fips_state)); % link states to their FIPS code 
fips_state = unique(cell2table(fips_state)); % remove duplicates from the table 
fips_state.Properties.VariableNames = {'state_name','state_code'}; 

coal_purchase_nowc_domestic(:,end+1) = {0}; % add two columns, one for state fips, the other for county fips
coal_purchase_nowc_domestic(:,end+1) = {0};
coal_purchase_nowc_domestic.Properties.VariableNames(end-1:end) = {'state', 'county'};

% for each coal purchase in the coal purchase list, 
for i = 1:size(coal_purchase_nowc_domestic,1)
    purchase_state = coal_purchase_nowc_domestic.Coalmine_State(i); % state coal was purchased from 
    % match the state of purchase with state name in fips table then
    % extract the fips code and store it as fstate 
    fstate = fips_state.state_code(strcmpi(purchase_state, fips_state.state_name) == 1); 
    coal_purchase_nowc_domestic.state(i) = fstate; % store fips state code in coal purchase list 
    if isnumeric(coal_purchase_nowc_domestic.Coalmine_County{i}) % if the county fips code is included 
        % mark the fips code 
        coal_purchase_nowc_domestic.county(i) = fstate*1000 + coal_purchase_nowc_domestic.Coalmine_County{i};
    else % else mark -1 to denote missing county information 
        coal_purchase_nowc_domestic.county(i) = -1; 
    end 
end 

end 