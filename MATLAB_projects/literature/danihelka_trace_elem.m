function [sankey_matrix, phase_matrix, error_matrix] = ...
    danihelka_trace_elem(trace_elem_input)
% based on the Danihelka 2003 paper 
% Czech power plants ranging from 50-150 MW. Ignore the 6th experiment,
% since it is not connected to an ESP. 
% Assume 20/80 bottom ash vs fly ash split 
global bot_ash_frac; 

%%
% data from Table 3 
% ash_frac = 100*ones(1,5); 
% assume 1 kg of coal  
hg_in = [0.052 0.027 0.135 0.03 0.029]*10^-3; % in mg
se_in = [1.2 1.0 1.0 1.5 0.9]*10^-3; % in mg
as_in = [2.6 2 23.1 1.1 1.7]*10^-3; % in mg

ash_frac = [12.9 12.7 17.8 15.5 11.9]/100; % kg of ash 

% data from Table 4; bottom ash 
hg_bot = [0.002 0.002 0.008 0.004 0.004]; % ppm
se_bot = [0.5 0.8 0.8 0.8 1]; % ppm 
as_bot = [1.2 4.7 10.8 1.1 4.9]; % ppm

% data from Table 4; fly ash 
hg_fly = [0 0.231 0.013 0.24 0.163]; % ppm
se_fly = [2 6.6 4 7.3 7.9]; % ppm
as_fly = [9 10.9 46.6 10 5.3]; % ppm

bot_ash = ash_frac*bot_ash_frac; 
fly_ash = ash_frac*(1-bot_ash_frac); 

% calculated values 
hg_stack = hg_in - hg_bot.*bot_ash*10^-3 - hg_fly.*fly_ash*10^-3 % in mg
hg_stack./hg_in
hg_fly.*fly_ash*10^-3./hg_in
%%
se_stack = se_in - se_bot.*bot_ash*10^-3 - se_fly.*fly_ash*10^-3
se_stack./se_in

%%
as_stack = as_in - as_bot.*bot_ash*10^-3 - as_fly.* fly_ash*10^-3
as_stack./as_in

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