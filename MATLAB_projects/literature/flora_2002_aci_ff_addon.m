function [output_cell, study_name, apcd_combo] = flora_2002_aci_ff_addon(i)
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Flora et al. 2002
% Title: Modeling sorbent injection for mercury control in baghouse
% filters: II 
% Journal: NETL report (see below link)
% https://www.netl.doe.gov/File%20Library/research/coal/ewr/mercury/2002-622.pdf

%% define study name and air pollution control combination
study_name = 'Flora et al. (2002)'; 
apcd_combo = 401; 

sample_removals = [12.2 84.1 88.7 68.2 31.0 42.8 65.6 62.7 3.7 5.4 90.0 87.5 ...
    79.6 96.5 80.8 73.2 32.8 96.7 92.5 91.8 87.7 86.2 10.2];

if i > size(sample_removals,2)
    output_cell = 1;
    return; 
end 

%% boiler 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% Table 1 of Flora et al. 
esp_ash_output = [sample_removals(i) nan nan nan]*10^-2;

%% SO2 control 
gypsum_output = [0 nan nan nan]*10^-2; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
Clpurge_output = zeros(1,4); 

%% stacks
emission_output = 1 - bot_ash_output - esp_ash_output - gypsum_output;

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_output, esp_ash_output, gypsum_output, ...
    Clpurge_output, emission_output};

end 
