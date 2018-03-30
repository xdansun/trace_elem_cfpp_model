function [output_cell, study_name, apcd_combo, waste_stream_fractions] = aunela_tapola_dfgd
% Aunela-Tapola et al. 
% Fuel Processing Technology
% 1998
% A study of trace element behaviour in two modern CFPPs
% Finnish plants 

%% define study name and air pollution control combination
study_name = 'Aunela Tapola et al. (1998)'; 
apcd_combo = 2400; 

%% boiler 
% the partition ratio is outfall/total 
% order of elements is Hg, Se, As, and Cl. 
bot_ash_frac = [0 nan 0 nan];

%% PM - ESP 
% Table 8. Here ESP ash data contains standard deviation measurements 
% although total As removal is n.c. in Table 8 for plant HB, in Table 7, I
% estimate that removal of As by the dFGD should be around 0.99 
esp_ash_frac = [mean([0.44 0.97]) nan mean([0.71 0.99]) nan];

%% wFGD 
clpurge_frac = [nan nan nan nan];
gypsum_frac = [nan nan nan nan]; 
%% Stacks 
% split gases entering stacks based on the ratio. 
stacks_frac = [1 1 1 1] - esp_ash_frac; 

%% combine partition fractions together 
waste_stream_fractions = vertcat(bot_ash_frac, esp_ash_frac, gypsum_frac, ...
    clpurge_frac, stacks_frac); 

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_frac, esp_ash_frac, gypsum_frac, ...
    clpurge_frac, stacks_frac};

end 