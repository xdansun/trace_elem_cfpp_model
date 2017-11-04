function [output_cell, study_name, apcd_combo] = ondov_trace_elem
% This function calculates the partitioning coefficients based on the
% empirical data presented in the Ondov 1979 paper 

%% define study name and air pollution control combination
study_name = 'Ondov et al. (1979)'; 
apcd_combo = 1100; 

%% boiler 
bot_ash_output = [0 0 0 0]; % data is not reported here, set to zero 

%% ESP 
% Data from Table VI, order is %Hg, Se, As, and Cl 
esp_ash_penetration = [nan median([3.8,8.1]), median([4.3,11.5]) 100]/100; 
esp_ash_output = 1 - esp_ash_penetration;

%% wFGD 
% Data obtained from Table VI
wfgd_penetration = [nan median([10,21]), median([2.5,7.5]), median([0.54,6.7])]/100; 
wfgd_output = esp_ash_penetration.*(1-wfgd_penetration);

gypsum_output = wfgd_output; % assume everything is a solid, wastewater ratios from other studies will be applied later 
Clpurge_output = zeros(1,4); 

%% calculate stacks 
emission_output = 1.*esp_ash_penetration.*wfgd_penetration; 

%% calculate partition fractions
% partitioning coefficient exiting different apcd
% equipments (bot ash, esp, cl purge, gypsum, and stacks in order)
partition_by_apc = vertcat(bot_ash_output, esp_ash_output, gypsum_output,...
    Clpurge_output, emission_output);  
for k = 1:4 % for each trace element 
    % normalize the partition coefficient based on the total output 
    partition_by_apc(:,k) = partition_by_apc(:,k)/sum(partition_by_apc(:,k)); 
end 

%% format output 
output_cell = {study_name, apcd_combo, partition_by_apc(1,:), partition_by_apc(2,:), partition_by_apc(3,:), ...
    partition_by_apc(4,:), partition_by_apc(5,:)};

end 