function [sankey_matrix, phase_matrix, error_matrix] = ...
    brekke_1995(trace_elem_input)
% This function handles the baghouse... can be modified to include other
% APCs 
% Based on the paper: Brekke 1995 Comparison  of  hazardous  air
% pollutants  from  advanced  conventional  power  systems. In: 12th
% Annual  International Pittsburgh Coal Conference, Pittsburgh,
% Pennsylvania, USA.
% https://digital.library.unt.edu/ark:/67531/metadc621107/m2/1/high_res_d/137325.pdf


%% boiler
% bottom ash splits
bot_ash_ratio = [nan nan nan nan];

bot_trace = bot_ash_ratio.*trace_elem_input; %in units of mol/MWh

% calculate trace elem leaving boiler / entering ESP 
fg_trace_elem = trace_elem_input - bot_trace; 

%% ESP
% data from Figure 3
fly_as_avg = nan;
fly_hg_avg = 0.60;
fly_se_avg = 0.65;
fly_cl_avg = nan; % for chlorine, there's only a single data point 

fa_ratio_norm = [fly_hg_avg fly_se_avg fly_as_avg fly_cl_avg];

%% calculate element partition 
% determine mass ratios 
% the total amount of ash that enters the ESP is everything that leaves as
% fly ash from the boiler. ESP Ash is called fly ash 
fg_ratio_norm = 1 - fa_ratio_norm; 

% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = fa_ratio_norm.*fg_trace_elem;
% subtract off trace elements in the ESP ash from the current collection in
% the flue gas. 
trace_elem_stacks_mol = fg_trace_elem - esp_ash_mol;

%% so2 control
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
sankey_matrix = vertcat(bot_trace, fa_ratio_norm, cl_purge, gypsum, fg_ratio_norm);  

phase_matrix = zeros(3,4); 
phase_matrix(1,:) = trace_elem_stacks_mol; 
phase_matrix(3,:) = esp_ash_mol; 

%% create error matrix
% no error bar. Not sure what uncertainty range is 
error_matrix = zeros(10,4); 
end 