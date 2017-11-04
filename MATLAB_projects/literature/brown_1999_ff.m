function [output_cell, study_name, apcd_combo, waste_stream_fractions] = brown_1999_ff
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Brown et al. 1999
% Title: Mercury Measurement and Its Control: What We Know, Have Learned, and Need to Further Investigate
% Journal: Journal of Air and Waste management association 

%% define study name and air pollution control combination
study_name = 'Brown et al. FF (1999)'; 
apcd_combo = 300; 

%% boiler 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% Figure 25
esp_ash_output = [mean([65 85 90 55 65 68 95 99 98 99 50 65 67]) nan nan nan]*10^-2;

%% no wFGD
% Data from Table 14
% Note that Figure 5 and 8 also have data, but they assume that all Hg
% particulate matter is removed
% for FF this leads to negative wFGD removal
% fgd_removal = [49.7 65.0 37.8 48 58 45.9 57 5 3.5]*10^-2; % subtract off csesp, hsesp, and ff contribution in removal 
gypsum_output = [0 nan nan nan]; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
Clpurge_output = zeros(1,4); 

%% Stacks 
% split gases entering stacks based on the ratio. 
stacks_frac = 1 - bot_ash_output - esp_ash_output - gypsum_output;

%% combine partition fractions together 
waste_stream_fractions = vertcat(bot_ash_output, esp_ash_output, gypsum_output,...
    Clpurge_output, stacks_frac);  

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_output, esp_ash_output, gypsum_output, ...
    Clpurge_output, stacks_frac};

end 
