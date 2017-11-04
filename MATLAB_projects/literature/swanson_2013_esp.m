function [output_cell, study_name, apcd_combo] = swanson_2013_esp
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Swanson et al. (2009)
% Title: Partitioning of selected trace elements in coal combustion products from two coal-burning power plants in the United States
% Journal: International Journal of Coal Geology

%% define study name and air pollution control combination
study_name = 'Swanson et al. (2013)'; 
apcd_combo = 100; 

%% boiler 
% Data in Table 3. Add economizer and bottom ash together 
bot_ash_output = [0 0 4 nan]*10^-2;

%% PM control
% Table 3, Swanson et al. 
esp_ash_output = [2 20 48 nan]*10^-2;

%% no wFGD
cl_purge = zeros(1,4); 
gypsum = zeros(1,4); 

%% stacks 
stacks_frac = 1 - bot_ash_output - esp_ash_output; 

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_output, esp_ash_output, gypsum, ...
    cl_purge, stacks_frac};


end 
