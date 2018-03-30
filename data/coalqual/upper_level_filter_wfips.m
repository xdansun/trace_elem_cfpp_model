% this script reads in the completed CQ_upper_level.xlsx spreadsheet
% created by combine_coalqual_data, filters it to essential columns, and
% combines the FIPS information into the spreadsheet.
tic
% clear; clc;

%%
[num,txt,raw] = xlsread('CQ_upper_level.xlsx.'); 

upper_level = cell2table(raw(2:end,:));

%%
upper_level.Properties.VariableNames = raw(1,:); 

% define the columns of interest
interest = {'SampleID';'State';'County';'MinePowerPlant';'SubmitDate';...
    'Strat';'Depthin';'Comments';'EstimatedRank';'ApparentRank';'Province';'Region';...
    'Moisture';'VolatileMatter';'FixedCarbon';'StandardAsh';...
    'Hydrogen';'Carbon';'Nitrogen';'Oxygen';'Sulfur';'Btu';'BtuMoistMMF';...
    'MoistureAshFreeBtu';'Hg';'Se';'As';'Cl';...
    'HgQ';'SeQ';'AsQ';'ClQ'};

%create a new table with the columns of interest 
upper_level_filter = upper_level(:,interest); 

%% define all coal ranks 
lig = {'Lignite A','Lignite B'};
sub = {'Subbituminous A','Subbituminous B','Subbituminous C'};
bit = {'High volatile A bituminous','High volatile B bituminous', ...
    'High volatile C bituminous','Low volatile bituminous', ...
    'Medium volatile bituminous'};
coal_subranks = {'Lignite A','Lignite B','Subbituminous A','Subbituminous B',...
    'Subbituminous C','High volatile A bituminous','High volatile B bituminous', ...
    'High volatile C bituminous','Low volatile bituminous', ...
    'Medium volatile bituminous'};

% pull all coal estimated rank entries into a table 
coal_index = zeros(size(upper_level_filter,1),1);
total_cell = table2cell(upper_level_filter); 
apparent_rank_index = find(strcmp('ApparentRank',...
    upper_level_filter.Properties.VariableNames));

for i = 1:size(coal_subranks,2)
    coal_index = coal_index + strcmp(coal_subranks{i}, total_cell(:,apparent_rank_index));
end 
coal_table = upper_level_filter(logical(coal_index),:);


%% 
% convert the state and counties into the fips code 
% extract the county codes 
% 2010 FIPS code https://www.census.gov/geo/reference/codes/cou.html
fileID = fopen('national_county.txt'); 

temp = textscan(fileID,'%s%d%d%s%s','Delimiter',','); 

state_name = temp{1}; 
fips_state = temp{2};
fips_county = temp{3}; 
county_name = temp{4};

% create a variable of the fips code 
fips_code = fips_state*1000 + fips_county; 

% link counties to to the fips code 
fips_code = horzcat(num2cell(fips_state), county_name, num2cell(fips_code)); 

% remove the last few words from the county name 
for i = 1:size(fips_code,1)
    temp = fips_code{i,2};
    temp = strrep(temp, ' City and Borough', '');
    temp = strrep(temp, ' County', '');
    temp = strrep(temp, ' Borough', ''); 
    temp = strrep(temp, ' Census Area', ''); 
    temp = strrep(temp, ' Municipality', ''); 
    % lastly remove all the sapce in the county name 
    temp = strrep(temp, ' ', ''); 
    fips_code{i,2} = temp;
end 

% % link states to their FIPS code 
fips_state = horzcat(state_name, num2cell(fips_state)); 
% reduce the table to match between states and their fips code 
fips_state = unique(cell2table(fips_state));
fips_state.Properties.VariableNames = {'state_abbrev','fips_state'};

fclose(fileID);
clear dummy1 dummy2 temp*

%% 
% read in state abbreviation information 
fileID = fopen('state_abbrev.csv'); 

temp = textscan(fileID,'%s%s','Delimiter',','); 

states_abbrev = cell2table(horzcat(temp{1}, temp{2}));
states_abbrev.Properties.VariableNames = {'State','state_abbrev'};

fclose(fileID);

% merge the fips state table with the state abbrev cell 
fips_state = innerjoin(states_abbrev, fips_state); 

%% 
% merge the state fips data 
coal_table = innerjoin(coal_table, fips_state(:,{'State','fips_state'})); 
% note that coal_table does not shrink in size after performing the
% innerjoin 

%%
coal_table_wfips = coal_table; 
coal_table_wfips(:,end+1) = array2table(zeros(size(coal_table,1),1));

% name the new column variable name 
coal_table_wfips.Properties.VariableNames(end) = {'fips_code'}; 

% pull a separate column of the counties to avoid messing with the original
coalqual_counties = table2cell(coal_table_wfips(:,'County'));
coalqual_states = table2array(coal_table_wfips(:,'fips_state'));
% clean up the dataset 
for j = 1:size(coalqual_counties,1)
    % remove all spaces from the county name
    coalqual_counties(j) = strrep(coalqual_counties(j), ' ', '');
    % remove all "Borough's" from the county name
    coalqual_counties(j) = strrep(coalqual_counties(j), 'BOROUGH', '');
end

fips_state_list = table2array(cell2table(fips_code(:,1)));

% for each coalqual entry
for i = 1:size(coalqual_counties,1)
    % pull the county level information 
    county = coalqual_counties(i); 
    % find all fips counties that match the coalqual county 
    county_index = find(strcmpi(county, fips_code(:,2))); 
    % for each of those fips counties, determine if the state is also
    % correct 
    for j = 1:size(county_index,1)
%         temp_fips_state = fips_code{county_index(j),1};
        % if the coalqual state matches the fip state 
        if coalqual_states(i) == fips_state_list(county_index(j),1);
            % assign the fips code into coal_table_wfips 
            coal_table_wfips(i,end) = fips_code(county_index(j),end);
        end 
    end 
end 

%%
% write coalqual upperlevel coal data with fips 
writetable(coal_table_wfips,'coalqual_upper_wfips.xlsx');

toc