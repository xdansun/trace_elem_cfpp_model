function [output_cell, study_name, apcd_combo] = laird_trace_elem_dsi
% This function calculates the partitioning coefficients based on the
% empirical data presented in the Laird et al. piece. "Results of DSI
% testing to reduce HCl"
% http://www.carmeusena.com/sites/default/files/brochures/flue-gas-treatment/tp-mega-symp-paper107.pdf

%% define study name and air pollution control combination
study_name = 'Laird et al. (2013)'; % determined date by inspecting the last date modified on the pdf 
apcd_combo = 4000; 

%% boiler 
bot_ash_output = [0 0 0 0]; % data is not reported here, set to zero 

%% ESP 
% Data is from Table 2, Table 4, and Table 6
% order is %Hg, Se, As, and Cl 
esp_ash_output = [nan nan nan mean([0.917 0.989 0.9996 0.969 0.969 0.71 0.78 0.64 0.84 0.77])];

%% wFGD 
% Data obtained from Table VI
wfgd_output = [nan nan nan nan]; 

gypsum_output = wfgd_output; % assume everything is a solid, wastewater ratios from other studies will be applied later 
Clpurge_output = zeros(1,4); 

%% calculate stacks 
emission_output = 1 - esp_ash_output; 

%% calculate partition fractions
% partitioning coefficient exiting different apcd
% equipments (bot ash, esp, cl purge, gypsum, and stacks in order)
partition_by_apc = vertcat(bot_ash_output, esp_ash_output, gypsum_output,...
    Clpurge_output, emission_output);  
for k = 1:4 % for each trace element 
    % normalize the partition coefficient based on the total output 
    partition_by_apc(:,k) = partition_by_apc(:,k)/sum(partition_by_apc(:,k),'omitnan'); 
end 

%% format output 
output_cell = {study_name, apcd_combo, partition_by_apc(1,:), partition_by_apc(2,:), partition_by_apc(3,:), ...
    partition_by_apc(4,:), partition_by_apc(5,:)};

end 