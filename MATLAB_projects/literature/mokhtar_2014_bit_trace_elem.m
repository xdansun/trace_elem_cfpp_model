function [sankey_matrix, phase_matrix, error_matrix] = ...
    mokhtar_2014_bit_trace_elem(trace_elem_input)
% paper is based on Mokhtar et al 2014 
% Journal of air and waste management association 
% because Hg, Se, and As were not detected in this study, it is largely
% useless 

% air pollution employed are a cold-side ESP and a wet FGD, but the paper
% does not report wFGD waste streams 

% the paper has measurements for both bituminous and subbituminous.
% Therefore, two separate files were made ... one for bituminous, and the
% other for subbittuminous 

% Relative enrichment factor (RE) = (element concentration in ash)
    %/(element concentration in coal)*(% ash content in coal)/100
% therefore, the element concentration in ash is
    % RE*(element concentration in coal)*(100/(%ash content in coal))
% or 
% element concentration in ash = 
    % RE*(element concentration in coal)/(ash content in coal)

% this function assumes trace_elem_input = [1 1 1 1]
    
%%
global bot_ash_frac

%%
ash_in_coal = mean([12.5 12.5 12.3])/100; % fraction of ash in coal 
% order is Hg, Se, As, and Cl in ppm (mg/kg)
coal_in = [nan nan nan 78.11]; % we assume that non-detects are nan. If we assumed otherwise, everything would be zero 
%% boiler
% bottom ash splits
% data is from Table 10 in Otero-Rey 
%Hg, Se, As, and Cl partitioning
bot_ash_conc = [nan nan nan 44.95]; %the other trace elements are not included because they all record less than the detection limits 
% bot_ash_conc is mg/kg in bottom ash 
% bottom ash content calculated by 1kg coal * ash_in_coal * bot_ash_frac 
% coal_in is mg/kg in coal so coal_in*1000 g is ug
bot_ash_frac = 0.2; 
bot_ash_ratio = bot_ash_conc*ash_in_coal*bot_ash_frac./coal_in;

bot_trace = bot_ash_ratio.*trace_elem_input; % mol As in bottom ash/ mol As in coal 
% note that kg As / kg As is the same as mol As / mol As 

%% ESP
% order of elements is Hg, Se, As, and Cl. 
% data from Table 10 
fly_ash_conc = [nan nan nan 53.85];
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
bot_error_low = [0 0 0 0];
bot_error_high = [0 0 0 0];
fly_error_low = [0 0 0 0];
fly_error_high = [0 0 0 0];
fg_error_low = [0 0 0 0];
fg_error_high = [0 0 0 0];

error_matrix = vertcat(bot_error_low, bot_error_high, fly_error_low, ...
    fly_error_high, zeros(4,4), fg_error_low, fg_error_high);

end 