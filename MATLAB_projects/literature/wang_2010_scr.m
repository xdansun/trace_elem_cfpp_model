function [sankey_matrix, phase_matrix, err_matrix] = wang_2010_scr
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Wang et al. (2010)
% Title: Mercury emission and speciation of CFPP in China
% Journal: Atmospheric chemistry and physics

%% boiler 
% according to Figure 10 for Wang et al., the removal is close to zero. However, an actual
% measurement is hard to make, so we place as 0 and exclude in the bottom
% removal calculation 
bot_ash_output = [0 nan nan nan];

%% ESP 
% Figure 8, Wang et al. Use plant 1-6
esp_ash_output = [mean([0.37 0.48 0.10 0.06 0.17 0.24]) nan nan nan]; 

%% wFGD 
% Figure 8, Wang et al. Use plant 6
% calculate SCR+wFGD contribution
gypsum_output = [mean(0.36-0.24) nan nan nan]; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
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
