function boot_part = boot_partitioning_link(coal_gen_boiler_apcd, pm_removal,...
    so2_removal, fgd_ww_ratio, trials, te, extreme_flag)
%% Description
% bootstrap partitioning coefficients using link approach
% 
% Can also be used to extremize estimates. Manipulate lines 115-185 
% (roughly) to perform extremization 
% 
% inputs
% coal_gen_boiler_apcd (table) - coal:generator:boiler:apcd:fuels table 
% pm_removal (cell) - partitioning of each trace element by the particulate
% matter control for each study
% so2_removal (cell) - partitioning of each trace element by the sulfur
% dioxide control for each study
% fgd_ww_ratio (double) - ratio of trace element in Cl purge to gypsum
% trials (int) - number of trials to bootstrap
% te (str) - trace element to bootstrap on
% extreme_flag (int) - default is zero. If not zero, then run the extreme
% analysis where coal concentrations are minimized and partitioning to gas
% is minimized 
% 
% output
% boot_part (cell) - all boilers in analysis with bootstrapped partitioning
% coefficients. Column 1 is the plant, column 2 is the boiler, and column 3
% are the bootstrapped partitioning coefficients to solid, liquid, and gas.
% Trace element depends on the trace element defined in the input (te). 

%% define extreme_flag if it's undefined 
if nargin < 7
    extreme_flag = 0; 
end 

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

% for chlorine, approximate hsESP and FF removal as csESP 
% copy all csESP data twice and write as hsESP the first time and FF the
% second time
if strcmp(te, 'Cl') == 1
    apcds = floor(rem(table2array(cell2table(pm_removal(:,2)))/100,10)); 
    csesp_removal = pm_removal(apcds == 1,:); 
    for i = 1:size(csesp_removal,1)
        csesp_removal{i,2} = 400; % FF
    end 
    pm_removal = vertcat(pm_removal, csesp_removal); 
    for i = 1:size(csesp_removal,1)
        csesp_removal{i,2} = 200; % hsESP
    end 
    pm_removal = vertcat(pm_removal, csesp_removal); 
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

% create a source variable that is not manipulated 
pm_removal_source = pm_removal_te; 
so2_removal_source = so2_removal_te; 

%% for each coal generator, create bootstrapped removal distribution for TE poll
% I treat dFGD + FF as a single control. The combination is implemented as
% a "particulate matter" control because it is easier to implement than as
% a sulfur dioxide control
boot_part = cell(size(coal_gen_boiler_apcd,1),1); 

% pm_removal_te = pm_removal_source; % for testing
% so2_removal_te = so2_removal_source; % for testing

if strcmp(te,'Hg') == 1 % Hg 
    cb_apcds = coal_gen_boiler_apcd.apcds; % only keep plants that we have literature data for 
    cb_apcd_so2 = floor(rem(cb_apcds/1000,10)); % pull the so2 control codes 
    cb_apcd_pm = floor(rem(cb_apcds/100,10)); % pull the pm control codes
    cb_apcd_nox = floor(rem(cb_apcds/10,10)); % pull the nox control codes
    cb_apcd_hg = floor(rem(cb_apcds,10)); % pull the hg control codes
    
    for i = 1:size(coal_gen_boiler_apcd,1) % for each boiler 
%         [cb_apcd_so2(i) cb_apcd_pm(i) cb_apcd_nox(i) cb_apcd_hg(i)]
        te_part = zeros(trials,1); % initialize partition array
        
        lit_apcds_hg = floor(rem(pm_removal_source(:,1)/1,10));
%         lit_apcds_pm = floor(rem(pm_removal_source(:,1)/100,10));
        lit_apcds_nox = floor(rem(so2_removal_source(:,1)/10,10));
%         lit_apcds_so2 = floor(rem(so2_removal_source(:,1)/1000,10));
        
        if cb_apcd_so2(i) >= 4 % if there is DSI
            cb_apcd_so2(i) = cb_apcd_so2(i) - 4; % remove it 
        end 

