function comp_part = compare_partitioning(boot_part_link, boot_part_sys, TE)

% compare solid and liquid partitioning fractions calculated using the link
% process method and the system method 

%% prepare data for plotting 
part_liq_sol = zeros(size(boot_part_link,1),2); 
for i = 1:size(boot_part_link,1)
    part = median(boot_part_link{i,3},1); 
    part_liq_sol(i,1) = part(1);  % solid partitioning
    part_liq_sol(i,2) = part(2);  % liq partitioning
end 
boot_part_link_med = horzcat(cell2table(boot_part_link), array2table(part_liq_sol)); 
boot_part_link_med.Properties.VariableNames = {'Plant_Code','Plant_Boiler','boot_part','med_sol_link', 'med_liq_link'}; 
boot_part_link_med(:,'boot_part') = [];

part_liq_sol = zeros(size(boot_part_sys,1),2); 
for i = 1:size(boot_part_sys,1)
    part = median(boot_part_sys{i,3},1); 
    part_liq_sol(i,1) = part(1);  % solid partitioning
    part_liq_sol(i,2) = part(2);  % liq partitioning
end 
boot_part_sys_med = horzcat(cell2table(boot_part_sys), array2table(part_liq_sol)); 
boot_part_sys_med.Properties.VariableNames = {'Plant_Code','Plant_Boiler','boot_part','med_sol_sys', 'med_liq_sys'}; 

comp_part = innerjoin(boot_part_link_med(:,{'Plant_Boiler','med_sol_link','med_liq_link'}), ...
    boot_part_sys_med(:,{'Plant_Boiler','med_sol_sys','med_liq_sys'})); 

comp_part(:,end+1) = array2table(comp_part.med_sol_link - comp_part.med_sol_sys); 
comp_part(:,end+1) = array2table(comp_part.med_liq_link - comp_part.med_liq_sys); 
comp_part.Properties.VariableNames(end-1:end) = {'dif_sol','dif_liq'}; 

%% create a histogram that compares the partitioning
figure('Color','w','Units','inches','Position',[1.25 1.25 4 4]) % was 1.25
axes('Position',[0.15 0.15 0.8 0.8]) % x pos, y pos, x width, y height

hold on;
histogram(comp_part.dif_sol,'facecolor','r');
histogram(comp_part.dif_liq,'facecolor','b');

set(gca,'FontName','Arial','FontSize',13)
a=gca;
% ylim([-0.2 0.2]); 

xlabel('Difference in partitioning');
ylabel('Number of boilers');

set(a,'box','off','color','none')
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

% xlim([-0.2 0.2]);
xlim([-inf inf]);
legend('Solid','Liquid','Location','northwest');
legend boxoff;
print(strcat('../Figures/comp_link_sys_part',TE),'-dpdf','-r300') % save figure (optional)


end 