function boot_part = boot_partitioning_link(coal_gen_boiler_apcd, pm_removal, so2_removal, fgd_ww_ratio, trials, te)
%% DESCRIPTION NEEDED

%% seperate partitioning by trace element of interest 
% define column 
if strcmp(te,'Hg') == 1
    k = 1;
elseif strcmp(te, 'Se') == 1
    k = 2;
elseif strcmp(te, 'As') == 1
    k = 3;
elseif strcmp(te, 'Cl') == 1
    k = 4;
else
    error('incorrect trace element'); 
end 

% for pm control 
pm_removal_te = pm_removal; 
for i = 1:size(pm_removal_te,1)
    pm_removal_te{i,3} = pm_removal{i,3}(1,k); % reassign to only include partitioning for that trace element
end 
pm_removal_te(:,1) = []; % remove first column 
pm_removal_te = table2array(cell2table(pm_removal_te)); 
pm_removal_te(isnan(pm_removal_te(:,2)),:) = []; % remove all nans from partitioning 

% for so2 control 
so2_removal_te = so2_removal; 
for i = 1:size(so2_removal_te,1)
    so2_removal_te{i,3} = so2_removal{i,3}(1,k); % reassign to only include partitioning for that trace element
end 
so2_removal_te(:,1) = []; % remove first column 
so2_removal_te = table2array(cell2table(so2_removal_te)); 
so2_removal_te(isnan(so2_removal_te(:,2)),:) = []; % remove all nans from partitioning 


%% for each coal generator, create bootstrapped removal distribution for TE poll
boot_part = cell(size(coal_gen_boiler_apcd,1),1); 
pm_removal_backup = pm_removal_te; 
so2_removal_backup = so2_removal_te; 

if strcmp(te,'Hg') == 1
    cb_apcds = coal_gen_boiler_apcd.apcds; % only keep plants that we have literature data for 
    cb_apcd_so2 = floor(rem(cb_apcds/1000,10)); % pull the so2 control codes 
    cb_apcd_pm = floor(rem(cb_apcds/100,10)); % pull the pm control codes
    cb_apcd_nox = floor(rem(cb_apcds/10,10)); % pull the pm control codes
    cb_apcd_hg = floor(rem(cb_apcds,10)); % pull the pm control codes
    
    for i = 1 %:size(coal_gen_boiler_apcd,1) % for each boiler 
        te_part = zeros(trials,1); % initialize partition array
        
        lit_apcds_hg = floor(rem(pm_removal_te(:,1)/1,10));
        lit_apcds_nox = floor(rem(so2_removal_te(:,1)/10,10));
        
        if cb_apcd_so2(i) < 3 % if there is only a wFGD or dFGD control 
            % assume wFGD will be the last air emission control 
            % if there is ACI, remove all non ACI studies 
            % if there is SCR, remove all non SCR studies 
            % when replacing pm_removal_te, it needs to be coded as a
            % differnt variable name 
            
                if cb_apcd_hg(i) == 1
                    pm_removal_te = pm_removal_te(lit_apcds_hg == 1,:); 
                else 
                    pm_removal_te = pm_removal_te(lit_apcds_hg == 0,:); 
                end 
                if cb_apcd_nox(i) == 1
                    so2_removal_te = so2_removal_te(lit_apcds_nox == 1,:); 
                else
                    so2_removal_te = so2_removal_te(lit_apcds_nox == 0,:); 
                end 
                lit_apcds_pm = floor(rem(pm_removal_te(:,1)/100,10));
                lit_apcds_so2 = floor(rem(so2_removal_te(:,1)/1000,10));
                pm_ctrl = cb_apcd_pm(i); 
            while pm_ctrl > 0
                if pm_ctrl >= 4 % FF is one of the controls 
                    index = find(lit_apcds_pm == 4); % for FF 
                    pm_ctrl = pm_ctrl - 4; 
                elseif pm_ctrl >= 2 % hsESP is one of the controls 
                    index = find(lit_apcds_pm == 2); % for hsESP
                    pm_ctrl = pm_ctrl - 2; 
                elseif pm_ctrl == 1 % csESP is one of the controls
                    index = find(lit_apcds_pm == 1); % for csESP
                    pm_ctrl = pm_ctrl - 1;
                end 
                if size(index,1) > 0
                    te_part = te_part + (1-te_part).*...
                        pm_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2); % randomly generate <num trials> of studies 
                else 
                    te_part = nan; 
                end 
            end
            if isnan(te_part) ~= 1
                te_part = [te_part zeros(trials,1) 1-te_part]; % define solid, liquid, gas
                if cb_apcd_so2(i) == 1
                    index = find(lit_apcds_so2 == 1); % for wFGD
                    wfgd = so2_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2); % randomly generate <num trials> of studies 
                    te_part(:,2) = te_part(:,3).*wfgd*(fgd_ww_ratio(k)); % calculate liq partitioning
                    te_part(:,1) = te_part(:,1) + te_part(:,3).*wfgd*(1-fgd_ww_ratio(k)); % calculate solid partitioning
                    te_part(:,3) = 1 - te_part(:,1) - te_part(:,2); 
                end 
            else
                te_part = nan;
            end
        else 
            te_part = nan;     
        end
        % reset removals
        pm_removal_te = pm_removal_backup; 
        so2_removal_te = so2_removal_backup; 
        boot_part(i,1) = {te_part}; 
    end 

