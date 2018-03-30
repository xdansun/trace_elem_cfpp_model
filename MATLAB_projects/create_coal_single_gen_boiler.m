function [coal_generators, coal_gen_boiler_wcutoff, ann_coal_gen, num_coal_plants] = ...
    create_coal_single_gen_boiler
% this function goes through the EIA spreadsheets and filters for
% generators that use coal, generators that are linked one-to-one with
% boilers, and cuts off any plants with total nameplate capacity below the
% capacity cutoff; this script also calculates the generation lost from the
% total coal fleet after imposing our restrictions 
%
%
% outputs
% coal_gen_table - a list of generators
% coal_gen_boiler_wcutoff - a list of generators with boilers after
% capacity cutoff has been imposed 

% from EIA, we filter for plants with single generator-boiler links with
% total plant nameplate capacities greater than the cap_cutoff

%% read in generator level data and filter for all generators that use coal
% as a fuel 
[num,txt,raw] = xlsread('../data/EIA_860/3_1_Generator_Y2015.xlsx',...
    'Operable');
column_numbers = [3 4 7 16 34:39]; % identify columns of interest from raw data files
row_start = 2; % spreadsheet starts on row 2
% create a table of all the generators with certain columns of data 
generator_table = table_scrub(raw, column_numbers, row_start);

% create a plant_gen link 
col1 = 'Plant_Code'; 
col2 = 'Generator_ID'; 
% merge the two columns with the name 'Plant_Gen'
generator_table = merge_two_col(generator_table, col1, col2, {'Plant_Gen'}); 

% filter for any generators that do not utilize coal in their first two
% energy sources
coal_index = zeros(size(generator_table,1),1);
% create a variable that contains all energy sources listed in EIA 
% there are a total of six
source_list = {'Energy_Source_1','Energy_Source_2','Energy_Source_3',...
    'Energy_Source_4','Energy_Source_5','Energy_Source_6'};
for i = 1:2 % consider only primary and secondary fuel source %6 for all
    temp = generator_table{:,source_list(i)}; % pull the primary energy source column 
    % find all plants which utilize a type of coal power 
    coal_index = coal_index + strcmp(temp,'BIT') + strcmp(temp,'SUB') + strcmp(temp,'LIG'); % + ...
%         strcmp(temp,'ANT') + strcmp(temp,'WC') + strcmp(temp,'RC');    
end 

% all non-coal sources are removed 
generator_table(~logical(coal_index),:) = [];

%% read in generation at the generator level 
[num,txt,raw] = xlsread('../data/EIA_923/EIA923_Schedules_2_3_4_5_M_12_2015_Final.xlsx',...
    'Page 4 Generator Data');
column_numbers = [1 10 12 26]; % identify columns of interest 
row_start = 6; % identify row number in which spreadsheet starts; index is the row of the header
% gen_by_generator is "generation by generator" and gives the generation at
% the generator level
gen_by_generator = table_scrub(raw, column_numbers, row_start); % create table from raw data 

% merge the columns together to create unique identifier plant to generator
% link
col1 = 'Plant_Id';
col2 = 'Generator_Id';
gen_by_generator = merge_two_col(gen_by_generator, col1, col2, {'Plant_Gen'});
gen_by_generator = [gen_by_generator(:,end) gen_by_generator(:,1:end-1)]; % move the plant_gen identifier column to the first column

% merge annual generation with the coal generator list 
coal_generators = innerjoin(generator_table, ...
    gen_by_generator(:,{'Plant_Gen','Net_Generation_Year_To_Date'})); 

%% create boiler-generator links from EIA form 860 
% Read in EIA 860 6_1 Boiler Generation Data 
[num,txt,raw] = xlsread('../data/EIA_860/6_1_EnviroAssoc_Y2015.xlsx','Boiler Generator');
column_numbers = [3 5 6]; % identify columns of interest from raw data files
row_start = 2; % which row does the spreadsheet start
gen_boiler_link = table_scrub(raw, column_numbers, row_start); % convert the generator into a table 

% merge the plant code with the boiler and the plant code with the
% generator id to create unique identifying strings at the boiler and
% generator level 
col1 = 'Plant_Code'; 
col2 = 'Generator_ID';
col3 = 'Boiler_ID'; 
gen_boiler_link  = merge_two_col(gen_boiler_link, col1, col2, {'Plant_Gen'});
gen_boiler_link = merge_two_col(gen_boiler_link, col1, col3, {'Plant_Boiler'});

%% combine boiler ids with plant generator ids
coal_gen_boiler = innerjoin(coal_generators,gen_boiler_link(:,{'Plant_Gen','Plant_Boiler'})); 

% index of the plant_gen 
gen_index = find(strcmp(coal_gen_boiler.Properties.VariableNames,'Plant_Gen')); 
% index of plant_boil
boil_index = find(strcmp(coal_gen_boiler.Properties.VariableNames,'Plant_Boiler'));

