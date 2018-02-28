function [plt_blr_TE_emis, plt_TE_emis] = boot_coal_cq_part_lit(...
    coal_gen_boiler_apcd, boot_cq_TE, boot_remov_TE, ann_coal_gen, poll)

%% DESCRIPTION NEEDED 

%% convert cells to tables 
boot_cq_TE_tbl = cell2table(boot_cq_TE); 
boot_cq_TE_tbl.Properties.VariableNames = {'Plant_Code','hg_ppm','se_ppm','as_ppm','cl_ppm'}; 
boot_remov_TE_tbl = cell2table(boot_remov_TE); 
boot_remov_TE_tbl.Properties.VariableNames = {'Plant_Code','Plant_Boiler','remov_dist'}; 

%% combine fuel consumption, generation, coal distribution, and removal tables together 
plt_blr_coal_remov = coal_gen_boiler_apcd(:,{'Plant_Code','Plant_Boiler','Net_Generation_Year_To_Date','Fuel_Consumed'}); 
plt_blr_coal_remov = innerjoin(plt_blr_coal_remov, boot_remov_TE_tbl); 
plt_blr_coal_remov = innerjoin(plt_blr_coal_remov, boot_cq_TE_tbl); 

%% calculate number of plants where we have data for one of the boilers but not the entire plant
plt_list = unique(coal_gen_boiler_apcd.Plant_Code); 
num_plts = 0; 
for i = 1:size(plt_list,1)
    num_blrs_orig = sum(plt_list(i) == coal_gen_boiler_apcd.Plant_Code); 
    num_blrs_post = sum(plt_list(i) == plt_blr_coal_remov.Plant_Code); 
    if num_blrs_orig - num_blrs_post ~= 0 
        num_plts = num_plts + 1; 
    end 
end 
% num_plts
% size(plt_list,1)
%% for each generator, calculate total emissions and emissions factor 
if strcmp(poll,'Hg') == 1
    k = 1; 
elseif strcmp(poll,'Se') == 1
    k = 2; 
elseif strcmp(poll,'As') == 1
    k = 3; 
elseif strcmp(poll,'Cl') == 1
    k = 4; 
end 
    
fuel_consumed = plt_blr_coal_remov.Fuel_Consumed;
gen = plt_blr_coal_remov.Net_Generation_Year_To_Date; 
lit_phases_TE_array = plt_blr_coal_remov.remov_dist; 

blrs_to_remov = zeros(size(plt_blr_coal_remov,1),1); 
plt_blr_TE_emis = cell(size(plt_blr_coal_remov,1),2); 
for i = 1:size(plt_blr_coal_remov,1)
    coal_dist = plt_blr_coal_remov{i,k+5}{1,1}; % find coal distribution associated with the plant of the boiler 
    if sum(isnan(coal_dist)) == 1 % if the TE input is all nans then leave just nan 
%         plt_blr_TE_emis(i,1) = {nan};
%         plt_blr_TE_emis(i,2) = {nan};
        blrs_to_remov(i) = 1; % mark boilers to be removed 
    else
        phase_dist = lit_phases_TE_array{i,1}; % find bootstrapped phase partitions associated with each boiler 
        % convert ppm to mol; ppm = 1g/10^6g
        % without unit conversion we have ppm * tons/yr * kg/tons = kg/yr
        % with unit conversion (10^-6 g Hg/g coal) * tons coal/yr * 907.185 kg/tons * 10^3 g/kg * 10^3 mg/g = mg/yr
        TE_input = repmat(coal_dist*fuel_consumed(i)*907.185,[1 3]); % calculate in weight the amount of coal entering the boiler 
        plt_blr_TE_emis(i,1) = {TE_input.*phase_dist}; % calculate TE output in each phase [mg]
        plt_blr_TE_emis(i,2) = {TE_input.*phase_dist/gen(i)}; % calculate TE output in each phase [mg/MWh]
        med_emf = median(TE_input.*phase_dist/gen(i)); 
        plt_blr_TE_emis(i,3) = {med_emf(1)}; 
        plt_blr_TE_emis(i,4) = {med_emf(2)}; 
        plt_blr_TE_emis(i,5) = {med_emf(3)}; 
    end 
end 