end

if strcmp(te,'Se') == 1 || strcmp(te,'As') == 1 || strcmp(te,'Cl') == 1 % for non Hg trace elements
    cb_apcds = coal_gen_boiler_apcd.apcds; % only keep plants that we have literature data for 
    cb_apcd_so2 = floor(rem(cb_apcds/1000,10)); % pull the so2 control codes 
    cb_apcd_pm = floor(rem(cb_apcds/100,10)); % pull the pm control codes
    lit_apcds_pm = floor(rem(pm_removal_te(:,1)/100,10));
    lit_apcds_so2 = floor(rem(so2_removal_te(:,1)/1000,10));
    
    for i = 1:size(coal_gen_boiler_apcd,1) % for each boiler 
        te_part = zeros(trials,1); % initialize partition array
        if cb_apcd_so2(i) < 3 % if there is only a wFGD or dFGD control 
            % assume wFGD will be the last air emission control 
            pm_ctrl = cb_apcd_pm(i); 
            while pm_ctrl > 0
                if pm_ctrl >= 4 % FF is one of the controls 
                    index = find(lit_apcds_pm == 4); % for FF 
                    pm_ctrl = pm_ctrl - 4; 
                elseif pm_ctrl >= 2 % hsESP is one of the controls 
                    index = find(lit_apcds_pm == 2); % for hsESP
                    pm_ctrl = pm_ctrl - 2; 
                elseif pm_ctrl == 1 % csESP is one of the controls
                    index = find(lit_apcds_pm == 1); % for csESP
                    pm_ctrl = pm_ctrl - 1;
                end 
                if size(index,1) > 0
                    te_part = te_part + (1-te_part).*pm_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2); % randomly generate <num trials> of studies 
                else 
                    te_part = nan; 
                end 
            end
            if isnan(te_part) ~= 1
                te_part = [te_part zeros(trials,1) 1-te_part]; % define solid, liquid, gas
                if cb_apcd_so2(i) == 1
                    index = find(lit_apcds_so2 == 1); % for wFGD
                    wfgd = so2_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2); % randomly generate <num trials> of studies 
                    te_part(:,2) = te_part(:,3).*wfgd*(fgd_ww_ratio(k)); % calculate liq partitioning
                    te_part(:,1) = te_part(:,1) + te_part(:,3).*wfgd*(1-fgd_ww_ratio(k)); % calculate solid partitioning
                    te_part(:,3) = 1 - te_part(:,1) - te_part(:,2); 
                end 
            else
                te_part = nan;
            end 
        else 
            te_part = nan; 
        end 
        boot_part(i,1) = {te_part}; 
%         boot_part(i,2) = {median(te_part(:,3))}; 
    end 
end

boot_part = horzcat(table2cell(coal_gen_boiler_apcd(:,{'Plant_Code','Plant_Boiler','apcds'})),boot_part);
% boot_remov = horzcat(table2cell(coal_gen_boiler_apcd(:,{'Plant_Code','Plant_Boiler'})),boot_remov);
% remove all plants that do not have any partitioning data 
flag = zeros(size(boot_part,1),1); 
for i = 1:size(boot_part,1)
    if isnan(boot_part{i,4}) == 1 % supposed to be 3
        flag(i) = 1;
    end 
end
boot_part(flag == 1,:) = []; 
boot_part = cell2table(boot_part); 
boot_part.Properties.VariableNames = {'Plant_Code','Plant_Boiler','apcds','boot_part'};

part_gas = zeros(size(boot_part,1),1); 
for i = 1:size(boot_part,1)
    part = boot_part{i,4}{1,1}; 
    if size(part,1) > 0
        part_gas(i) =  median(part(:,3),1);
    end 
end 
boot_part = horzcat(boot_part, array2table(part_gas)); 
% boot_part_hg_med(:,'boot_part') = [];
clear part part_gas;


%% perform check
for i = 1:size(boot_part,1)
    test = boot_part{i,3}; 
    for j = 1:size(test,1)
        if abs(sum(test(j,:)) - 1) > 1e-10
            error('partitioning coefficients do not add up to 1'); 
        end 
    end 
end 

end 