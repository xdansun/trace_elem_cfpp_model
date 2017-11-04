function [sankey_matrix, phase_matrix, err_matrix] = ...
    lee_2006_trace_elem(trace_elem_input)

%% boiler 
% Data obtained from Figure 4, Lee 2006; expanded data is in Table 5 
bot_ash_output = [0.0085 nan nan nan];

%% ESP 
% Data obtained from Figure 4, Lee 2006; expanded data is in Table 5 
esp_ash_output = [0.5835 nan nan nan]; 

%% wFGD 
% Data obtained from Figure 4, Lee 2006; expanded data is in Table 5 
emission_output = [0.2445 nan nan nan];
gypsum_output = [0.0585 nan nan nan]; 
Clpurge_output = [0.006 nan nan nan]; 

%% create two output matrices
% the first output matrix will detail the quantity and where the trace
% element exited out of the cfpp

% the second output matrix will detail the quantity of trace elements
% exiting and the phase of the exiting trace element 

% first output matrix (bot ash, esp, cl purge, gypsum, and stacks in order)
sankey_matrix = vertcat(bot_ash_output, esp_ash_output, gypsum_output,...
    Clpurge_output, emission_output);  
sankey_matrix_orig = sankey_matrix; % create original matrix for later manipulation
for k = 1:4
    sankey_matrix(:,k) = sankey_matrix(:,k)/sum(sankey_matrix(:,k)); 
end 

% second output matrix
phase_matrix = zeros(3,4); % each row is a phase (gas, aqueous, solid) 

phase_matrix(1,:) = sankey_matrix(end,:); % gas 
phase_matrix(2,:) = sankey_matrix(4,:); 
phase_matrix(3,:) = sum(sankey_matrix(1:3,:)); 


%%
% calculate error bars 
% bottom ash low 
bot_err = [0.05 nan nan nan]; 
esp_err = [0.0075 nan nan nan]; 
gypsum_err = [0.0135 nan nan nan]; 
cl_purge_err = [0.0005 nan nan nan]; 
stack_err = [0.0925 nan nan nan]; 

% duplicate error matrix because the bounds from both ends are the same 
err_matrix = vertcat(bot_err, bot_err, esp_err, esp_err, ...
    gypsum_err, gypsum_err, cl_purge_err, cl_purge_err, stack_err, stack_err);
for k = 1:4
    err_matrix(:,k) = err_matrix(:,k)/sum(sankey_matrix_orig(:,k)); 
end 


end 
