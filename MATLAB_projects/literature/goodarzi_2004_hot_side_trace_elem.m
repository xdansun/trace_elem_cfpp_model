function [sankey_matrix, phase_matrix, error_matrix] = ...
    goodarzi_2004_hot_side_trace_elem(trace_elem_input)
% Refer to Cheng_ESP for guidance on finishing the remainder of the ESP
% code. 

% Goodarzi in 2004 studies a CFPP paper studies an ESP with capacity
% ranging from 3.87 to 13.83 million MW
% this function assumes trace_elem_input = [1 1 1 1]

% the sixth station Goodarzi measures is linked to a hot-side ESP. HS-ESPs
% have been placed into a separate script away from the CS-ESPs.
    
%% boiler
% bottom ash splits
%Hg, Se, As, and Cl partitioning
bot_hg = 0.12; 
bot_ash_conc = [mean(bot_hg) nan nan nan]; %detection limits 
% bot_ash_conc is mg/kg in bottom ash 
% bottom ash content calculated by 1kg coal * ash_in_coal * bot_ash_frac 
% coal_in is mg/kg in coal so coal_in*1000 g is ug

%% ESP
% order of elements is Hg, Se, As, and Cl. 
fly_hg = 0.126; 
fly_ash_conc = [mean(fly_hg) nan nan nan];

%% stacks
% calculate trace element exiting stacks, order is Hg, Se, As, and Cl 
stack_hg = [6.95]; 
stack_conc = [mean(stack_hg) nan nan nan];

%% calculate trace element partitioning 
bot_ash_ratio = bot_ash_conc./(bot_ash_conc + fly_ash_conc + stack_conc); 
fly_ash_ratio = fly_ash_conc./(bot_ash_conc + fly_ash_conc + stack_conc); 
stack_ratio = 1 - bot_ash_ratio - fly_ash_ratio; 

bot_trace = bot_ash_ratio.*trace_elem_input; % mol As in bottom ash/ mol As in coal 
% note that kg As / kg As is the same as mol As / mol As 

% calculate esp ash 
esp_ash_mol = fly_ash_ratio.*trace_elem_input;

trace_elem_stacks_mol = trace_elem_input - bot_trace - esp_ash_mol;

%%
% make empty fgd matrices 
% the final results contain fgd exit streams, but this source only contains
% esp data, so we set fgd values to zero 
cl_purge = zeros(1,4); 
gypsum = zeros(1,4); 


%% create two output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

% first output matrix
sankey_matrix = vertcat(bot_trace, esp_ash_mol, cl_purge, gypsum, trace_elem_stacks_mol);  

% the issue with the phase matrix is that there is no phase partitioning
% data in Otero-Rey... that will have to be built elsewhere 
phase_matrix = zeros(3,4); 
phase_matrix(1,:) = trace_elem_stacks_mol; 
phase_matrix(3,:) = esp_ash_mol; 

%% create error matrices 
bot_error_low = [min(bot_hg) nan nan nan]./(min(bot_hg) + fly_ash_conc + stack_conc)...
    - bot_ash_ratio;
bot_error_high = [max(bot_hg) nan nan nan]./(max(bot_hg) + fly_ash_conc + stack_conc)...
    - bot_ash_ratio;
fly_error_low = [min(fly_hg) nan nan nan]./(bot_ash_conc + min(fly_hg) + stack_conc)...
    - fly_ash_ratio;
fly_error_high = [max(fly_hg) nan nan nan]./(bot_ash_conc + max(fly_hg) + stack_conc)...
    - fly_ash_ratio;
fg_error_low = [min(stack_hg) nan nan nan]./(bot_ash_conc + fly_ash_conc + min(stack_hg))...
    - stack_ratio;
fg_error_high = [max(stack_hg) nan nan nan]./(bot_ash_conc + fly_ash_conc + max(stack_hg))...
    - stack_ratio;

error_matrix = abs(vertcat(bot_error_low, bot_error_high, fly_error_low, ...
    fly_error_high, zeros(4,4), fg_error_low, fg_error_high));

end 