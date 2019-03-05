function [boiler_pm_link, boiler_so2_link, boiler_nox_link,...
    boiler_hg_link] = apcd_link()
% This function reads in apcds spreadsheets from EIA and merges the boilers
% with the apcd id and the apcd equipment type 
%
% no inputs
%
% outputs:
% boiler_pm_link - a table with boiler:apcd_id:apcd equipments for the
% particulate matter controls
% boiler_so2_link - same as above except for so2
% boiler_nox_link - same as above except for nox
% boiler_hg_link - same as above except for hg 

%% read in PM, NOx, SO2, and mercury pollution IDs 
% READ IN EIA 860 6_1 ENVIROASSOC DATA - BOILER PM
[num,txt,raw] = xlsread('../data/EIA_860/6_1_EnviroAssoc_Y2015.xlsx','Boiler Particulate Matter');
column_numbers = 3:6; % identify columns of interest from raw data files
row_start = 2;  % identify row number in which spreadsheet starts; row_start is the row of the header 
boiler_pm = table_scrub(raw, column_numbers, row_start); % merge the table together

% create unique plant_boiler identification string and plant_PM
% identification string
col1 = 'Plant_Code'; % the name of the column that will merge together later
col2 = 'Boiler_ID'; 
col3 = 'Particulate_Matter_Control__ID';
boiler_pm = sortrows(boiler_pm,'Plant_Code','ascend'); % sort data for later convenience 
boiler_pm = merge_two_col(boiler_pm, col1, col2, {'Plant_Boiler'}); % combine two columns
boiler_pm = merge_two_col(boiler_pm, col1, col3, {'Plant_PM'});
boiler_pm(:,1:end-2) = []; % remove all but the last two columns, which contain Plant_boiler and Plant_PM ids 
boiler_pm = unique(boiler_pm); % remove duplicate entries 

% READ IN EIA 860 6_1 ENVIROASSOC DATA - BOILER SO2 
% create a link between the boiler and the so2 control 
[num,txt,raw] = xlsread('../data/EIA_860/6_1_EnviroAssoc_Y2015.xlsx','Boiler SO2');
column_numbers = 3:6; % identify columns of interest from raw data files
row_start = 2; % identify row number in which spreadsheet starts; index is the row of the header
boiler_so2 = table_scrub(raw, column_numbers, row_start); % merge the table together

% create unique plant_boiler identification string and plant_SO2
% identification string
col1 = 'Plant_Code'; 
col2 = 'Boiler_ID'; 
col3 = 'SO2_Control_ID';
boiler_so2 = sortrows(boiler_so2,'Plant_Code','ascend'); % sort data for later convenience 
boiler_so2 = merge_two_col(boiler_so2, col1, col2, {'Plant_Boiler'}); % combine the two columns
boiler_so2 = merge_two_col(boiler_so2, col1, col3, {'Plant_SO2'});
boiler_so2(:,1:end-2) = []; % remove all but the last two columns, which contain Plant_boiler and Plant_so2 ids 
boiler_so2 = unique(boiler_so2); % remove duplicate entries 

% READ IN EIA 860 6_1 ENVIROASSOC DATA - BOILER NOX
[num,txt,raw] = xlsread('../data/EIA_860/6_1_EnviroAssoc_Y2015.xlsx','Boiler NOx'); 
column_numbers = 3:6; % identify columns of interest from raw data files
row_start = 2; % identify row number in which spreadsheet starts; index is the row of the header
boiler_nox = table_scrub(raw, column_numbers, row_start); % merge the table together

% create unique plant_boiler identification string and plant_nox
% identification string
col1 = 'Plant_Code'; 
col2 = 'Boiler_ID'; 
col3 = 'NOx_Control_ID';
boiler_nox = sortrows(boiler_nox,'Plant_Code','ascend'); % sort data for later convenience 
boiler_nox = merge_two_col(boiler_nox, col1, col2, {'Plant_Boiler'}); % combine the two columns
boiler_nox = merge_two_col(boiler_nox, col1, col3, {'Plant_NOx'});
boiler_nox(:,1:end-2) = []; % remove all but the last two columns, which contain Plant_boiler and Plant_nox ids 
boiler_nox = unique(boiler_nox);

