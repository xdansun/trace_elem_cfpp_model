%% description:
% In upper_level_filter_wfips, I determine the FIPS county codes of each
% coalqual sample. However, while CQ_upper_level contains 7626 samples,
% coalqual_upper_wfips contains only 6673 samples. I believe 15% of the
% samples are dropped because I was not able to match the county name to a
% FIPS code, but it's important to look into why. 

%% overhead
% clear; clc; close all; 

%% input raw upper level COALQUAL data and remove most columns to simplify the analysis 
[num,txt,raw] = xlsread('CQ_upper_level.xlsx.'); 

upper_level = cell2table(raw(2:end,:));
upper_level.Properties.VariableNames = raw(1,:); 

% define the columns of interest
interest = {'SampleID';'State';'County';'MinePowerPlant';'SubmitDate';...
    'Strat';'Depthin';'Comments';'EstimatedRank';'ApparentRank';...
    'Moisture';'VolatileMatter';'FixedCarbon';'StandardAsh';...
    'Hydrogen';'Carbon';'Nitrogen';'Oxygen';'Sulfur';'Btu';'BtuMoistMMF';...
    'MoistureAshFreeBtu';'Hg';'Se';'As';'Cl';...
    'HgQ';'SeQ';'AsQ';'ClQ'};

%create a new table with the columns of interest 
upper_level_filter = upper_level(:,interest); 

%% input upper level COALQUAL data with FIPS codes 
[num,txt,raw] = xlsread('coalqual_upper_wfips.xlsx'); 

coal_table_wfips = cell2table(raw(2:end,:));
coal_table_wfips.Properties.VariableNames = raw(1,:); 

%% match two tables and compare differences 
cq_no_fips = outerjoin(upper_level,coal_table_wfips(:,1)); 
cq_no_fips = cq_no_fips(strcmp(cq_no_fips.SampleID_right, ''),:); 

%% it becomes clear that I filtered away plants without an apparent rank. 
% However, I could include coal samples with estimated ranks. The
% difference between estimate and apparent rank is that apparent rank is
% determined in a lab while estimated rank is determined by the person out
% in the field 
% documentation available here: https://ncrdspublic.er.usgs.gov/coalqual/CQDef.htm

%% check which states are included with data 
state_list = unique(cq_no_fips.State(isnan(cq_no_fips.Cl) == 0));
state_list2 = unique(coal_table_wfips.State(isnan(coal_table_wfips.Cl) == 0));
% unique(vertcat(state_list, state_list2))
state_list2
%% 
size(unique(upper_level.State))
size(unique(coal_table_wfips.State))

