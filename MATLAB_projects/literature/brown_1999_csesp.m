function [output_cell, study_name, apcd_combo, waste_stream_fractions] = brown_1999_csesp
% see Brown 1999, 
%  
%% define study name and air pollution control combination
study_name = 'Brown et al. (1999)'; 
apcd_combo = 100; 

%% boiler 
% order of elements is Hg, Se, As, and Cl. 
bot_ash_frac = [0 nan nan nan]; % not reported

%% PM - ESP 
% % Figure 25
esp_ash_frac = [mean([0 60 25 30 35]) nan nan nan]*10^-2;

%% wFGD 
wfgd_frac = [0 nan nan nan]; % Table 3. ICR EPRI 2000
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
