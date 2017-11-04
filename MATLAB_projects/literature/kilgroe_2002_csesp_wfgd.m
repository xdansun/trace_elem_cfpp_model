function [sankey_matrix, phase_matrix, err_matrix] = kilgroe_2002_csesp_wfgd
%% Script description 
% contains removal/partitioning data of trace elements (TE) from 
% Kilgroe et al. (see citation from Kolker Applied Geochemistry 2006 for Kilgroe citation) 
% Title: Control of mercury emissions from coal-fired electric utility boilers: Interim report including errata dated 03-21-02
% Journal: EPA report

%% boiler 
bot_ash_output = [0 nan nan nan]*10^-2;

%% PM control
% Table ES-1 of Kilgroe et al. 
esp_ash_output = [mean([0.36 0.03 -0.04]) nan nan nan];

%% SO2 control 
% Table ES-1
fgd_removal = [75-36 29-3 44]; % subtract off csesp, hsesp, and ff contribution in removal 
gypsum_output = [mean(fgd_removal) nan nan nan]*10^-2; % assume all of it goes into solids; ww_ratio from other scripts will assume a percentage enters water
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

err_matrix = nan; 

end 