% READ IN EIA 860 6_1 ENVIROASSOC DATA - BOILER MERCURY
[num,txt,raw] = xlsread('../data/EIA_860/6_1_EnviroAssoc_Y2015.xlsx','Boiler Mercury');
column_numbers = 3:6; % identify columns of interest from raw data files
row_start = 2; % identify row number in which spreadsheet starts; index is the row of the header
boiler_hg = table_scrub(raw, column_numbers, row_start); % merge the table together 

% create unique plant_boiler identification string and plant_hg
% identification string
col1 = 'Plant_Code'; 
col2 = 'Boiler_ID'; 
col3 = 'Mercury_Control_ID';
boiler_hg = sortrows(boiler_hg,'Plant_Code','ascend'); % sort data for later convenience 
boiler_hg = merge_two_col(boiler_hg, col1, col2, {'Plant_Boiler'}); % combine the two columns
boiler_hg = merge_two_col(boiler_hg, col1, col3, {'Plant_Hg'});
boiler_hg(:,1:end-2) = []; % remove all but the last two columns, which contain Plant_boiler and Plant_Hg ids 
boiler_hg = unique(boiler_hg);
%% link in generator level apcd ids to apcd equipment 
[num,txt,raw] = xlsread('../data/EIA_860/6_1_EnviroAssoc_Y2015.xlsx',...
    'Emissions Control Equipment');
column_numbers = [3 5:9 11]; % identify columns of interest from raw data files
row_start = 2; % which row does the spreadsheet start
plant_apcds = table_scrub(raw, column_numbers, row_start); % convert the generator into a table 

% only keep plant_apcds which are "operating" 
status = plant_apcds.Status; 
plant_apcds = plant_apcds(strcmp('OP',status),:); 

% create plant_apcd_ids identifier strings 
col1 = 'Plant_Code'; % the name of the columns that will be merged
col2 = 'Particulate_Matter_Control_ID';
col3 = 'SO2_Control_ID'; 
col4 = 'NOx_Control_ID'; 
col5 = 'Mercury_Control_ID'; 
plant_apcds = merge_two_col(plant_apcds, col1, col2, {'Plant_PM'}); % combine two columns
plant_apcds = merge_two_col(plant_apcds, col1, col3, {'Plant_SO2'});
plant_apcds = merge_two_col(plant_apcds, col1, col4, {'Plant_NOx'});
plant_apcds = merge_two_col(plant_apcds, col1, col5, {'Plant_Hg'});

% remove apcd ids as they are no longer needed 
plant_apcds(:,{'Status','Particulate_Matter_Control_ID','SO2_Control_ID',...
    'NOx_Control_ID','Mercury_Control_ID'}) = []; 

%% check to make sure all DSI's are actual SO2 controls 
% first, import SO2 control data at the so2 control level from EIA 860-6-2
[num,txt,raw] = xlsread('../data/EIA_860/6_2_EnviroEquip_Y2015.xlsx', 'FGD');
column_numbers = [3 6:10]; % identify columns of interest from raw data files
row_start = 2; % which row does the spreadsheet start
boiler_so2_ctrls = table_scrub(raw, column_numbers, row_start); % convert the generator into a table 

boiler_so2_ctrls = merge_two_col(boiler_so2_ctrls, 'Plant_Code', 'SO2_Control_ID', {'Plant_SO2'});

% mark all so2 control IDs with DSI; here plants are required to report the
% sorbent used. Since all sorbents reported on this sheet are used for
% removing acid gases, if DSI is reported on schedule 6-1 but not on
% schedule 6-2, then we can assume that the DSI is used for removing
% mercury and not acid gases 
flag = zeros(size(boiler_so2_ctrls,1),1); 
for i = 1:size(boiler_so2_ctrls,1)
    for j = 3:6 % for the different SO2_Types
        if strcmp(boiler_so2_ctrls{i,j},'DSI') == 1
            flag(i) = 1; 
            break; 
        end 
    end 
