function [output_cell, study_name, apcd_combo, waste_stream_fractions] = rubin_trace_elem
% This function handles the electrostatic precipitator. 
% The data is based off of Ed Rubin's ES&T paper 1999:
% Toxic Releases from Power Plants 
% DOI: es990018d
% See table S2 for the removal efficiency for the case study plant 

study_name = 'Rubin (1999)'; 
apcd_combo = 100; 

%% boiler
% bottom ash splits, see Table S2 
% Hg, Se, As, and Cl partitioning
bot_as = 0.014;
bot_hg = 0.008;
bot_se = 0.015;
bot_cl = 0.001; % only one data point available for partitioning of each trace element 
bot_ash_frac = [bot_hg bot_se bot_as bot_cl];

%% ESP
fly_as = 0.974;
fly_hg = 0.254;
fly_se = 0.604;
fly_cl = 0.00005; 

esp_ash_frac = [fly_hg fly_se fly_as fly_cl];

%% no wFGDs
clpurge_frac = zeros(1,4); 
gypsum_frac = zeros(1,4); 

%% Stacks 
% split gases entering stacks based on the ratio. 
stacks_frac = ones(1,4) - bot_ash_frac - esp_ash_frac; 

%% combine fractions together 
waste_stream_fractions = vertcat(bot_ash_frac, esp_ash_frac, gypsum_frac, ...
    clpurge_frac, stacks_frac);  

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_frac, esp_ash_frac, gypsum_frac, ...
    clpurge_frac, stacks_frac};


end 