function [sankey_matrix, phase_matrix, error_matrix] = ...
    mokhtar_2014_trace_elem(trace_elem_input)
% Refer to Cheng_ESP for guidance on finishing the remainder of the ESP
% code. 

% This function handles the fabric filter
% It is based on the paper by Shah et al. (2008)
% Speciation of As, Cr, Se, and Hg under coal fired power station
% conditions
% DOI: 10.1016/j.fuel.2007.12.001

% Relative enrichment factor (RE) = (element concentration in ash)
    %/(element concentration in coal)*(% ash content in coal)/100
% therefore, the element concentration in ash is
    % RE*(element concentration in coal)*(100/(%ash content in coal))
% or 
% element concentration in ash = 
    % RE*(element concentration in coal)/(ash content in coal)

% this function assumes trace_elem_input = [1 1 1 1]
    
%%
ash_in_coal = mean([0.268; % fraction of ash in coal 
% order is Hg, Se, As, and Cl in ppm (mg/kg)
coal_in = [0.052 1.3 2.5 nan]; 
bot_ash_frac = 0.2; % fraction of coal ash that becomes bottom ash 

%% boiler
% bottom ash splits
% data is from Table 10 in Otero-Rey 
%Hg, Se, As, and Cl partitioning
bot_ash_conc = [0.0094 0.2 0.2 nan]; %detection limits 
% bot_ash_conc is mg/kg in bottom ash 
% bottom ash content calculated by 1kg coal * ash_in_coal * bot_ash_frac 
% coal_in is mg/kg in coal so coal_in*1000 g is ug
bot_ash_ratio = bot_ash_conc*ash_in_coal*bot_ash_frac./coal_in;

bot_trace = bot_ash_ratio.*trace_elem_input; % mol As in bottom ash/ mol As in coal 
% note that kg As / kg As is the same as mol As / mol As 

%% ESP
% order of elements is Hg, Se, As, and Cl. 
% data from Table 10 
fly_ash_conc = [0.0124 4.1 5.4 nan];
fly_ash_ratio = fly_ash_conc*ash_in_coal*(1-bot_ash_frac)./coal_in;

% calculate esp ash 
esp_ash_mol = fly_ash_ratio.*trace_elem_input;

%% calculate element partition 
% calculate trace element entering stacks 
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
% 
bot_error_low = [min(bot_hg) min(bot_se) min(bot_as) min(bot_cl)] - bot_ash_ratio;
bot_error_high = [max(bot_hg) max(bot_se) max(bot_as) max(bot_cl)] - bot_ash_ratio;
fly_error_low = [min(fly_hg) min(fly_se) min(fly_as) min(fly_cl)] - fly_ash_ratio;
fly_error_high = [max(fly_hg) max(fly_se) max(fly_as) max(fly_cl)] - fly_ash_ratio;
fg_error_low = [min(fg_hg) min(fg_se) min(fg_as) min(fg_cl)] - fg_ratio;
fg_error_high = [max(fg_hg) max(fg_se) max(fg_as) max(fg_cl)] - fg_ratio;

error_matrix = vertcat(bot_error_low, bot_error_high, fly_error_low, ...
    fly_error_high, zeros(4,4), fg_error_low, fg_error_high);

end 