function [output_cell, study_name, apcd_combo] = helble_2000_trace_elem
% Helble 2000 
% Fuel processing technology 
% Model for the air emissions of trace metallic elements from coal 
% combustors equipped with electrostatic precipitators

%% define study name and air pollution control combination
study_name = 'Helble (2000)'; 
apcd_combo = 100; 

%% boiler
% bottom ash splits
%Hg, Se, As, and Cl partitioning
bot_ash_frac = [0 0 0 nan]; %detection limits 

%% ESP
% order of elements is Hg, Se, As, and Cl. 
% data from Table 10 
fly_ash_frac = [0.289 0.491 0.961 nan];

%% no wFGD
cl_purge = zeros(1,4); 
gypsum = zeros(1,4); 

%% stacks
stacks_frac = 1 - fly_ash_frac; 

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_frac, fly_ash_frac, gypsum, ...
    cl_purge, stacks_frac};



end 