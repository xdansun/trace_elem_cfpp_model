function foo = trace_elem_partition_lit_addon(partitioning_lit)

%%
% partitioning_lit = lit_partition_US;
partitioning_lit([4 11 19 21:22],:) = []; % removes averaged versions of studies 

for i = 1:50
    output_cell = flora_2002_aci_ff_addon(i);
    if iscell(output_cell) ~= 1
        break;
    else
        partitioning_lit(end+1,:) = output_cell;
    end 
end 

for i = 1:50
    output_cell = brown_1999_ff_addon(i);
    if iscell(output_cell) ~= 1
        break;
    else
        partitioning_lit(end+1,:) = output_cell;
    end 
end 

for i = 1:50
    output_cell = laird_trace_elem_dsi_addon(i);
    if iscell(output_cell) ~= 1
        break;
    else
        partitioning_lit(end+1,:) = output_cell;
    end 
end 


% add NRMRL (2005)

% ACI + PM controls 
% create entry for ACI controls
aci_removals = zeros(2,6); 
% first, for CSESP + ACI control combo 5 
aci_removals(1,1:6) = [94 85 70 94 65 73]/100; % see Table 5 and 7 of NRMRL study "Control of Mercury Emissions from Coal fired electric utility boilers: an update
% next for HSESP + ACI control combo 6 
aci_removals(2,1:2) = [40 80]/100; % see Table 7 of the above study 
aci_removals(aci_removals == 0) = nan; % set all zeros to NaN so they do not appear on plot
% note that ACI+FF removals listed in the NRMRL study has data for ACI+FF+SDA,
% which includes an SO2 control 

for i = 1:6
    partitioning_lit(end+1,1) = {'NRMRL (2005)'};
    partitioning_lit(end,2) = {101};
    partitioning_lit(end,3) = {[0 nan nan nan]}; 
    partitioning_lit(end,4) = {[aci_removals(1,i) nan nan nan]};
    partitioning_lit(end,5) = {[0 nan nan nan]};
    partitioning_lit(end,6) = {[0 nan nan nan]};
    partitioning_lit(end,7) = {[1 - aci_removals(1,i) nan nan nan]};
end 

for i = 1:2
    partitioning_lit(end+1,1) = {'NRMRL (2005)'};
    partitioning_lit(end,2) = {201};
    partitioning_lit(end,3) = {[0 nan nan nan]}; 
    partitioning_lit(end,4) = {[aci_removals(2,i) nan nan nan]};
    partitioning_lit(end,5) = {[0 nan nan nan]};
    partitioning_lit(end,6) = {[0 nan nan nan]};
    partitioning_lit(end,7) = {[aci_removals(2,i) nan nan nan]};
end 


foo = partitioning_lit;

%%

end 