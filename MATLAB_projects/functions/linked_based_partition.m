function [pm_removal, so2_removal] = linked_based_partition(lit_partition_US)

% calculate partition based on linked based approach 
%
% input:
% lit_partition_US (cell) - list of studies with their air pollution
% control code and the partitioning of each trace element by each unit
% (boiler, particulate matter control, sulfur dioxide control) installed 
% after the boiler 
%
% output:
% pm_removal (cell) - partitioning of each trace element by the particulate
% matter control for each study
% so2_removal (cell) - partitioning of each trace element by the sulfur
% dioxide control for each study


%%
% for pm removal 
pm_removal = lit_partition_US(:,1:2); 
for i = 1:size(pm_removal,1)
    pm_removal{i,3} = lit_partition_US{i,3} + lit_partition_US{i,4}; % add boiler and PM removal together 
end 

% for so2 removal 
so2_removal = lit_partition_US(:,1:2); 
for i = 1:size(so2_removal,1)
    wfgd = lit_partition_US{i,5} + lit_partition_US{i,6}; % trace elements removed by wFGD 
    tot = lit_partition_US{i,5} + lit_partition_US{i,6} + lit_partition_US{i,7}; % total trace elements post PM control
    so2_removal{i,3} = wfgd./tot; % ratio of trace elements removed by wFGD/total post PM control
end 
so2_removal = so2_removal(table2array(cell2table(so2_removal(:,2))) > 1000,:); % include only wfgd entries 


end 