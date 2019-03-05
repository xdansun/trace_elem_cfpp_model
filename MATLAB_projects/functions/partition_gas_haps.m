function partition_haps_te = partition_gas_haps(haps_plant_data)
% This function estimates the gas phase partitioning of trace elements at
% the boiler level using data from the HAPS (MATS ICR) dataset
% 
% inputs
% haps_plant_data (table) - a table containing every boiler in the HAPS dataset 
%
% outputs
% partition_haps_te (table) - a table containing every boiler, plant code,
% air pollution control device, and the removal of trace elements into the
% solid and liquid phase. For example, hg_remov = 0.96 means hg_gas
% partitioning = 0.04. 

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

%% read in coal fuel (hhv) data 
[num,txt,raw] = xlsread('../data/PISCES_data/fuels_hhv_data.xlsx','haps');
column_numbers = [3 4 7:11]; % identify columns of interest from raw data files
row_start = 1;  % identify row number in which spreadsheet starts; row_start is the row of the header 
fuel_table = table_scrub(raw, column_numbers, row_start); % merge the table together

%% read in emissions data
[num,txt,raw] = xlsread('../data/PISCES_data/selenium_stack_data.xlsx','data');
column_numbers = [3:6 12:16 20]; % identify columns of interest from raw data files
row_start = 1;  % identify row number in which spreadsheet starts; row_start is the row of the header 
se_stack = table_scrub(raw, column_numbers, row_start); % merge the table together

[num,txt,raw] = xlsread('../data/PISCES_data/arsenic_stack_data.xlsx','data');
as_stack = table_scrub(raw, column_numbers, row_start); % merge the table together

% [num,txt,raw] = xlsread('..\PISCES_data\chloride_stack_data.xlsx','data');
% note that if one ran this using the chloride emissions data from haps,
% they would get no matches between the removals and the coal inputs.
% Therefore, we use the hydrogen chloride emissions 
[num,txt,raw] = xlsread('../data/PISCES_data/hcl_stack_data.xlsx','data');
column_numbers = [3:6 12:18 20 23:24]; % identify columns of interest from raw data files
cl_stack = table_scrub(raw, column_numbers, row_start); % merge the table together
% remove nan unit names from cl_stack 
for i = 1:size(cl_stack.Unit_Name,1)
    if isnan(cl_stack.Unit_Name{i,1}) == 1
        flag(i) = 1;
    else
        flag(i) = 0; 
    end 
end 
cl_stack(flag == 1,:) = []; 

[num,txt,raw] = xlsread('../data/PISCES_data/mercury_stack_data.xlsx','data');
hg_stack = table_scrub(raw, column_numbers, row_start); % merge the table together

%% determine air pollution control devices at different units 
unit_list = unique(vertcat(hg_stack(:,{'Unit_Name','Control_Devices'}), se_stack(:,{'Unit_Name','Control_Devices'}), ...
    as_stack(:,{'Unit_Name','Control_Devices'}), cl_stack(:,{'Unit_Name','Control_Devices'}))); %create list of units from coal data 

ctrls = apcd_at_unit_haps(unit_list.Control_Devices); % determine the numeric code associated with controls installed at power plants
unit_list = horzcat(unit_list, array2table(ctrls)); % append results to unit controls table 
unit_list.Properties.VariableNames(end) = {'ctrls'}; 

%% calculate removals from all haps facilities
removals = zeros(size(unit_list,1),4); % initialize removals 
for k = 1:4
    if k == 1
        te_coal = hg_coal; 
        te_stack = hg_stack; 
    elseif k == 2
        te_coal = se_coal; 
        te_stack = se_stack; 
    elseif k == 3
        te_coal = as_coal; 
        te_stack = as_stack; 
    elseif k == 4
        te_coal = cl_coal; 
        te_stack = cl_stack; 
    end 
    for i = 1:size(unit_list,1)
        ppm = median(te_coal.Concentration(strcmp(te_coal.Unit_Name, unit_list{i,1})), 'omitnan'); 
        hhv = median(fuel_table.HHV(strcmp(fuel_table.Unit_Name, unit_list{i,1})),'omitnan'); 
        hhv_inverse = hhv^-1; 
        emf = median(te_stack.Emission_Factor_lb_trillion_Btu(strcmp(te_stack.Unit_Name, unit_list{i,1})),'omitnan');
        removals(i,k) = 1 - (emf*10^-12)./(hhv_inverse.*ppm*10^-6); % calculate removal by air pollution controls into solid and water  
    end
end 

%% combine all haps removal into a single table 
partition_haps_te = horzcat(unit_list, array2table(removals)); 
partition_haps_te(:,2) = []; 
partition_haps_te.Properties.VariableNames = {'Unit_Name','apcds','hg_remov','se_remov','as_remov','cl_remov'}; 

%% merge 
partition_haps_te = innerjoin(partition_haps_te, haps_plant_data(:,{'Unit_Name','Plant_Code','Plant_Boiler'})); 

%% filter out data that doesn't make sense 
partition_haps_te(partition_haps_te.apcds == 0,:) = []; % remove rows where there are no removals 
partition_haps_te.hg_remov(partition_haps_te.hg_remov < 0) = nan; % convert negative removals to NaN
partition_haps_te.se_remov(partition_haps_te.se_remov < 0) = nan; % convert negative removals to NaN
partition_haps_te.as_remov(partition_haps_te.as_remov < 0) = nan; % convert negative removals to NaN
partition_haps_te.cl_remov(partition_haps_te.cl_remov < 0) = nan; % convert negative removals to NaN

% remove boilers where all removals are estimated to be nan
flag = isnan(partition_haps_te.hg_remov) + isnan(partition_haps_te.se_remov) + ...
    isnan(partition_haps_te.as_remov) + isnan(partition_haps_te.cl_remov);
partition_haps_te(flag == 4,:) = []; 
end 