function [sankey_matrix, phase_matrix, error_matrix] = ...
    meij_2007_trace_elem(trace_elem_input)
% based on the Meij 2007 paper 
% apcd setup is SCR, ESP, and wFGD

%% boiler 
% determine bottom ash trace element ratio 
% no bottom ash ratios were given 
% bot_ash_ratio = [nan nan nan nan];
bot_ash_ratio = [0 0 0 0];

bot_trace = bot_ash_ratio.*trace_elem_input; %in units of mol/MWh

% in order Hg, Se, As and Cl
%FG_trace_elem = zeros(4,1); %done in mols/hr
% ppm is mg/kg, so mg/kg * kg * 10^-3 / (g/mol)
% FG_trace_elem = trace_elem_input - bot_trace;   
    
%% PM - ESP 
% Trace element removal from flue gas via ESP ash 
% FG_trace_elem = trace_elem_vapor + trace_elem_PM; 
% Given that the coal feed rate is same, the ratio of the input coal and
% the esp ash output should calculate how much esp in mass there
% should be. 

esp_ash_ratio = [0.496 0.824 0.983 0.009]; 
% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = esp_ash_ratio.*trace_elem_input; % mass of trace elem in esp ash

%% SOx - wFGD 
% for trace elements Hg, Se, As, and Cl 
% data from Table 7 
wFGD_removal = [0.8 0.656 0.75 0.95]; % this is the wFGD removal of the flue gas exiting the ESP 
gypsum_ratio = (1 - esp_ash_ratio).*wFGD_removal; % assume everything is solids. Correct to liquids later 
emission_ratio = 1 - gypsum_ratio - esp_ash_ratio;
%% Trace element partitioning in emissions, gypsum, and Cl purge
% unfortunately in Table 7 of Meij (2007), we are not told the ratio of wet
% to dry ratio. 
trace_elem_Clpurge_mol = zeros(1,4); 
trace_elem_stacks_mol = emission_ratio.*trace_elem_input;
trace_elem_gypsum_mol = gypsum_ratio.*trace_elem_input; % mass of trace elem in gypsum

%% create two output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

trace_elem_vapor = trace_elem_stacks_mol;

% first output matrix
sankey_matrix = vertcat(bot_trace, esp_ash_mol, trace_elem_gypsum_mol, ...
    trace_elem_Clpurge_mol, trace_elem_stacks_mol);  

% second output matrix
phase_matrix = zeros(3,4); % each row is a phase (gas, aqueous, solid) 
phase_matrix(1,:) = trace_elem_vapor; 
phase_matrix(3,:) = trace_elem_input - trace_elem_vapor; 

%% create error matrix
% all errors are zero because Meij paper does not indicate what the
% error bars are
error_matrix = zeros(10,4); 

end 
