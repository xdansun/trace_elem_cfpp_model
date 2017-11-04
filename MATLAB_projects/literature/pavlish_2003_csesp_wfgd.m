function [output_cell, study_name, apcd_combo, waste_stream_fractions] = ...
    pavlish_2003_csesp_wfgd
% see Pavlish et al., 2003, Fuel Processing Technology. Status review of
% mercury control options for CFPPs 
% multiple sources are presented in the paper. 
%  
%% define study name and air pollution control combination
study_name = 'Pavlish et al. (2003)'; 
apcd_combo = 1100; 

%% boiler 
% order of elements is Hg, Se, As, and Cl. 
bot_ash_frac = [0 nan nan nan]; % not reported

%% PM - ESP 
% Table 3. ICR EPRI 2000 
esp_ash_frac = [27/100 nan nan nan];

%% wFGD 
wfgd_frac = [22/100 nan nan nan]; % Table 3. ICR EPRI 2000
clpurge_frac = zeros(1,4); % ratio of cl purge to gypsum is not given, assume zero
gypsum_frac = wfgd_frac; 
%% Stacks 
% split gases entering stacks based on the ratio. 
stacks_frac = ones(1,4) - bot_ash_frac - esp_ash_frac - wfgd_frac; 

%% combine fractions together 
waste_stream_fractions = vertcat(bot_ash_frac, esp_ash_frac, gypsum_frac, ...
    clpurge_frac, stacks_frac);  

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_frac, esp_ash_frac, gypsum_frac, ...
    clpurge_frac, stacks_frac};

end 
