function [output_cell, study_name, apcd_combo] = chu_porcella_1995_esp_wfgd
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Chu and Porcella (1995)
% Title: Mercury stack emissions from US electric utility power plants
% Journal: Water, Air, and Soil Pollution

%% define study name and air pollution control combination
study_name = 'Chu and Porcella (1995)'; 
apcd_combo = 1100; 

%% boiler 
% Data in Table 3. Add economizer and bottom ash together 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% First paragraph on page 139 
esp_ash_output = [30 nan nan nan]*10^-2;

%% no SO2 control 
% Second paragraph on page 139 
gypsum_output = [15 nan nan nan]*10^-2; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
Clpurge_output = zeros(1,4); 
%% stacks 
emission_output = 1 - bot_ash_output - esp_ash_output - gypsum_output;

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_output, esp_ash_output, gypsum_output, ...
    Clpurge_output, emission_output};

end 