plt_blr_TE_emis = horzcat(plt_blr_coal_remov(:,{'Plant_Code','Plant_Boiler','Net_Generation_Year_To_Date'}), cell2table(plt_blr_TE_emis)); 
plt_blr_TE_emis.Properties.VariableNames = {'Plant_Code','Plant_Boiler','Gen_MWh','emis_mg','emf_mg_MWh','sol','liq','gas'}; 
plt_blr_TE_emis = plt_blr_TE_emis(blrs_to_remov == 0,:); % remove boilers with nan coal inputs 
%% aggregate data to the plant level 
% this method adds the bootstrapped distributions together, which may not
% be the most accurate way to aggregate median emissions at the plant level
% 
% plt_TE_emis = unique(plt_blr_TE_emis(:,{'Plant_Code'})); 
% % 
% gen = zeros(size(plt_TE_emis,1),1); % set array for generation 
% plt_emis_emfs = cell(1,2); 
% for i = 1:size(plt_TE_emis,1)
%     blr_idx = find(plt_TE_emis.Plant_Code(i) == plt_blr_TE_emis.Plant_Code); 
%     gen(i) = sum(plt_blr_TE_emis.Gen_MWh(blr_idx)); 
%     emis = zeros(10000,3); 
%     for j = 1:size(blr_idx,1)
%         emis = emis + plt_blr_TE_emis.emis_mg{blr_idx(j),1};
%     end 
%     plt_emis_emfs(i,1) = {emis}; 
%     plt_emis_emfs(i,2) = {emis/gen(i)};
% end 
% 
% plt_TE_emis(:,end+1) = array2table(gen); 
% plt_TE_emis.Properties.VariableNames = {'Plant_Code','Gen_MWh'}; 
% plt_TE_emis = horzcat(plt_TE_emis, cell2table(plt_emis_emfs)); 
% plt_TE_emis.Properties.VariableNames(end-1:end) = {'emis_mg','emf_mg_MWh'}; 

% This approach takes the median total emission and adds them together at
% the plant level 
plt_TE_emis = unique(plt_blr_TE_emis(:,{'Plant_Code'})); 

% emis = zeros(size(plt_TE_emis,1),3); % set array for emissions 
gen = zeros(size(plt_TE_emis,1),1); % set array for generation 
plt_emis_emfs = cell(1,2); 
for i = 1:size(plt_TE_emis,1)
    blr_idx = find(plt_TE_emis.Plant_Code(i) == plt_blr_TE_emis.Plant_Code); 
    gen(i) = sum(plt_blr_TE_emis.Gen_MWh(blr_idx)); 
    emis = zeros(1,3); 
    for j = 1:size(blr_idx,1)
        emis = emis + median(plt_blr_TE_emis.emis_mg{blr_idx(j),1},'omitnan');
    end 
    emis = repmat(emis,[3 1]); % this is for testing purposes 
    plt_emis_emfs(i,1) = {emis}; 
    plt_emis_emfs(i,2) = {emis/gen(i)};
end 

plt_TE_emis(:,end+1) = array2table(gen); 
plt_TE_emis.Properties.VariableNames = {'Plant_Code','Gen_MWh'}; 
plt_TE_emis = horzcat(plt_TE_emis, cell2table(plt_emis_emfs)); 
plt_TE_emis.Properties.VariableNames(end-1:end) = {'emis_mg','emf_mg_MWh'}; 


%% report summary statistics
% number of plants and generation of boilers modeled
foo = innerjoin(plt_blr_TE_emis(:,{'Plant_Code','Plant_Boiler'}), coal_gen_boiler_apcd(:,{'Plant_Boiler','Net_Generation_Year_To_Date','apcds'}));
fprintf('Estimated %s emissions for %1.0f plants\n', poll, size(unique(foo.Plant_Code),1)); 
fprintf('Estimated %s emissions for %1.0f plants with wFGD \n', poll, size(unique(foo.Plant_Code(foo.apcds > 999)),1)); 
fprintf('Estimated %s emissions for %1.3f (fraction) of total coal generation\n', poll, sum(foo.Net_Generation_Year_To_Date)/ann_coal_gen); 

annual_loadings = zeros(3,3); 
for i = 1:size(plt_blr_TE_emis,1)
    emis = plt_blr_TE_emis.emis_mg{i,1};
    annual_loadings(:,1) = annual_loadings(:,1)+ prctile(emis(:,1), [25, 50, 75])'/1e9; 
    annual_loadings(:,2) = annual_loadings(:,2)+ prctile(emis(:,2), [25, 50, 75])'/1e9; 
    annual_loadings(:,3) = annual_loadings(:,3)+ prctile(emis(:,3), [25, 50, 75])'/1e9; 
end 
fprintf('annual emissions (kg) 25, 50, and 75 percentile in: \n'); 
fprintf('solid:\t %3.0f %3.0f %3.0f\n', annual_loadings(:,1));
fprintf('liq: \t %3.2f %3.2f %3.2f\n', annual_loadings(:,2));
fprintf('gas: \t %3.0f %3.0f %3.0f\n', annual_loadings(:,3));
% sum(annual_loadings,1,'omitnan'))

%%
med_emf = zeros(size(plt_TE_emis,1),3); 
for i = 1:size(plt_TE_emis,1)
    med_emf(i,:) =  median(plt_TE_emis.emf_mg_MWh{i,1}, 'omitnan');
end 
med_emf(isnan(med_emf)) = 0; % turn this off if analyze nonzero numbers only 
med_emf(med_emf(:,1) == 0,:) = []; % remove plant with zero fuel consumption
% fprintf('%s emf percentile (solid, liquid, gas) for 0th, 5th, 25th, 50th, 7th, 95th, and 100th', poll); 
% prctile(med_emf,[0 5 25 50 75 95 100],1)/10^3
end

