function [sankey_matrix, phase_matrix, error_matrix] = ...
    alvarez_ayuso(trace_elem_input)
% ESP measurements taken from Figure 1 
% 100% line is 6.3125 in
% 0% line is 2.2014 in 
% height is 4.1111 in 

% As BA - 2.3333 in (2.3333 - 2.2014)/4.1111 = 0.03
% As FA - 5.9653 in (5.9653 - 2.3333)/4.1111 = 0.9
% Hg BA - blank
% Hg FA - 2.375 in (2.375 - 2.2014)/4.1111 = 0.0422
% Cl BA - blank
% Cl FA - 2.4028 in (2.4028 - 2.2014)/4.1111 = 0.05
% Se BA - 2.4375 in (2.4375 - 2.2014)/4.1111 = 0.06
% Se FA - 4.5417 in (4.5417 - 2.4375)/4.1111 = 0.5

% wFGD measurements
% I calculated the Hg abatement exiting the wFGD by copying Figure 2 into
% adobe illustrator and drawing lines at where each of the bars ended. Here
% is my data:
% The 100 % line 6.2153 in
% Top of the wastewater is 5.0417 in
% Bottom of the wastewater is 4.944 in
% 0 % line is 3.0764 in 
% Therefore, 100% is 3.1389 in 
% the wastewater is 0.0977 in or roughly 3.11% of the total bar
% The gypsum is 4.944 - 3.0764 = 1.8815 in or roughly 59.5% of the total
% bar 
% Therefore, we use 3.1% ww and 59.5% of the gypsum... rest is atmosphere

% for selenium, we use the same method (had to remeasure) 
% 0% line is 2.6667 in 
% 100% line is 5.8333 in
% bottom of wastewater line is 5.7639
% wastewater is 2.19% 
% rest is gypsum. 

% for arsenic, we use the same method
% 100% is 3.1389 in 
% bottom of wastewater is 6.0833 in 
% top of wastewater is 6.1389 in 
% wastewater is 0.0556 in or 1.77% of wFGD waste
% gypsum is 95.79% of wFGD waste 

% for Cl same method 
% 100% is 3.1389 in 
% bottom of wastewater is 3.6042 in. The top of the bar is the 100% line 
% wastewater is 100 - 16.82% = 83.18% of the wFGD waste
% rest is gypsum is 0.5281 in or 16.82% of the wFGD waste

%% boiler / bottom ash splits
% Data from Table 2
ba_ratio = [0 0.06 0.03 0];% define the mean as the partition coefficient 

%% ESP / fly ash splits 
% order of elements is Hg, Se, As, and Cl. 
% As BA - 2.3333 in (2.3333 - 2.2014)/4.1111 = 0.03
% As FA - 5.9653 in (5.9653 - 2.3333)/4.1111 = 0.9
% Hg BA - blank
% Hg FA - 2.375 in (2.375 - 2.2014)/4.1111 = 0.0422
% Cl BA - blank
% Cl FA - 2.4028 in (2.4028 - 2.2014)/4.1111 = 0.05
% Se BA - 2.4375 in (2.4375 - 2.2014)/4.1111 = 0.06
% Se FA - 4.5417 in (4.5417 - 2.4375)/4.1111 = 0.5

fa_ratio = [0.04 0.5 0.9 0.05]; % from Figure 1 measurements 

post_esp = 1 - ba_ratio - fa_ratio;
%% wFGD splits 
% Data from Table 2 
gypsum_abatement = [0.6 0.98 0.96 0.17]; % wFGD removal 
clpurge_abatement = [0.03 0.02 0.02 0.83]; 

gypsum_ratio_norm = post_esp.*gypsum_abatement; 
clpurge_ratio_norm = post_esp.*clpurge_abatement; 

%% calculate element partition 
ba_ratio_norm = ba_ratio;
fa_ratio_norm = fa_ratio; 
fg_ratio_norm = 1 - ba_ratio - fa_ratio - clpurge_ratio_norm - gypsum_ratio_norm; 

% calculate mols of trace elements leaving through the bottom ash. 
bot_trace = ba_ratio_norm.*trace_elem_input; 
% calculate mols of trace elements leaving through the ESP ash. 
esp_ash_mol = fa_ratio_norm.*trace_elem_input;
gypsum = gypsum_ratio_norm.*trace_elem_input; 
cl_purge = clpurge_ratio_norm.*trace_elem_input; 
% subtract off trace elements in the bottom ash and ESP ash from the
% current collection in the flue gas.
stacks_mol = fg_ratio_norm.*trace_elem_input;

%% create three output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

% first output matrix
sankey_matrix = vertcat(bot_trace, esp_ash_mol, gypsum, cl_purge, stacks_mol);  

% second output matrix 
% this assumes that everything exiting the stacks is in the gas phase,
% everything else is in the solid phase 
phase_matrix = zeros(3,4); 
phase_matrix(1,:) = stacks_mol; % gas
phase_matrix(2,:) = gypsum + cl_purge; 
phase_matrix(3,:) = esp_ash_mol + bot_trace; % solid 

% third output matrix - error matrix. This one reports no error. 
error_matrix = zeros(10,4);

% to check the normalization assumption, run this
% (ba_ratio+fa_ratio+fg_ratio)



end 
