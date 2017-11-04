function [sankey_matrix, phase_matrix, err_matrix] = Afonso_2001_ff
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Afonso and Senior (2001) 
% Title: Assessment of mercury emissions from full scale power plants 

%% boiler 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% Table 3, use average of coal types as removal 
esp_ash_output = [82 nan nan nan]*10^-2;

%% SO2 control 
% Table 3, use average of coal types as removal; 
% unfortunately, the measurements for FF + wFGD do not make sense
gypsum_output = [0 nan nan nan]*10^-2; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
Clpurge_output = zeros(1,4); 

emission_output = 1 - bot_ash_output - esp_ash_output - gypsum_output;

%% create two output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

% first output matrix (bot ash, esp, cl purge, gypsum, and stacks in order)
sankey_matrix = vertcat(bot_ash_output, esp_ash_output, gypsum_output,...
    Clpurge_output, emission_output);  

% second output matrix
phase_matrix = zeros(3,4); % each row is a phase (gas, aqueous, solid) 

phase_matrix(1,:) = sankey_matrix(end,:); % gas 
phase_matrix(2,:) = sankey_matrix(4,:); 
phase_matrix(3,:) = sum(sankey_matrix(1:3,:)); 


%% error skipped on this script 

err_matrix = nan; 

end 
