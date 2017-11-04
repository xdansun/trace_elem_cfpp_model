function [output_cell, study_name, apcd_combo] = laudal_2000_esp_wfgd
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Laudal et al. (2000)
% Title: Mercury mass balances: A case study of two North Dakota power plants
% Journal: Journal of the Air & Waste Management Association 

%% define study name and air pollution control combination
study_name = 'Laudal et al. (2000)'; 
apcd_combo = 1100; 

%% boiler 
% Data in Table 4, but we use zero because data before the ESP is not
% useful 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% Table 4 % use zero, because 
esp_ash_output = [mean([0.93/18.96 0.90/17.19 0.03/22.36]) nan nan nan];

%% wFGD
% Second paragraph on page 139 
gypsum_output = [mean([1-6.27/7.57 1-1.39/1.72 1-7.93/10.05]) nan nan nan]; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
Clpurge_output = zeros(1,4); 

%% stacks 
emission_output = 1 - bot_ash_output - esp_ash_output - gypsum_output;

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_output, esp_ash_output, gypsum_output, ...
    Clpurge_output, emission_output};

end 
