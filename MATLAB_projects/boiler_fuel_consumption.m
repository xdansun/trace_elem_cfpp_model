function coal_gen_boiler_wfuels = boiler_fuel_consumption(coal_gen_boiler, ann_coal_gen, num_coal_plants)
% This function performs two tasks. First it takes the
% cfpp:generator:boiler:apcd table and merges in the fuel consumption at
% the boiler level so that the final table coal_gen_boiler_wapcd_wfuels is
% cfpp:generator:boiler:apcd:fuel_consumption. Second, it calculates the
% loss of generation from removing power plants that do not report fuel
% consumption at the boiler level 
% 
% inputs
% coal_gen_boiler_wapcd - cfpp:generator:boiler:apcd table 
% ann_coal_gen - total generation from cfpps in 2015 
%
% outputs
% coal_gen_boiler_wapcd_wfuels - cfpp:generator:boiler:apcd:fuels table 

%% create a boiler:fuels table 
[num,txt,raw] = xlsread('../data/EIA_923/EIA923_Schedules_2_3_4_5_M_12_2015_Final.xlsx',...
    'Page 3 Boiler Fuel Data');
% [num,txt,raw] = xlsread('../data/eia9232016/EIA923_Schedules_2_3_4_5_M_12_2016_Final_Revision.xlsx',...
%     'Page 3 Boiler Fuel Data');
column_number = [1 12 14 15 64]; 
row_start = 6; % identify row number in which spreadsheet starts; index is the row of the header
% create a table of all plants with fuel consumption and electricity generation  
fuel_by_boiler = table_scrub(raw, column_number, row_start); % create table from raw data

col1 = 'Plant_Id'; 
col2 = 'Boiler_Id'; 
fuel_by_boiler = merge_two_col(fuel_by_boiler, col1, col2, {'Plant_Boiler'});
%% keep only boilers that burn bituminous coal, subbituminous coal, and lignite
% convert fuels to cell to make matching easier 
temp_fuels_list = table2cell(fuel_by_boiler(:,'Reported_Fuel_Type_Code')); 
% find all boilers that burn bituminous, subbituminous, and lignite 
coal_index = strcmp(temp_fuels_list,'BIT') + strcmp(temp_fuels_list,'SUB') + ...
    strcmp(temp_fuels_list,'LIG'); 
coal_fuel_by_boiler = fuel_by_boiler(logical(coal_index),:); % create boiler:coal fuels table 

%% for each plant_boiler combination, add up the fuel consumption at each boiler
% create a table with just plant_boilers and fuel consumption for convenience 
coal_boiler_fuels = coal_fuel_by_boiler(:,{'Plant_Boiler','Total_Fuel_Consumption_Quantity'});
unique_boiler_fuels = table2cell(unique(coal_boiler_fuels(:,{'Plant_Boiler'}))); % create a unique list of boilers 
unique_boiler_fuels(:,end+1) = {0}; % add a row of zeros to add fuel consumption 
plant_boiler_list = table2cell(coal_boiler_fuels(:,{'Plant_Boiler'})); % grab list of boilers without removing duplicates 
for i = 1:size(unique_boiler_fuels,1) % for each unique plant_boiler combination
    boiler = unique_boiler_fuels{i,1}; % grab the unique boiler 
    fuels = coal_boiler_fuels(strcmp(boiler,plant_boiler_list) == 1,end); % grab all fuel consumed by that boiler 
    unique_boiler_fuels{i,2} = sum(table2array(fuels)); % mark total fuel consumed by that plant_boiler 
end 

unique_boiler_fuels = cell2table(unique_boiler_fuels); % convert cell to table and mark headers 
unique_boiler_fuels.Properties.VariableNames = {'Plant_Boiler','Fuel_Consumed'}; 

% merge the fuel consumption data to the plant_boiler so now we have 
% cfpp:generator:boiler:apcds:fuel consumption
coal_gen_boiler_wfuels = innerjoin(coal_gen_boiler, unique_boiler_fuels); 

%%
% calculate generation lost from removing boilers without fuel consumption 
num_plants_wfuel = size(unique(coal_gen_boiler_wfuels.Plant_Code),1); 
generation_wconsumption = sum(coal_gen_boiler_wfuels.Net_Generation_Year_To_Date);

fprintf('total percent plants and generation lost due to fuel consumption data limitation: %3.2f %3.2f\n',...
    (num_coal_plants - num_plants_wfuel)/num_coal_plants*100,...
    (ann_coal_gen - generation_wconsumption)/ann_coal_gen*100); 

end 