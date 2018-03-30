function [output_cell, study_name, apcd_combo] = karlsson_1984_dFGD
% This function calculates the partitioning coefficients based on the
% empirical data presented in the Karlsson 1984 piece. "Spray dry scrubbing
% of secondary pollutants from coal burning"

%% define study name and air pollution control combination
study_name = 'Karlsson (1984)'; 
apcd_combo = 2400; 

%% boiler 
bot_ash_output = [0 0 0 0]; % data is not reported here, set to zero 

%% ESP 
% Data is on page 248, where "At 127 ppm HCl inlet concentration, removal
% efficiency reaches 97%"
% although the range of HCl removal varies, this 97% corroborates with
% EPA's modeling assumptions about HCl in dFGDs and is similar to HCl's
% removal in wFGDs 
esp_ash_output = [nan nan nan 0.97];

%% wFGD 
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