%         [cb_apcd_so2(i) cb_apcd_pm(i) cb_apcd_nox(i) cb_apcd_hg(i)]
        
        if cb_apcd_so2(i) == 2 || cb_apcd_so2(i) == 6 % implies dFGD is present 
            if cb_apcd_hg(i) == 1 % if there is ACI, remove all non ACI studies
                pm_removal_te = pm_removal_source(lit_apcds_hg == 1,:);
                cb_apcd_hg(i) = cb_apcd_hg(i) - 1;
            else
                pm_removal_te = pm_removal_source(lit_apcds_hg == 0,:);
            end
            lit_apcds_so2 = floor(rem(pm_removal_te(:,1)/1000,10));
            index = find(lit_apcds_so2 == 2); % for dFGD 
            if extreme_flag == 0
            % median, normal result 
                te_part = te_part + (1-te_part).*...
                            pm_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2); % randomly generate <num trials> of studies 
            % choose maximum removal to minimize Hg emissions to air
            else
                te_part = te_part + (1-te_part).*...
                            (max(pm_removal_te(index,2))*ones(trials,1));
            end 
                        
            cb_apcd_so2(i) = cb_apcd_so2(i) - 2; % subtract off the dFGD 
            % subtract off the FF, even if csESP or hsESP downstream,
            % assume they have similar efficiencies
            cb_apcd_pm(i) = cb_apcd_pm(i) - 4; 
        end 
        
        % if there is only a wFGD or dFGD control 
        % assume wFGD will be the last air emission control
        pm_ctrl = cb_apcd_pm(i);
        if pm_ctrl == 0 % only so2 controls 
            if cb_apcd_nox(i) == 1 % if there is SCR, remove all non SCR studies
                so2_removal_te = so2_removal_source(lit_apcds_nox == 1,:);
            else
                so2_removal_te = so2_removal_source(lit_apcds_nox == 0,:);
            end
            lit_apcds_so2 = floor(rem(so2_removal_te(:,1)/1000,10));
        end 
        while pm_ctrl > 0      
            if cb_apcd_hg(i) == 1 % if there is ACI, remove all non ACI studies
                pm_removal_te = pm_removal_source(lit_apcds_hg == 1,:);
                cb_apcd_hg(i) = cb_apcd_hg(i) - 1;
            else
                pm_removal_te = pm_removal_source(lit_apcds_hg == 0,:);
            end
            if cb_apcd_nox(i) == 1 % if there is SCR, remove all non SCR studies
                so2_removal_te = so2_removal_source(lit_apcds_nox == 1,:);
            else
                so2_removal_te = so2_removal_source(lit_apcds_nox == 0,:);
            end
            lit_apcds_so2 = floor(rem(pm_removal_te(:,1)/1000,10));
            if cb_apcd_so2(i) < 2 % no dFGD present 
                pm_removal_te = pm_removal_te(lit_apcds_so2 < 2,:);
            end 
            
            lit_apcds_pm = floor(rem(pm_removal_te(:,1)/100,10));
            lit_apcds_so2 = floor(rem(so2_removal_te(:,1)/1000,10));

            if pm_ctrl == 1 || pm_ctrl == 3 || pm_ctrl == 5 % csESP is one of the controls
                index = find(lit_apcds_pm == 1); % for csESP
                pm_ctrl = pm_ctrl - 1;
            elseif pm_ctrl >= 4 % FF is one of the controls
                index = find(lit_apcds_pm == 4); % for FF
                pm_ctrl = pm_ctrl - 4;
            elseif pm_ctrl >= 2 % hsESP is one of the controls
                index = find(lit_apcds_pm == 2); % for hsESP
                pm_ctrl = pm_ctrl - 2;
            end
            
            if size(index,1) > 0
                te_part = te_part + (1-te_part).*...
                    pm_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2); % randomly generate <num trials> of studies
                if extreme_flag == 1
                    % choose maximum removal to minimize Hg emissions to air
                    te_part = te_part + (1-te_part).*...
                            (max(pm_removal_te(index,2))*ones(trials,1));
                end 
            else
                te_part = nan;
            end
        end
%         [cb_apcd_so2(i) cb_apcd_pm(i) cb_apcd_nox(i) cb_apcd_hg(i)]
        if isnan(te_part) ~= 1
            te_part = [te_part zeros(trials,1) 1-te_part]; % define solid, liquid, gas
            if cb_apcd_so2(i) == 1
                index = find(lit_apcds_so2 == 1); % for wFGD                
                wfgd = so2_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2); % randomly generate <num trials> of studies
                if extreme_flag == 1
                    % choose maximum removal to minimize Hg emissions to air
                    wfgd = max(so2_removal_te(index,2)); % randomly generate <num trials> of studies
                end 
                te_part(:,2) = te_part(:,3).*wfgd*(fgd_ww_ratio(k)); % calculate liq partitioning
                te_part(:,1) = te_part(:,1) + te_part(:,3).*wfgd*(1-fgd_ww_ratio(k)); % calculate solid partitioning
                te_part(:,3) = 1 - te_part(:,1) - te_part(:,2);
            end
        else
            te_part = nan;
        end

        boot_part(i,1) = {te_part}; 
    end 

