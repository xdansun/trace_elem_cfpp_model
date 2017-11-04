function [output_cell, study_name, apcd_combo] = devito_2002_csesp_wfgd
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Devito et al. 2002
% Title: Flue gas Hg measurements from coal-fired power plants 
% Journal: International Journal of Environment and pollution

%% define study name and air pollution control combination
study_name = 'Devito et al. (2002)'; 
apcd_combo = 1100; 

%% boiler 
% See Table 3 for data 
bot_ash_output = [(11*0+4*13+3*2+3*2)/(11+11) nan nan nan]*10^-2;

%% PM control
% Assume cold side ESP; Table 3
esp_ash_output = [(4*24+4*7+3*13+4*35+3*9+3*8)/22 nan nan nan]*10^-2;

%% SO2 control 
% Table 5, confirm with Table 4
% 66 - 24 = 42; 56 - 7 = 49; 72 - 13 = 59; 75 - 48 = 27; 67 - 11 = 56; 63 - 10 = 53; 
gypsum_output = [(4*42+4*49+3*59+4*27+3*56+3*53)/22 nan nan nan]*10^-2; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
Clpurge_output = zeros(1,4); 

%% stacks 
emission_output = 1 - bot_ash_output - esp_ash_output - gypsum_output;

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_output, esp_ash_output, gypsum_output, ...
    Clpurge_output, emission_output};

end 
