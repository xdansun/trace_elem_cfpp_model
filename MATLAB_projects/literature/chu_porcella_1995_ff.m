function [output_cell, study_name, apcd_combo] = chu_porcella_1995_ff
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Chu and Porcella (1995)
% Title: Mercury stack emissions from US electric utility power plants
% Journal: Water, Air, and Soil Pollution

%% define study name and air pollution control combination
study_name = 'Chu and Porcella FF (1995)'; 
apcd_combo = 400; 

%% boiler 
% Data in Table 3. Add economizer and bottom ash together 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% First paragraph on page 139 
esp_ash_output = [30 nan nan nan]*10^-2;

%% no wFGD
cl_purge = zeros(1,4); 
gypsum = [0 nan nan nan]; 

%% stacks
emission_output = 1 - bot_ash_output - esp_ash_output;

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_output, esp_ash_output, gypsum, ...
    cl_purge, emission_output};

end 
