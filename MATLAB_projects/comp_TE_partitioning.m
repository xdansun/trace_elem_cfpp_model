function comp_partition_lit_mats = comp_TE_partitioning(haps_remov_wcode, boot_remov_TE, poll)

%%
boot_remov_TE_tbl = cell2table(boot_remov_TE(:,2:3));
boot_remov_TE_tbl.Properties.VariableNames = {'Plant_Boiler','removs'};

% for each boiler, find median trace element removal from boostrap
solid_liq_removs = zeros(size(boot_remov_TE_tbl,1),1);
for i = 1:size(boot_remov_TE_tbl,1) 
    removals = median(boot_remov_TE_tbl.removs{i,1});
    solid_liq_removs(i,1) = 1 - removals(1,3); % 3rd column is gas (solid, liq, gas)
end
boot_remov_TE_tbl(:,end+1) = array2table(solid_liq_removs);
boot_remov_TE_tbl.Properties.VariableNames(end) = {'boot_med_remov'};

% select haps removal for correct pollutant 
if strcmp(poll,'Hg') == 1
    haps_remov = haps_remov_wcode(:,[3 7 8]);
elseif strcmp(poll,'Se') == 1
    haps_remov = haps_remov_wcode(:,[4 7 8]);
elseif strcmp(poll,'As') == 1
    haps_remov = haps_remov_wcode(:,[5 7 8]);
elseif strcmp(poll,'Cl') == 1
    haps_remov = haps_remov_wcode(:,[6 7 8]);
end

% remove missing removals, remove negative removals 
% the removals are in table2array(haps_remov(:,1)) 
haps_remov.Properties.VariableNames(1) = {'haps_med_remov'}; 
haps_remov(isnan(haps_remov.haps_med_remov),:) = []; 
haps_remov(haps_remov.haps_med_remov < 0,:) = []; % remove negative removal coefficients 

comp_partition_lit_mats = innerjoin(haps_remov, boot_remov_TE_tbl);
comp_partition_lit_mats(:,end+1) = array2table(comp_partition_lit_mats.boot_med_remov -...
    comp_partition_lit_mats.haps_med_remov);
comp_partition_lit_mats.Properties.VariableNames(end) = {'remov_dif'};    

%% summary statistics
fprintf('%s median partition into solids + liquids from MATS ICR and literature %1.3f, %1.3f\n', ...
    poll, median(comp_partition_lit_mats.haps_med_remov), median(comp_partition_lit_mats.boot_med_remov))
fprintf('%s mean and median difference of MATS and literature %1.3f %1.3f\n', ...
    poll, mean(comp_partition_lit_mats.remov_dif), median(comp_partition_lit_mats.remov_dif))
    
end 