function [output_cell, study_name, apcd_combo] = brekke_1995_ff
% This function handles the baghouse... can be modified to include other
% APCs 
% Based on the paper: Brekke 1995 Comparison  of  hazardous  air
% pollutants  from  advanced  conventional  power  systems. In: 12th
% Annual  International Pittsburgh Coal Conference, Pittsburgh,
% Pennsylvania, USA.
% https://digital.library.unt.edu/ark:/67531/metadc621107/m2/1/high_res_d/137325.pdf

%% define study name and air pollution control combination
study_name = 'Brekke et al. (1995)'; 
apcd_combo = 400; 

%% boiler
% bottom ash splits
bot_ash_ratio = [0 0 0 nan];

%% ESP
% data from Figure 3; use for FF 
fly_hg = 0.60;
fly_se = 0.65;
% In Fig 3, total CAAA trace metals includes As; therefore baghouse removal
% of As should be similar to all other trace metals included in CAAA trace metals 
fly_as = 0.99; 
fly_cl = nan; % for chlorine, there's only a single data point 

fly_ash_ratio = [fly_hg fly_se fly_as fly_cl];

%% no wFGD
cl_purge = zeros(1,4); 
gypsum = zeros(1,4); 

%% stacks 
stacks_frac = 1 - bot_ash_ratio - fly_ash_ratio; 

%% format output 
output_cell = {study_name, apcd_combo, bot_ash_ratio, fly_ash_ratio, gypsum, ...
    cl_purge, stacks_frac};

end 