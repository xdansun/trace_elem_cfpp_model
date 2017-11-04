function [sankey_matrix, phase_matrix, error_matrix] = ...
    pavlish_csesp(trace_elem_input)
% see Pavlish et al., 2003, Fuel Processing Technology. Status review of
% mercury control options for CFPPs 
% multiple sources are presented in the paper. We opted to aggregate all
% the data into a single point estimate, given we did not have access to
% the original data. Future adoption would separate out these three conference 
% papers. It is not clear how Pavlish dervied numeric values from the
% conference papers. 

% this script reflects csESP controls 
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

% This function handles the electrostatic precipitator. Can support other
% apcd combinations... would have to implement in separate scripts 
%  
%% boiler 
% order of elements is Hg, Se, As, and Cl. 
% Data obtained from Table 3; 
bot_ash_ratio = [0 nan nan nan]; % not reported

bot_trace = bot_ash_ratio.*trace_elem_input; 
FG_trace_elem = trace_elem_input - bot_trace;   

%% PM - ESP 
% Trace element removal from flue gas via ESP ash 

% Table 3. Here ESP ash data contains standard deviation measurements 
esp_ash_ratio = [median([27 32 39])/100 nan nan nan];
% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = esp_ash_ratio.*trace_elem_input; % mass of trace elem in esp ash

%% wFGD 
wfgd_ratio = [median([22 25 34])/100 nan nan nan]; % from Table 3. Take the difference of ESP cold and ESP cold + FGD wet 
wfgd_mol = wfgd_ratio.*trace_elem_input; % assume everything is entering the solid phase 

%% Stacks 
% split gases entering stacks based on the ratio. 
stacks_ratio = ones(1,4) - bot_ash_ratio - esp_ash_ratio; 
stacks_mol = stacks_ratio.*trace_elem_input; 
trace_elem_vapor = stacks_mol; 
%% create two output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

trace_elem_Clpurge_mol = zeros(1,4); 
trace_elem_gypsum = wfgd_mol; 
% first output matrix
sankey_matrix = vertcat(bot_trace, esp_ash_mol, trace_elem_Clpurge_mol, ...
    trace_elem_gypsum, stacks_mol);  

% second output matrix
phase_matrix = zeros(3,4); % each row is a phase (gas, aqueous, solid) 
phase_matrix(1,:) = trace_elem_vapor; 
phase_matrix(3,:) = trace_elem_input - trace_elem_vapor; 


%% create error matrices 
bot_error_low = [0 0 0 0];
bot_error_high = [0 0 0 0];
fly_error_low = [0.27 0 0 0] - esp_ash_ratio;
fly_error_high = [0.39 0 0 0] - esp_ash_ratio;
gypsum_error_low = [0.22 0 0 0] - wfgd_ratio;
gypsum_error_high = [0.34 0 0 0] - wfgd_ratio;
fg_error_low = [0 0 0 0];
fg_error_high = [0 0 0 0];

error_matrix = vertcat(bot_error_low, bot_error_high, fly_error_low, ...
    fly_error_high, gypsum_error_low, gypsum_error_high, zeros(2,4),...
    fg_error_low, fg_error_high);
end 