end
%% non Hg trace elements
if strcmp(te,'Se') == 1 || strcmp(te,'As') == 1 || strcmp(te,'Cl') == 1 % for non Hg trace elements
    cb_apcds = coal_gen_boiler_apcd.apcds; % only keep plants that we have literature data for 
    cb_apcd_so2 = floor(rem(cb_apcds/1000,10)); % pull the so2 control codes 
    cb_apcd_pm = floor(rem(cb_apcds/100,10)); % pull the pm control codes
    
    for i = 1:size(coal_gen_boiler_apcd,1) % for each boiler 
        te_part = zeros(trials,1); % initialize partition array
        
        if cb_apcd_so2(i) >= 4 && strcmp(te,'Cl') == 1 % for DSI, 
%             though DSI is a SO2 removal, it operates upstream of the
%             csESP, so it's removal is embedded in PM removal
            pm_removal_te = pm_removal_source; 
            lit_apcds_so2 = floor(rem(pm_removal_te(:,1)/1000,10));
            index = find(lit_apcds_so2 == 4); % for DSI
            te_part = te_part + (1-te_part).*...
                        pm_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2);
%                         pm_removal_te(lit_apcds_so2 == 4,2); % randomly generate <num trials> of studies 
            cb_apcd_so2(i) = cb_apcd_so2(i) - 4;
        elseif cb_apcd_so2(i) >= 4
            cb_apcd_so2(i) = cb_apcd_so2(i) - 4;
        end 
        if cb_apcd_so2(i) == 2 || cb_apcd_so2(i) == 6 % implies dFGD is present 
            pm_removal_te = pm_removal_source; 
            lit_apcds_so2 = floor(rem(pm_removal_te(:,1)/1000,10));
            index = find(lit_apcds_so2 == 2); % for dFGD 
            te_part = te_part + (1-te_part).*...
                        pm_removal_te(index(floor(1 + size(index,1)*rand(trials,1))),2); % randomly generate <num trials> of studies 
            cb_apcd_so2(i) = cb_apcd_so2(i) - 2; % subtract off the dFGD 
            % subtract off the FF, even if csESP or hsESP downstream,
            % assume they have similar efficiencies
            cb_apcd_pm(i) = cb_apcd_pm(i) - 4; 
        end 
        % assume wFGD will be the last air emission control
        pm_ctrl = cb_apcd_pm(i);
        if pm_ctrl == 0 % only so2 controls 
            so2_removal_te = so2_removal_source;
            lit_apcds_so2 = floor(rem(so2_removal_te(:,1)/1000,10));
        end 
        while pm_ctrl > 0
            pm_removal_te = pm_removal_source;
            so2_removal_te = so2_removal_source;
            
            lit_apcds_so2 = floor(rem(pm_removal_te(:,1)/1000,10));
            if cb_apcd_so2(i) < 2 % no dFGD present 
                pm_removal_te = pm_removal_te(lit_apcds_so2 < 2,:);
            end 
            
            lit_apcds_pm = floor(rem(pm_removal_te(:,1)/100,10));
            lit_apcds_so2 = floor(rem(so2_removal_te(:,1)/1000,10));
            
            if pm_ctrl == 1 || pm_ctrl == 3 || pm_ctrl == 5 % csESP is one of the controls
                index = find(lit_apcds_pm == 1); % for csESP
                pm_ctrl = pm_ctrl - 1;
            elseif pm_ctrl >= 4 % FF is one of the controls
                index = find(lit_apcds_pm == 4); % for FF
                pm_ctrl = pm_ctrl - 4;
            elseif pm_ctrl >= 2 % hsESP is one of the controls
                index = find(lit_apcds_pm == 2); % for hsESP
                pm_ctrl = pm_ctrl - 2;
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

        boot_part(i,1) = {te_part}; 
    end 

end

% boot_part = horzcat(table2cell(coal_gen_boiler_apcd(:,{'Plant_Code','Plant_Boiler','apcds'})),boot_part);
boot_part = horzcat(table2cell(coal_gen_boiler_apcd(:,{'Plant_Code','Plant_Boiler'})),boot_part);
% remove all plants that do not have any partitioning data 
flag = zeros(size(boot_part,1),1); 
for i = 1:size(boot_part,1)
    if isnan(boot_part{i,3}) == 1 % supposed to be 3
        flag(i) = 1;
    end 
end
boot_part(flag == 1,:) = []; 


%% perform check
for i = 1:size(boot_part,1)
    test = boot_part{i,3}; 
    for j = 1:size(test,1)
        if abs(sum(test(j,:)) - 1) > 1e-10
            test(j,:)
            display(boot_part{i,2})
            error('partitioning coefficients do not add up to 1'); 
        end 
    end 
end 

end 