function [plt_TE_emis_lat_long, emf_egrid] = append_lat_long(plt_TE_emis, plant_coord, poll)
%% DESCRIPTION NEEDED 

%% determine median phase emis for each plant 
emf_med = zeros(size(plt_TE_emis,1),3); 
emis_med = zeros(size(plt_TE_emis,1),3); 
for i = 1:size(plt_TE_emis,1)
    emf_med(i,:) = median(plt_TE_emis.emf_mg_MWh{i,1},'omitnan'); 
    emis_med(i,:) = median(plt_TE_emis.emis_mg{i,1},'omitnan'); 
end
% emf_med(emf_med < 0) = 0; % set negative emfs to zero emfs (theres are due to negative generation)
plt_TE_emf_med = horzcat(plt_TE_emis(:,{'Plant_Code','Gen_MWh'}), array2table(emis_med), array2table(emf_med)); 
plt_TE_emf_med.Properties.VariableNames = {'Plant_Code','Gen_MWh','solid_mg','liq_mg','gas_mg','solid_emf_mg_mwh','liq_emf_mg_mwh','gas_emf_mg_mwh'}; 
%% merge geographical information 
plt_TE_emis_lat_long = innerjoin(plt_TE_emf_med, plant_coord); 
plt_TE_emis_lat_long(plt_TE_emis_lat_long.Gen_MWh < 0,:) = []; % remove plants with negative generation 
% emf_med = horzcat(plt_TE_emis_lat_long.solid_emf_mg_mwh, plt_TE_emis_lat_long.liq_emf_mg_mwh, plt_TE_emis_lat_long.gas_emf_mg_mwh); 
% emis_med(plt_TE_emis_lat_long.Gen_MWh < 0,:) = []; % update emission and emission factors 

%% calculate emissions at the egrid level
egrid_list = unique(plant_coord.egrid_subrgn); 
emf_egrid = zeros(size(egrid_list,1),3); 
% emis_med(isnan(emis_med)) = 0; % set nans to zero 
% older method where I take the median of the emissions at eGRID subregion
% level
% for i = 1:size(egrid_list,1)
%     idx = strcmp(egrid_list{i,1}, plt_TE_emis_lat_long.egrid_subrgn); 
%     emfs_plts = emf_med(idx,:); % gather all waste stream factors at egrid region i
%     emf_egrid(i,:) = median(emfs_plts,1,'omitnan'); % older method 
% end 
for i = 1:size(egrid_list,1)
    idx = strcmp(egrid_list{i,1}, plt_TE_emis_lat_long.egrid_subrgn); 
    emf_egrid(i,:) = sum(table2array(plt_TE_emf_med(idx,3:5)))/sum(plt_TE_emf_med.Gen_MWh);
end 

emf_egrid(isnan(emf_egrid)) = 0; 
emf_egrid = horzcat(cell2table(egrid_list), array2table(emf_egrid));
emf_egrid.Properties.VariableNames = {'eGRID','solid_mg_mwh','liq_mg_mwh','gas_mg_mwh'}; 

% set zero solid emissions to nan, implies no coal plants in eGRID subregion
emf_egrid.liq_mg_mwh(emf_egrid.solid_mg_mwh == 0) = nan; 
emf_egrid.gas_mg_mwh(emf_egrid.solid_mg_mwh == 0) = nan; 
emf_egrid.solid_mg_mwh(emf_egrid.solid_mg_mwh == 0) = nan; 

%% write excel outputs 
writetable(plt_TE_emis_lat_long, strcat('../r_map/data_boot_cq_remov_',poll,'.xlsx')); 
writetable(emf_egrid, strcat('../r_map/data_egrid_emf_',poll,'.xlsx')); 
end 








