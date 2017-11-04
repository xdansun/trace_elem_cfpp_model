function partition_by_apcd = cheng_trace_elem
% based on the cheng 2009 paper 
% apcd setup is SCR, ESP, and wFGD
% the mass balance of cheng 2009 is not complete. There are more trace 
% elements in the inputs than the outputs, so the partition coefficients
% will be normalized based on the outputs 

%% boiler 
% Data obtained from Table 11, Cheng et al 2009
% fractions are in ug/kg except for Cl which is in mg/kg 
econ_ash_ratio = [0.1 164 143 4.3];
%Data obtained from Table 11, Cheng et al 2009
bot_ash_ratio = [0.2 290 240 1.7];
% assume all of the econ ash goes into the bot ash 
bot_ash_output = econ_ash_ratio + bot_ash_ratio;

%% ESP 
% Data obtained from Table 11, Cheng et al 2009
esp_ash_output = [16 3700 5300 34]; 

%% wFGD 
% Data obtained from Table 11, Cheng et al 2009
emission_output = [4.09 340 1.0 17];
gypsum_output = [64 2000 300 22.4]; 
Clpurge_output = [8 84 0.259 1325]; 

%% create three output matrices
% partitioning coefficient exiting different apcd
% equipments (bot ash, esp, cl purge, gypsum, and stacks in order)
partition_by_apcd = vertcat(bot_ash_output, esp_ash_output, gypsum_output,...
    Clpurge_output, emission_output);  
for k = 1:4 % for each trace element 
    % normalize the partition coefficient based on the total output 
    partition_by_apcd(:,k) = partition_by_apcd(:,k)/sum(partition_by_apcd(:,k)); 
end 

end 