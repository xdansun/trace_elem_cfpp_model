function [output_cell, study_name, apcd_combo, waste_stream_fractions] = klein_trace_elem
% based on the Klein 1975 paper 
% Allen power plant with three 290 MW boilers for a total of 870 MW 
% apcd setup is ESP, but uncertain if Hot-side or Cold-side 

%% define study name and air pollution control combination
study_name = 'Klein et al. (1975)'; 
apcd_combo = 100; 

%% define total outfall mass flows 
% Data obtained from Table 3; The calculation is total = slag + inlet fly
% ash + atmospheric discharge
hg_tot = 0.002 + 0.004 + 0.1; 
as_tot = 0.5 + 1.8 + 0.2 + 1.5 + 8.1 + 0.2; % note that there are two As isotopes 
se_tot = 0 + 1.8 + 0.4; 
cl_tot = 8 + 15 + 1300; 

%% boiler 
% the partition ratio is outfall/total 
% order of elements is Hg, Se, As, and Cl. 
bot_ash_frac = [0.002/hg_tot 2/as_tot 0/se_tot 8/cl_tot];

%% PM - ESP 
% Table 5. Here ESP ash data contains standard deviation measurements 
esp_ash_frac = [0.004/hg_tot 9.9/as_tot 1.8/se_tot 15/cl_tot];

%% wFGD 
clpurge_frac = zeros(1,4); 
gypsum_frac = zeros(1,4); 
%% Stacks 
% split gases entering stacks based on the ratio. 
stacks_frac = [1 1 1 1] - bot_ash_frac - esp_ash_frac; 

%% combine partition fractions together 
waste_stream_fractions = vertcat(bot_ash_frac, esp_ash_frac, gypsum_frac, ...
    clpurge_frac, stacks_frac); 

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_frac, esp_ash_frac, gypsum_frac, ...
    clpurge_frac, stacks_frac};

end 