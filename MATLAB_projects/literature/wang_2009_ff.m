function [sankey_matrix, phase_matrix, err_matrix] = wang_2009_ff
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Wang et al. (2009)
% Title: Experimental study on mercury transformation and removal in
% coal-fired boiler flue gases 
% Journal: Atmospheric chemistry and physics

%% boiler 
% No data, but use a zero for convenience.  
bot_ash_output = [0 nan nan nan];

%% ESP 
% Figure 2, Wang et al. Plants 1-2; Add up the input, add up the output,
% that ratio is the emissions fraction. 1 minus gives the esp_ash_output
inlet = [4+11+12 14+15+1]; 
outlet = [1+4 7+21]; % this assumes that the flue gas is constant 
fly_ash_output = [1 - mean(outlet./inlet) nan nan nan];

%% wFGD 
% Although plants in this study have wFGDs, there is no FGD data  
gypsum_output = [0 nan nan nan]; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
Clpurge_output = zeros(1,4); 

emission_output = 1 - bot_ash_output - fly_ash_output - gypsum_output;

%% create two output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

% first output matrix (bot ash, esp, cl purge, gypsum, and stacks in order)
sankey_matrix = vertcat(bot_ash_output, fly_ash_output, gypsum_output,...
    Clpurge_output, emission_output);  

% second output matrix
phase_matrix = zeros(3,4); % each row is a phase (gas, aqueous, solid) 

phase_matrix(1,:) = sankey_matrix(end,:); % gas 
phase_matrix(2,:) = sankey_matrix(4,:); 
phase_matrix(3,:) = sum(sankey_matrix(1:3,:)); 


%% error skipped on this script 
% calculate error bars 
% bottom ash low 
% bot_err = [0.05 nan nan nan]; 
% esp_err = [0.0075 nan nan nan]; 
% gypsum_err = [0.0135 nan nan nan]; 
% cl_purge_err = [0.0005 nan nan nan]; 
% stack_err = [0.0925 nan nan nan]; 

% duplicate error matrix because the bounds from both ends are the same 
% err_matrix = vertcat(bot_err, bot_err, esp_err, esp_err, ...
%     gypsum_err, gypsum_err, cl_purge_err, cl_purge_err, stack_err, stack_err);
% for k = 1:4
%     err_matrix(:,k) = err_matrix(:,k)/sum(sankey_matrix_orig(:,k)); 
% end 

err_matrix = nan; 

end 
