function [sankey_matrix, phase_matrix, error_matrix] = ...
    zhu_trace_elem(trace_elem_input)
% This function calculates the partitioning coefficients based on the
% empirical data presented in the paper. This paper is the baseline for
% plants with just ESP. 
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

% This function handles the electrostatic precipitator. Tables also support
% ESP, ESP+wFGD, and FF, if desired 
% Zhu Journal of Cleaner Production 2016 
% DOI: 10.1021/es020949g

%% boiler / bottom ash splits
% Data from Table 2
ba_ratio = [nan nan nan nan];% define the mean as the partition coefficient 

%% ESP / fly ash splits 
% order of elements is Hg, Se, As, and Cl. 
% Data from table 2
fa_ratio = [33.17 73.78 86.20 nan]; % define the mean as the partition coefficient 

%% wFGD splits 
% Data from Table 2 
wfgd_ratio = [71.41 97.29 93.41 nan] - fa_ratio; % wFGD removal 

%% calculate element partition 
% determine mass ratios, note that the Otero-Rey data has already been normalized  
ba_ratio_norm = zeros(1,4);
fa_ratio_norm = fa_ratio/100; 
gypsum_ratio_norm = wfgd_ratio/100; 
fg_ratio_norm = 1 - ba_ratio_norm - fa_ratio_norm - gypsum_ratio_norm; 

% calculate mols of trace elements leaving through the bottom ash. 
bot_trace = ba_ratio_norm.*trace_elem_input; 
% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = fa_ratio_norm.*trace_elem_input;
gypsum = gypsum_ratio_norm.*trace_elem_input; 
% subtract off trace elements in the bottom ash and ESP ash from the
% current collection in the flue gas.
stacks_mol = fg_ratio_norm.*trace_elem_input;

%% make empty fgd matrices 
% the final results in other parts of the analysis contain fgd exit
% streams, but this source only contains esp data, so set fgd values to zero
cl_purge = zeros(1,4); 

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
phase_matrix(2,:) = gypsum + cl_purge; 
phase_matrix(3,:) = esp_ash_mol + bot_trace; % solid 

% third output matrix - error matrix. This one reports no error. 
error_matrix = zeros(10,4);

% to check the normalization assumption, run this
% (ba_ratio+fa_ratio+fg_ratio)

end 