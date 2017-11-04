function [sankey_matrix, phase_matrix, error_matrix] = ...
    pavlish_2003_csESP(trace_elem_input)
% see Pavlish et al., 2003, Fuel Processing Technology. Status review of
% mercury control options for CFPPs 
% multiple sources are presented in the paper. We opted to aggregate all
% the data into a single point estimate, given we did not have access to
% the original data. Future adoption would separate out these three conference 
% papers. It is not clear how Pavlish dervied numeric values from the
% conference papers. 

% this script reflects csESP controls 
% 
% inputs
% trace_elem_input - default is [1 1 1 1], which will allow this function
% to calculate the partitioning coefficient. Trace_elem_input can also be
% defined as the molar input into the boiler to calculate the molar output 
% 
% output 
% sankey_matrix - partitioning coefficients along different apcd equipments
% phase_matrix - partitioning coefficients of the phases of the trace
% elements 
% error_matrix - the minimum and maximum range of the partitiong 
% coefficients estimates are define 

% This function handles the electrostatic precipitator. Can support other
% apcd combinations... would have to implement in separate scripts 
% 

%% boiler / bottom ash splits
% no data
ba_ratio = [nan nan nan nan]; % define the mean removal by the boiler  

%% ESP / fly ash splits 
% order of elements is Hg, Se, As, and Cl. 
% fly ash data from Table 3
fa_hg = [0.27 0.39 0.32]; % define the mean removal by the PM control 
fg_hg = 1 - fa_hg; 

fa_ratio = [mean(fa_hg) nan nan nan];
fg_ratio = [mean(fg_hg) nan nan nan];

%% calculate element partition 
% determine mass ratios, note that the Otero-Rey data has already been normalized  
ba_ratio_norm = ba_ratio;
fa_ratio_norm = fa_ratio; 
fg_ratio_norm = 1 - fa_ratio_norm; 

% calculate mols of trace elements leaving through the bottom ash. 
bot_trace = ba_ratio_norm.*trace_elem_input; 
% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = fa_ratio_norm.*trace_elem_input;
% subtract off trace elements in the bottom ash and ESP ash from the
% current collection in the flue gas.
stacks_mol = fg_ratio_norm.*trace_elem_input;

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
% bot_error_low = [min(bot_hg) min(bot_se) min(bot_as) min(bot_cl)] - ba_ratio;
% bot_error_high = [max(bot_hg) max(bot_se) max(bot_as) max(bot_cl)] - ba_ratio;
fly_error_low = [min(fa_hg) nan nan nan] - fa_ratio;
fly_error_high = [max(fa_hg) nan nan nan] - fa_ratio;
fg_error_low = [min(fg_hg) nan nan nan] - fg_ratio;
fg_error_high = [max(fg_hg) nan nan nan] - fg_ratio;

% concatenate error matrices together; % normalization does not need to
% take place because the otero-rey matrix are already normalized 
error_matrix = vertcat(zeros(2,4), fly_error_low, ...
    fly_error_high, zeros(4,4), fg_error_low, fg_error_high);

% to check the normalization assumption, run this
% (ba_ratio+fa_ratio+fg_ratio)

end 