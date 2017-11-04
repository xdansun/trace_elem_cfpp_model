function [sankey_matrix, phase_matrix, error_matrix] = ...
    guo_trace_elem(trace_elem_input)
% based on the Guo 2004 and 2007 paper
% Guo 2004: Characterization of arsenic emissions from a coal-fired power
% plant; Energy and Fuels
% doi: 10.1021/ef049921b
% Guo 2007: Characterization of Mercury Emissions from a Coal-Fired Power
% Plant; Energy and Fuels
% doi: 10.1021/ef060157y


%% boiler 
% order of elements is Hg, Se, As, and Cl. 
% Data obtained from Table 3; The calculation is total = slag + inlet fly
% ash + atmospheric discharge
% the partition ratio is outfall/total 
% define total outfall mass flows 
hg_tot = 0.01 + 0.13 + 0.86;
as_tot = 0.0053 + 0.846 + 0.0216; % note that there are two As isotopes 

bot_ash_ratio = [0.01/hg_tot 0.0053/as_tot nan nan];

bot_trace = bot_ash_ratio.*trace_elem_input; 
FG_trace_elem = trace_elem_input - bot_trace;   

%% PM - ESP 
% Trace element removal from flue gas via ESP ash 

% Table 5. Here ESP ash data contains standard deviation measurements 
esp_ash_ratio = [0.13/hg_tot 0.846/as_tot nan nan];
% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = esp_ash_ratio.*trace_elem_input; % mass of trace elem in esp ash

% subtract off trace elements in the ESP ash from the current collection in
% the flue gas. 
FG_trace_elem = FG_trace_elem - esp_ash_mol;

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
trace_elem_gypsum = zeros(1,4); 
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
fly_error_low = [0 0 0 0];
fly_error_high = [0 0 0 0];
fg_error_low = [0 0 0 0];
fg_error_high = [0 0 0 0];

error_matrix = vertcat(bot_error_low, bot_error_high, fly_error_low, ...
    fly_error_high, zeros(4,4), fg_error_low, fg_error_high);
end 