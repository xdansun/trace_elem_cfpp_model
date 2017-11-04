function [sankey_matrix, phase_matrix, error_matrix] = otero_rey_trace_elem
% This function calculates the partitioning coefficients based on the
% empirical data presented in the paper. This paper is the baseline for
% plants with just ESP. 

% output 
% sankey_matrix - partitioning coefficients along different apcd equipments
% phase_matrix - partitioning coefficients of the phases of the trace
% elements 
% error_matrix - the minimum and maximum range of the partitiong 
% coefficients estimates are define 

% This function handles the electrostatic precipitator. 
% The data is based off of Otero-Rey's paper in 2003:
% As, Hg, and Se Flue Gas Sampling in a CFPP and their Fate during Coal
% Combustion 
% DOI: 10.1021/es020949g

%% boiler / bottom ash splits
% data is from Table 10 in Otero-Rey 
% Hg, Se, As, and Cl partitioning
bot_as = [.005 .014 .014];
bot_hg = [.001 .003 .004];
bot_se = [.098 .041 .042];
bot_cl = [.02]; % only one data point available 

% no economizer ash available
ba_ratio = [mean(bot_hg) mean(bot_se) mean(bot_as) mean(bot_cl)]; % define the mean as the partition coefficient 

%% ESP / fly ash splits 
% order of elements is Hg, Se, As, and Cl. 
% fly ash data from Table 10 
fly_as = [.976 .976 .979];
fly_hg = [.218 .194 .284];
fly_se = [.872 .918 .919];
fly_cl = [.13]; % for chlorine, there's only a single data point 

fa_ratio = [mean(fly_hg) mean(fly_se) mean(fly_as) mean(fly_cl)]; % define the mean as the partition coefficient 

%% stacks / flue gas split 
% order of elements is Hg, Se, As, and Cl. 
% stacks data from Table 10, listed in percentage 
fg_as = [1.9 1.0 0.7]/100; 
fg_hg = [78.1 80.3 71.2]/100; 
fg_se = [3.0 4.1 3.9]/100;
fg_cl = [85]/100; % for chlorine, there's only a single data point

fg_ratio = [mean(fg_hg) mean(fg_se) mean(fg_as) mean(fg_cl)]; % define the mean as the partition coefficient 

%% calculate element partition 
% determine mass ratios, note that the Otero-Rey data has already been normalized  
ba_ratio_norm = ba_ratio./(ba_ratio+fa_ratio+fg_ratio);
fa_ratio_norm = fa_ratio./(ba_ratio+fa_ratio+fg_ratio); 
fg_ratio_norm = 1 - ba_ratio_norm - fa_ratio_norm; 

% calculate mols of trace elements leaving through the bottom ash. 
bot_trace = ba_ratio_norm; 
% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = fa_ratio_norm;
% subtract off trace elements in the bottom ash and ESP ash from the
% current collection in the flue gas.
stacks_mol = fg_ratio_norm;

%% make empty fgd matrices 
% the final results in other parts of the analysis contain fgd exit
% streams, but this source only contains esp data, so set fgd values to zero
cl_purge = zeros(1,4); 
gypsum = zeros(1,4); 

%% create three output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

% first output matrix
sankey_matrix = vertcat(bot_trace, esp_ash_mol, gypsum, cl_purge, stacks_mol);  

% second output matrix 
% this assumes that everything exiting the stacks is in the gas phase,
% everything else is in the solid phase 
phase_matrix = zeros(3,4); 
phase_matrix(1,:) = stacks_mol; % gas
phase_matrix(3,:) = esp_ash_mol + bot_trace; % solid 

% create third output matrix - error matrices 
% calculate the min and max deviations away from the mean 
bot_error_low = [min(bot_hg) min(bot_se) min(bot_as) min(bot_cl)] - ba_ratio;
bot_error_high = [max(bot_hg) max(bot_se) max(bot_as) max(bot_cl)] - ba_ratio;
fly_error_low = [min(fly_hg) min(fly_se) min(fly_as) min(fly_cl)] - fa_ratio;
fly_error_high = [max(fly_hg) max(fly_se) max(fly_as) max(fly_cl)] - fa_ratio;
fg_error_low = [min(fg_hg) min(fg_se) min(fg_as) min(fg_cl)] - fg_ratio;
fg_error_high = [max(fg_hg) max(fg_se) max(fg_as) max(fg_cl)] - fg_ratio;

% concatenate error matrices together; % normalization does not need to
% take place because the otero-rey matrix are already normalized 
error_matrix = vertcat(bot_error_low, bot_error_high, fly_error_low, ...
    fly_error_high, zeros(4,4), fg_error_low, fg_error_high);

% to check the normalization assumption, run this
% (ba_ratio+fa_ratio+fg_ratio)

end 