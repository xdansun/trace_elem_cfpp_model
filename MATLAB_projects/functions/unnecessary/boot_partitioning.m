function boot_remov = boot_partitioning(coal_gen_boiler_wapcd_code, lit_phases_TE, trials, poll)
%% DESCRIPTION NEEDED

%% for each coal generator, create bootstrapped removal distribution for TE poll
if strcmp(poll,'Hg') == 1
    apcds = coal_gen_boiler_wapcd_code.apcds; 
    flag = zeros(size(coal_gen_boiler_wapcd_code,1),1); 
    lit_apcds = table2array(cell2table(lit_phases_TE(:,2))); 
    for i = 1:size(apcds,1)
        if sum(apcds(i) == lit_apcds) > 0
            flag(i) = 1; 
        end     
    end 
    coal_gb_apcd_wdata = coal_gen_boiler_wapcd_code(flag == 1,:);

    apcds = coal_gb_apcd_wdata.apcds; 
    boot_remov = cell(1,1); 
    lit_phases_TE_array = table2array(cell2table(lit_phases_TE(:,3:5))); 
    for i = 1:size(coal_gb_apcd_wdata,1)
        index = find(apcds(i) == lit_apcds); % find all studies with the air pollution control 
        boot_remov(i,1) = {lit_phases_TE_array(index(floor(1 + size(index,1)*rand(trials,1))),:)}; % randomly generate <num trials> of studies 
    end 
elseif strcmp(poll,'Se') == 1 || strcmp(poll,'As') == 1 || strcmp(poll,'Cl') == 1 % for non Hg trace elements
    apcds = coal_gen_boiler_wapcd_code.apcds; % only keep plants that we have literature data for 
    apcds_pm_so2 = floor(apcds/100);
    lit_apcds = table2array(cell2table(lit_phases_TE(:,2))); 
    lit_apcds_pm_so2 = floor(lit_apcds/100); 
    flag = zeros(size(coal_gen_boiler_wapcd_code,1),1); 
    for i = 1:size(apcds,1)
        if sum(apcds_pm_so2(i) == lit_apcds_pm_so2) > 0
            flag(i) = 1; 
        end     
    end 
    coal_gb_apcd_wdata = coal_gen_boiler_wapcd_code(flag == 1,:);

    apcds = coal_gb_apcd_wdata.apcds; 
    apcds_pm_so2 = floor(apcds/100);
    boot_remov = cell(1,1); 
    lit_phases_TE_array = table2array(cell2table(lit_phases_TE(:,3:5))); 
    for i = 1:size(coal_gb_apcd_wdata,1)
        index = find(apcds_pm_so2(i) == lit_apcds_pm_so2); % find all studies with the air pollution control
        boot_remov(i,1) = {lit_phases_TE_array(index(floor(1 + size(index,1)*rand(trials,1))),:)}; % randomly generate <num trials> of studies 
    end 
else 
    error('incorrect pollutant specified'); 
end

boot_remov = horzcat(table2cell(coal_gb_apcd_wdata(:,{'Plant_Code','Plant_Boiler'})),boot_remov);

end