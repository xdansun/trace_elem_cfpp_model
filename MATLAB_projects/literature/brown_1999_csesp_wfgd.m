function [sankey_matrix, phase_matrix, err_matrix] = brown_1999_csesp_wfgd
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Brown et al. 1999
% Title: Mercury Measurement and Its Control: What We Know, Have Learned, and Need to Further Investigate
% Journal: Journal of Air and Waste management association 

%% boiler 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% Figure 25
esp_ash_output = [mean([0 60 25 30 35]) nan nan nan]*10^-2;

%% SO2 control 
% Data from Table 14
% Note that Figure 5 and 8 also have data, but they assume that all Hg
% particulate matter is removed. This may be an okay assumption, but given
% data elsewhere in the paper, we opted not to use it. 
% Additionally, this script assumes that the controls preceding this study
% are csESPs 
fgd_removal = [49.7 65.0 37.8 48 58 45.9 57 5 3.5]*10^-2; % subtract off csesp, hsesp, and ff contribution in removal 
gypsum_output = [mean(fgd_removal) nan nan nan]; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
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
