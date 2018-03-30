function [output_cell, study_name, apcd_combo] = felsvang_1994_dfgd_ff_aci
% Felsvang et al. 1994
% Activated carbon injection in spray dryer/ESP/FF for mercury and toxics control
% Fuel Processing Technology

%% define study name and air pollution control combination
study_name = 'Felsvang et al. (1994)'; 
apcd_combo = 2401; 

%% boiler
% bottom ash splits
%Hg, Se, As, and Cl partitioning
bot_ash_frac = [0 nan nan nan]; %detection limits 

%% dFGD + FF
% order of elements is Hg, Se, As, and Cl. 
% data for Hg removal with ACI is in Table 1; 
fly_ash_frac = [0.99 nan nan nan];

%% no wFGD
cl_purge = nan(1,4); 
gypsum = nan(1,4); 

%% stacks
stacks_frac = 1 - fly_ash_frac; 

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_frac, fly_ash_frac, gypsum, ...
    cl_purge, stacks_frac};



end 