end 
boiler_dsi = horzcat(boiler_so2_ctrls, array2table(flag)); 
boiler_dsi.Properties.VariableNames(end) = {'DSI'}; 
% boiler_dsi(:, 1:6) = []; % remove all unnecessary columns from boiler dsi 
boiler_dsi(boiler_dsi.DSI == 0,:) = []; 
%% find all DSIs in plant_apcds, if the SO2 ID does not match 
dsi_idx = find(strcmp(plant_apcds.Equipment_Type, 'DSI')); 
omit_plants = [564, 3149, 3399, 57919]; % these plants report DSI is unusual ways and likely have DSI installed at their plants 
for i = 1:size(dsi_idx,1)
    if sum(strcmp(plant_apcds.Plant_SO2(dsi_idx(i)), boiler_dsi.Plant_SO2)) < 1 
        % if DSI reported in plant_apcds, but not in boiler_dsi
        % implying DSI is used for ACI 
        if sum(plant_apcds.Plant_Code(dsi_idx(i)) == omit_plants) == 0
            plant_apcds.Equipment_Type(dsi_idx(i)) = {'ACI'}; 
        end 
    end 
end 

% These are the plant codes with reporting ambiguities 
%         564 ??, probably DSI 
%         1355 unclear, assume ACI
%         1364 ACI
%         3149 ?? probably DSI, but which boilers? 
%         3399 DSI
%         6071 ACI
%         6073 ACI
%         6124 ACI
%         6190 ACI
%         6772 ACI
%        57919 DSI 

%% rename apcd equipments from EIA for data analysis
% EIA will also use acronyms that make it confusing to tell from first
% inspection what the apcd is. Therefore, we rename it for our own
% convenience. 

[num,txt,raw] = xlsread('../data/Misc_Data/apcd_abbrev.xlsx'); % read in apcd_abbrev spreadsheet 
apcd_rename = raw;        

% replace all EIA's apcd initials into ones that are more recognizable 
% pull all equipment types from original plant_apcd table into a dummy
% list of apcds 
temp_apcds = table2cell(plant_apcds(:,'Equipment_Type')); 
for i = 1:size(temp_apcds,1) % for each acpd 
    % search if the apcd appears in the apcd renaming table 
    temp_index = find(strcmp(temp_apcds{i,1},apcd_rename(:,1))); 
    if size(temp_index) > 0 % if there's a match 
        temp_apcds{i,1} = apcd_rename(temp_index,3); % replace the name of the apcd    
    else
        display(temp_apcds{i,1}) % otherwise print what was not in our table 
    end 
end 

% add a new column which has the new apcd abbreviations  
plant_apcds{:,'apcd_abbrev'} = temp_apcds; 

%%
% merge apcd-apcd_id link table with the boiler-apcd_id link so that we
% have separate lists for boiler:apcd_id:apcd 
% we merge left to prevent loss of data and prevent too many duplicate entries 
boiler_pm = outerjoin(boiler_pm, ...
    plant_apcds(:,{'Plant_PM','apcd_abbrev'}),...
    'MergeKeys',1,'Type','Left'); 
boiler_so2 = outerjoin(boiler_so2, ...
    plant_apcds(:,{'Plant_SO2','apcd_abbrev'}),...
    'MergeKeys',1,'Type','Left');
boiler_nox = outerjoin(boiler_nox, ...
    plant_apcds(:,{'Plant_NOx','apcd_abbrev'}),...
    'MergeKeys',1,'Type','Left');
boiler_hg = outerjoin(boiler_hg, ...
    plant_apcds(:,{'Plant_Hg','apcd_abbrev'}),...
    'MergeKeys',1,'Type','Left');

%%
% collapse all apcds onto a single boiler. For example if there are two
% instances of plant_boiler, 1001_01, one with ESP and the second with FF,
% combine those apcds to a single plant_boiler with ESP and FF listed under
% PM controls 
boiler_pm_link = unique_boiler_apcd_link(boiler_pm,'PM'); 
boiler_so2_link = unique_boiler_apcd_link(boiler_so2,'SO2'); 
boiler_nox_link = unique_boiler_apcd_link(boiler_nox,'NOx'); 
boiler_hg_link = unique_boiler_apcd_link(boiler_hg,'Hg'); 

end 