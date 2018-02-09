function comp_part = compare_partitioning(boot_part_link, boot_part_sys)
%%
part_liq_sol = zeros(size(boot_part_link,1),2); 
for i = 1:size(boot_part_link,1)
    part = median(boot_part_link{i,3},1); 
    part_liq_sol(i,1) = part(1);  % solid partitioning
    part_liq_sol(i,2) = part(2);  % solid partitioning
end 
boot_part_link_med = horzcat(cell2table(boot_part_link), array2table(part_liq_sol)); 
boot_part_link_med.Properties.VariableNames = {'Plant_Code','Plant_Boiler','boot_part','med_sol_link', 'med_liq_link'}; 
boot_part_link_med(:,'boot_part') = [];

part_liq_sol = zeros(size(boot_part_sys,1),2); 
for i = 1:size(boot_part_sys,1)
    part = median(boot_part_sys{i,3},1); 
    part_liq_sol(i,1) = part(1);  % solid partitioning
    part_liq_sol(i,2) = part(2);  % solid partitioning
end 
boot_part_sys_med = horzcat(cell2table(boot_part_sys), array2table(part_liq_sol)); 
boot_part_sys_med.Properties.VariableNames = {'Plant_Code','Plant_Boiler','boot_part','med_sol_sys', 'med_liq_sys'}; 

comp_part = innerjoin(boot_part_link_med(:,{'Plant_Boiler','med_sol_link','med_liq_link'}), ...
    boot_part_sys_med(:,{'Plant_Boiler','med_sol_sys','med_liq_sys'})); 

comp_part(:,end+1) = array2table(comp_part.med_sol_link - comp_part.med_sol_sys); 
comp_part(:,end+1) = array2table(comp_part.med_liq_link - comp_part.med_liq_sys); 
comp_part.Properties.VariableNames(end-1:end) = {'dif_sol','dif_liq'}; 

histogram(comp_part.dif_sol);
hold on;
histogram(comp_part.dif_liq);

end 