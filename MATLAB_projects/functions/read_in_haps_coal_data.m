function [plant_trace_haps, all_trace_ids, haps_sampling_months] = read_in_haps_coal_data
%% Description:
% reads in the coal concentration data from the 2010 HAPS ICR 
% 
% inputs:
% none
%
% outputs:
% plant_trace_haps (table) - each plant in HAPS with the concentration of
% each trace element and each coal sample taken at the plant
% all_trace_ids (table) - boiler level information with coal type, plant
% boiler, unit name, and plant ID. This table likely exists to conveniently
% find out more about the boiler and merge information 
% haps_sampling_months (array) - plant codes with the start (column 2) and
% end month (column 3) of the sampling

%% read in coal input data for arsenic, selenium, mercury, and chlorine 
[num,txt,raw] = xlsread('../data/PISCES_data/arsenic_coal_data.xlsx','haps');
column_numbers = [3 4 7:11]; % identify columns of interest from raw data files
row_start = 1;  % identify row number in which spreadsheet starts; row_start is the row of the header 
as_coal = table_scrub(raw, column_numbers, row_start); % merge the table together

[num,txt,raw] = xlsread('../data/PISCES_data/chloride_coal_data.xlsx','haps');
cl_coal = table_scrub(raw, column_numbers, row_start); % merge the table together

[num,txt,raw] = xlsread('../data/PISCES_data/selenium_coal_data.xlsx','haps');
se_coal = table_scrub(raw, column_numbers, row_start); % merge the table together

[num,txt,raw] = xlsread('../data/PISCES_data/mercury_coal_data.xlsx','haps');
hg_coal = table_scrub(raw, column_numbers, row_start); % merge the table together

%% determine all of the power plants in HAPS 
% create a combined list of units and coal type associated at the unit 
all_trace = se_coal(:,{'Unit_Name','Coal_Type'}); 
all_trace = vertcat(all_trace, hg_coal(:,{'Unit_Name','Coal_Type'})); 
all_trace = vertcat(all_trace, as_coal(:,{'Unit_Name','Coal_Type'})); 
all_trace = vertcat(all_trace, cl_coal(:,{'Unit_Name','Coal_Type'})); 

all_trace = unique(all_trace); % note that all coal samples are identical
    % the size of the list with just unit names compare to unit names with
    % coal type are equal 

%%
% for plant ids 52007 and 3954 units 1&2, create a duplicate to permit more
% matches; 
% not sure what the logic was here anymore - 04/21
all_trace_ids = all_trace; 
% all_trace_ids(end+1,:) = all_trace(strcmp('Morgantown Energy Facility 10743_Unit 1&2',all_trace_ids.Unit_Name),:); 
% all_trace_ids(end+1,:) = all_trace(strcmp('Mt. Storm 3954_Unit 1&2',all_trace_ids.Unit_Name),:); 
% all_trace_ids = sortrows(all_trace_ids,'Unit_Name','ascend');

% read in the plant code translation (done manually)
[num,txt,raw] = xlsread('../data/PISCES_data/haps_analysis.xlsx','plant_code_v2'); 
column_numbers = 1:3; % identify columns of interest from raw data files
row_start = 1;  % identify row number in which spreadsheet starts; row_start is the row of the header 
eia_code_translate = table_scrub(raw, column_numbers, row_start); % merge the table together

% append plant code data to the trace ids from HAPS 
% all_trace_ids(:,end+1) = array2table(eia_code_translate.plant); % old code. New code works better. (04/21)
all_trace_ids = innerjoin(all_trace_ids, eia_code_translate); 
% all_trace_ids.Properties.VariableNames(end) = {'Plant_Code'}; % old code. New code works better. 
% all_trace_ids = unique(all_trace_ids); % this doesn't do anything. It can be used as a check to make sure there are no duplicates 

%% determine coal distribution at each unit 
haps_trace_dist = cell(1,4); 