% prepare an array that marks the index. If multi_index(i) = 1, then that
% means there are multiple generators or boilers associated with that
% boiler or generator, respectively. 
multi_index = zeros(size(coal_gen_boiler,1),1);
temp_unique_gen = unique(coal_gen_boiler(:,'Plant_Gen')); 
temp_gen_boiler_cell = table2cell(coal_gen_boiler); % create a cell for ease 
for i = 1:size(temp_unique_gen,1) % for each unique generator id
    % find the boilers which are associated with the generator
    boilers = find(strcmp(temp_unique_gen{i,1},temp_gen_boiler_cell(:,gen_index)));
    if size(boilers,1) > 1 % if there are multiple boilers associated with the generator
        multi_index(boilers) = 1; % mark multi index 
    end 
end 
% remove all arrays for which multi_index = 1 
coal_gen_boiler(find(multi_index),:) = []; %#ok<FNDSB>

% remove boilers with multiple generators linked to the boiler 
% it's the exact same method, only multi_index here will mark multiple
% generators associated with unique boilers 
multi_index = zeros(size(coal_gen_boiler,1),1);
temp_unique_boil = unique(coal_gen_boiler(:,'Plant_Boiler')); % create an unique list of boilers 
temp_gen_boiler_cell = table2cell(coal_gen_boiler); % convert to cell for easy searching 
for i = 1:size(temp_unique_boil,1) % for each boiler 
    generators = find(strcmp(temp_unique_boil{i,1},temp_gen_boiler_cell(:,boil_index))); % find all generators associated with boiler 
    if size(generators,1) > 1 
        multi_index(generators) = 1; % mark index 
    end 
end 
% remove boilers with multiple generators. 
coal_gen_boiler(find(multi_index),:) = []; %#ok<FNDSB>

%% Impose capacity cutoff 
cap_cutoff = 1; % plants with total capacity of 1 MW and greater report to EIA. A plant with two generators of 0.75 MW, then they qualify. 
unique_cfpps = table2array(unique(coal_gen_boiler(:,'Plant_Code'))); % create unique list of power plants 
temp_cfpp_wcap = table2array(coal_gen_boiler(:,{'Plant_Code','Nameplate_Capacity_MW'})); % grab all generators and their capacities 
temp_cfpp_wcap(:,end+1) = 0; % add a column of zeros to identify which generators we can keep

for i = 1:size(unique_cfpps,1)
    % pull all generators at the specific power plant 
    generators_at_plant = temp_cfpp_wcap(temp_cfpp_wcap(:,1) == unique_cfpps(i),2); 
    if sum(generators_at_plant) >= cap_cutoff % if the sum of the nameplate capacities exceed 100 MW
        temp_cfpp_wcap(temp_cfpp_wcap(:,1) == unique_cfpps(i),end) = 1; % set the last column to 1
    end 
end 

coal_gen_boiler_wcutoff = coal_gen_boiler(temp_cfpp_wcap(:,end)==1,:); % remove all plants that do not meet the cutoff 

% remove generators with negative and/or zero generation 
coal_gen_boiler_wcutoff = coal_gen_boiler_wcutoff(coal_gen_boiler_wcutoff.Net_Generation_Year_To_Date > 0, :);

% trim the columns from coal_gen_boiler_wcutoff
coal_gen_boiler_wcutoff(:,{'Generator_ID','Energy_Source_3','Energy_Source_4',...
    'Energy_Source_5','Energy_Source_6',}) = [];

%% Inspect generation losses from cfpp for filtering generators out 
% percent generation lost by looking only at CFPPs with one generator linked to one boiler: 4.8440
ann_coal_gen = sum(table2array(coal_generators(:,'Net_Generation_Year_To_Date'))); 
ann_coal_single_gen = sum(table2array(coal_gen_boiler(:,'Net_Generation_Year_To_Date'))); 
fprintf('percent generation lost by looking only at CFPPs with one generator linked to one boiler: %3.4f\n',...
    (ann_coal_gen-ann_coal_single_gen)/ann_coal_gen*100); 

% percent of plants lost by looking at CFPPs with one generator linked to one boiler
num_coal_plants = size(unique(coal_generators.Plant_Code),1); 
num_single_gb_plants = size(unique(coal_gen_boiler.Plant_Code),1); 
fprintf('percent plants excluded by removing CFPPs with one generator \nlinked to multiple boilers and vice-versa: %3.4f\n',...
    (num_coal_plants-num_single_gb_plants)/num_coal_plants*100); 

% add up generation with capacity cutoff to see the difference 
% calculate total generation 
ann_coal_wcap_cutoff = sum(table2array(...
    coal_gen_boiler_wcutoff(:,'Net_Generation_Year_To_Date'))); 
% determine percent of generation tossed out of dataset 
fprintf('total percent generation lost after capacity cutoff: %3.4f\n',...
    (ann_coal_gen-ann_coal_wcap_cutoff)/ann_coal_gen*100); 
%  total percent generation lost after capacity cutoff: 4.9473

end 