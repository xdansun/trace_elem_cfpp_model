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
bot_as_avg = 0.014;
bot_hg_avg = 0.008;
bot_se_avg = 0.015;
bot_cl_avg = 0.001; % only one data point available 
bot_ash_frac = [bot_hg_avg bot_se_avg bot_as_avg bot_cl_avg];

%% ESP
fly_as_avg = 0.974;
fly_hg_avg = 0.254;
fly_se_avg = 0.604;
fly_cl_avg = 0.00005; % for chlorine, there's only a single data point 

esp_ash_frac = [fly_hg_avg fly_se_avg fly_as_avg fly_cl_avg];

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