for k = 1:4 % for each trace element 
    if k == 1
        trace_coal = hg_coal;
    elseif k == 2
        trace_coal = se_coal;
    elseif k == 3
        trace_coal = as_coal;
    elseif k == 4
        trace_coal = cl_coal;
    end 
    unit_list = trace_coal.Unit_Name; % obtain list of all units
    conc_array = trace_coal.Concentration; % obtain list of all concentrations
    for i = 1:size(all_trace_ids)
        unit = all_trace_ids.Unit_Name{i,1}; % pull the unit of interest 
        haps_trace_dist(i,k) = {conc_array(strcmp(unit,unit_list))}; % append all coal samples to the unit 
    end 
end 

%% determine dates associated with purchases 
haps_dates = cell(size(all_trace_ids,1),1); 

for k = 1:4
    if k == 1
        trace_coal = hg_coal;
    elseif k == 2
        trace_coal = se_coal;
    elseif k == 3
        trace_coal = as_coal;
    elseif k == 4
        trace_coal = cl_coal;
    end
    unit_list = trace_coal.Unit_Name; % obtain list of all units
    dates = trace_coal.Sample_Date; % obtain list of all concentrations
    for i = 1:size(all_trace_ids,1)
        unit = all_trace_ids.Unit_Name{i,1}; % pull the unit of interest
        if k == 1
            haps_dates(i,1) = {dates(strcmp(unit,unit_list))}; % append all coal samples to the unit
        else
            haps_dates(i,1) = {vertcat(haps_dates{i,1}, dates(strcmp(unit,unit_list)))}; % append all coal samples to the unit
        end 
    end
    
end 

%% determine coal distribution at each plant 
plant_list = unique(all_trace_ids.Plant_Code); % create a unique list of plants 
plant_trace_haps = cell(1,4); 
for k = 1:4 % for each trace element 
    for i = 1:size(plant_list,1) % for each power plant 
        cell_conc = haps_trace_dist(all_trace_ids.Plant_Code == plant_list(i),k); % pull all coal samples from all units 
        plant_conc = cell_conc{1,1}; % combine all unit coal samples into a single array 
        for j = 2:size(cell_conc,1)
            plant_conc = vertcat(plant_conc, cell_conc{j,1}); 
        end 
        plant_trace_haps(i,k) = {plant_conc}; % append to the cell 
    end 
end 

plant_trace_haps = horzcat(array2table(plant_list), cell2table(plant_trace_haps)); 
plant_trace_haps.Properties.VariableNames = {'Plant_Code','hg_haps_ppm','se_haps_ppm','as_haps_ppm','cl_haps_ppm'}; 

%% estimate sampling dates 
% for each boiler in the MATS ICR dataset, determine when MATS ICR sampling took place
% we want to estimate trace element concentrations in coal blends using
% COALQUAL for the months that MATS ICR sampling took place 
min_month = zeros(size(haps_dates,1),1); 
max_month = zeros(size(haps_dates,1),1); 
for i = 1:size(haps_dates,1)
    dates = haps_dates{i,1};
    months = zeros(size(dates,1),1); 
    for j = 1:size(dates,1)
        if isnumeric(dates{j,1}(1,1)) == 1 % if no dates are recorded, set min and max month to calendar year
            min_month(i) = 1;
            max_month(i) = 12; 
            j = size(dates,1) + 1; % break for loop
        else
            months(j) = str2num(dates{j,1}(1,1));
        end 
    end 
    min_month(i) = min(months);
    max_month(i) = max(months);
end 
% merge plant IDs, first month for sampling and last month for sampling 
boiler_months = [all_trace_ids.Plant_Code min_month max_month]; 

% recompile sampling months at the plant level  
haps_sampling_months = unique(boiler_months(:,1)); 
for i = 1:size(haps_sampling_months,1)
    haps_sampling_months(i,2) = min(boiler_months(boiler_months(i,1) == haps_sampling_months(:,1),2)); 
    haps_sampling_months(i,3) = max(boiler_months(boiler_months(i,1) == haps_sampling_months(:,1),2)); 
end 

end 