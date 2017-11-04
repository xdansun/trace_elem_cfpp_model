function [sankey_matrix, phase_matrix, error_matrix] = ...
    aunela_tapola_trace_elem(trace_elem_input)
% based on the aunela-tapola 1997 paper 
% two finnish plants 
% apcd setup is ESP into dry FGD with FF 
%% boiler 
% order of elements is Hg, Se, As, and Cl. 
%Data obtained from Table 5; % note that all of these are below the
%detection limit; % in addition, the 
bot_ash_ratio = [5/4100 390/88900 2000/300000 nan];

bot_trace = bot_ash_ratio.*trace_elem_input; %in units of mol/MWh

% in order Hg, Se, As and Cl
%FG_trace_elem = zeros(4,1); %done in mols/hr
% ppm is mg/kg, so mg/kg * kg * 10^-3 / (g/mol)
FG_trace_elem = trace_elem_input - bot_trace;   


%% PM - ESP 
% Trace element removal from flue gas via ESP ash 

% Table 5. Here ESP ash data contains standard deviation measurements 
esp_ash_ratio = [2300/4100 43000/88900 300000/306655 nan]; 
% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = esp_ash_ratio.*trace_elem_input; % mass of trace elem in esp ash

% subtract off trace elements in the ESP ash from the current collection in
% the flue gas. 
FG_trace_elem = FG_trace_elem - esp_ash_mol;

%% SOx - wFGD 
%% Trace element partitioning in emissions, gypsum, and Cl purge
% Data is from Table 5
% order of elements are Hg, Se, and As. 
fgd_ratio = [430/4100 40000/88900 4900/306655 nan];
fgd_mol = fgd_ratio.*FG_trace_elem;

FG_trace_elem = FG_trace_elem - fgd_mol; 

%% Calculate trace elements phase allocation exiting the stacks
% Data obtained from Table 5 Aunela-Tapola 
% Order of elements are Hg, Se, and As. 
stacks_particulate = [52 18 55 nan];
stacks_vapor = [1300 5900 1700 nan];
% calculate the ratio of in over out to determine partitioning. Though the
% ratios are done in mass, they should be the same ratio since the ratio of
% the molar weights should equal one. 
FGD_ratio_vapor = stacks_vapor./(stacks_vapor + stacks_particulate);
FGD_ratio_part = 1 - FGD_ratio_vapor;

% split gases entering stacks based on the ratio. 
trace_elem_vapor = FGD_ratio_vapor.*FG_trace_elem;
trace_elem_PM = FGD_ratio_part.*FG_trace_elem;

%% create two output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

trace_elem_Clpurge_mol = zeros(1,4); 
% first output matrix
sankey_matrix = vertcat(bot_trace, esp_ash_mol, trace_elem_Clpurge_mol, ...
    fgd_mol, FG_trace_elem);  

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