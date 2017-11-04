function [sankey_matrix, phase_matrix, err_matrix] = srivastava_2006_csesp_wfgd
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Srivastava et al. (2006) 
% Title: Control of mercury emissions from coal-fired electric utility boilers
% Journal: ES&T

%% boiler 
% Data in Table 4, but we use zero because data before the ESP is not
% useful 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% Table 1, use average of coal types as removal 
esp_ash_output = [(4*29+3*3+1*0)/8 nan nan nan]*10^-2;

%% SO2 control 
% Table 1, use average of coal types as removal; Note 40, 13, and 42 come
% from 69 - 29 = 40, 16 - 3 = 13, and 42 - 0 = 42; 
% for subbituminous, 39 - 11 = 28 and 8 - 0 = 8
% Also, combine wFGD removals for csESP and hsESP upstream together 
gypsum_output = [(2*40+3*13+2*42)/7 nan nan nan]*10^-2; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
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
