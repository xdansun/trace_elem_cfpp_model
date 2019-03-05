function boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_apcd, coalqual_samples, ...
    cfpp_coal_purch, trials, prep_purchases)

%% bootstraps the concentration of trace elements in coal prior to entering the boiler 
% for each plant based on the fuel purchases and the coal samples present
% at each county via randomly sampling weight based on the purchases 
%
% Can also be used to extremize estimates. Manipulate lines 210-240
% (roughly) to perform extremization 
% 
% inputs:
% coal_gen_boiler_apcd (table) - coal:generator:boiler:apcd:fuels table 
% assumes that trace elements are uncorrelated from each other
% coalqual_samples (table) - all COALQUAL upper-level samples 
% cfpp_coal_purch (cell) - a cell with the coal purchases by county and rank for
% each plant; In order from left to right, the columns contain 1. the plant
% code, 2. the list of county_rank (counties whole number, decimals are the
% rank of the coal, 0.1 = BIT, 0.2 = SUB, and 0.3 = LIG), 3. the amount of
% coal purchased at each county_rank combination, using state when there
% are no county_rank matches
% trials (int) - number of trials for bootstrap. 10000 trials used in the paper 
% prep_purchases (table) - coal purchases that came from a coal preparation plant 
% 
% outputs:
% boot_cq_TE (cell) - Boostrapped concentrations of trace elements in the 
% coal blend by plant. First column are the plant numbers. Columns 2-5 are
% the bootstrapped concentrations of the coal blend entering the boiler for
% Hg, Se, As, and Cl, respectively. 
% 
% (concentrations of one trace element are dependent on the other trace
% elements)

%%
approach = 2; % two approaches to sample based on dependency. We recommend approach 2 

%%
% approach 1: use only coal samples that where the concentration of all
% four trace elements are estimated
if approach == 1
cq_samples = coalqual_samples(~isnan(coalqual_samples.Hg) & ~isnan(coalqual_samples.Se) & ...
    ~isnan(coalqual_samples.As) & ~isnan(coalqual_samples.Cl),:);

plant_list = unique(coal_gen_boiler_apcd.Plant_Code); 
plant_list_cq_dist = table2array(cell2table(cfpp_coal_purch(:,1)));
dist_plant_coal_blend = cell(1,1); 
count = 0;
for i = 1:size(plant_list,1) % for each coal plant 
%     plant_list(i)
    county_data = 1;
    if sum(plant_list_cq_dist == plant_list(i)) > 0 
        plant_data = cfpp_coal_purch(plant_list_cq_dist == plant_list(i),:); % find all coal purchases made by plant
        purch_counties = plant_data{1,2}; % counties plant purchased coal from
        plant_purch = plant_data{1,3}; % how much coal is purchased at each county 
        hg_conc = zeros(trials,size(purch_counties,1)); 
        se_conc = zeros(trials,size(purch_counties,1)); 
        as_conc = zeros(trials,size(purch_counties,1)); 
        cl_conc = zeros(trials,size(purch_counties,1)); 
        coal_blend_conc = zeros(trials,4);
        for j = 1:size(purch_counties,1) % for each county
            county_samples = cq_samples(cq_samples.county_rank == purch_counties(j),:); 
            state_rank = rem(purch_counties(j)*10,10)/10.0 + floor(purch_counties(j)/1e3);
            state_samples = cq_samples(cq_samples.state_rank == state_rank,:);
            
            % take 10000 coal sample draws
            index = floor(1 + size(county_samples,1)*rand(trials,1));
            if size(county_samples,1) > 0 % if there are samples at the county level 
                hg_conc(:,j) = county_samples.Hg(index);
                se_conc(:,j) = county_samples.Se(index);
                as_conc(:,j) = county_samples.As(index);
                cl_conc(:,j) = county_samples.Cl(index);
                
            elseif size(state_samples,1) > 0 % if there are samples at the state level
                hg_conc(:,j) = state_samples.Hg(index);
                se_conc(:,j) = state_samples.Se(index);
                as_conc(:,j) = state_samples.As(index);
                cl_conc(:,j) = state_samples.Cl(index); 
            else 
                county_data = 0; 
                count = count + 1; 
                break;
            end 
        end 
        if county_data == 1
            coal_blend_conc(:,1) = hg_conc*plant_purch/sum(plant_purch);
            coal_blend_conc(:,2) = se_conc*plant_purch/sum(plant_purch);
            coal_blend_conc(:,3) = as_conc*plant_purch/sum(plant_purch);
            coal_blend_conc(:,4) = cl_conc*plant_purch/sum(plant_purch);

            dist_plant_coal_blend(i,1) = {coal_blend_conc(:,1)}; 
            dist_plant_coal_blend(i,2) = {coal_blend_conc(:,2)}; 
            dist_plant_coal_blend(i,3) = {coal_blend_conc(:,3)}; 
            dist_plant_coal_blend(i,4) = {coal_blend_conc(:,4)}; 
        else
            dist_plant_coal_blend(i,1:4) = {nan, nan, nan, nan};
        end 
    end
end

display(count) % lose 107 plants this way, or about 39% of plants. This approach sacrifices too much of the fleet
% if we use state level data whenever county level data is not available,
% we still lost 59 plants, which is 21% of plants. That's still a steep
% cost. I don't think this first approach makes much sense. Therefore, the
% 3rd approach also doesn't make much sense, because there are 21% of
% plants and 39% of plants that do not have samples at the state level and
% county level, respectively. Therefore, drawing until we get to 10,000
% draws for all trace elements is impossible for those plants without
% county or state level data. 

end
%%
% approach 2: Estimate trace element concentrations that are missing in
% the sample via the median or mean of all samples in the county

% for every nan in COALQUAL, replace it with the median concentration at
% the state level or the basin level for Cl
cq_samples = coalqual_samples;
cq_te_conc = [cq_samples.Hg, cq_samples.Se, cq_samples.As, cq_samples.Cl];
for k = 1:4
    for i = 1:size(cq_te_conc,1)
        if isnan(cq_te_conc(i,k)) == 1
            cq_te_conc(i,k) = median(cq_te_conc(cq_samples.state_rank(i) == cq_samples.state_rank,k),'omitnan');
            if isnan(cq_te_conc(i,k)) == 1 && k == 4 % if the trace element is still nan, meaning there are no state level samples (for Cl)
                county_rank = cq_samples.county_rank(i);
                state = floor(county_rank/1000); 
                rank = mod(county_rank*10,10)/10; % determine numerical rank of coal 
                if state == 4 % Arizona, match Utah (49), CO (8), and NM (35)
                    coalqual_samples_basin = ...
                        coalqual_samples(strcmp(coalqual_samples.Province, 'ROCKY MOUNTAIN') == 1,:); 
                    coalqual_match = coalqual_samples_basin.Cl(coalqual_samples_basin.state_rank == (49+rank) | ...
                        coalqual_samples_basin.state_rank == (4+rank) | ...        
                        coalqual_samples_basin.state_rank == (8+rank) | ...
                        coalqual_samples_basin.state_rank == (35+rank)); % match at the state level
                    cq_te_conc(i,k) = median(coalqual_match,'omitnan');
                elseif state == 17 || state == 18 % Illinois, match IL, IN, and KY (21)
                    coalqual_samples_basin = ...
                        coalqual_samples(strcmp(coalqual_samples.Province, 'INTERIOR') == 1 & ...
                        strcmp(coalqual_samples.Region, 'EASTERN') == 1,:);
                    coalqual_match = coalqual_samples_basin.Cl(coalqual_samples_basin.state_rank == (17+rank) | ...
                        coalqual_samples_basin.state_rank == (18+rank) | ...
                        coalqual_samples_basin.state_rank == (21+rank)); % match at the state level
                    cq_te_conc(i,k) = median(coalqual_match,'omitnan');
                elseif state == 29 % MO, IA (19), Nebraska (31), KS (20), OK (40), AR (5)
                    coalqual_samples_basin = ...
                        coalqual_samples(strcmp(coalqual_samples.Province, 'INTERIOR') == 1 & ...
                        strcmp(coalqual_samples.Region, 'WESTERN') == 1,:);
                    coalqual_match = coalqual_samples_basin.Cl(coalqual_samples_basin.state_rank == (29+rank) | ...
                        coalqual_samples_basin.state_rank == (19+rank) | ...
                        coalqual_samples_basin.state_rank == (31+rank) | ...
                        coalqual_samples_basin.state_rank == (20+rank) | ...
                        coalqual_samples_basin.state_rank == (40+rank) | ...
                        coalqual_samples_basin.state_rank == (5+rank)); % match at the state level
                    cq_te_conc(i,k) = median(coalqual_match,'omitnan');
                elseif state == 47 % TN, KY (21), WV (54), and VA (51)
                    coalqual_samples_basin = ...
                        coalqual_samples(strcmp(coalqual_samples.Province, 'EASTERN') == 1 & ...
                        strcmp(coalqual_samples.Region, 'CENTRAL APPALACHIAN') == 1,:);
                    coalqual_match = coalqual_samples_basin.Cl(coalqual_samples_basin.state_rank == (47+rank) | ...
                        coalqual_samples_basin.state_rank == (21+rank) | ...
                        coalqual_samples_basin.state_rank == (54+rank) | ...
                        coalqual_samples_basin.state_rank == (51+rank)); % match at the state level
                    cq_te_conc(i,k) = median(coalqual_match,'omitnan');
                else 
                    1; % do nothing. States outside of the above basins are not burned at any U.S. CFPP
                end 
            end 
        end 
    end 
end 
cq_samples.Hg = cq_te_conc(:,1);
cq_samples.Se = cq_te_conc(:,2);
cq_samples.As = cq_te_conc(:,3);
cq_samples.Cl = cq_te_conc(:,4);

%% adjust coal concentrations based on simple assumptions of coal cleaning
% removal percentages are from a paper and a book chapter:
% https://www.sciencedirect.com/science/article/pii/0378382086900342 
% book chapter: The Redistribution of Trace Elements during the Beneficiation of
% Coal by D. Akers from Environmental Aspects of Trace Elements in Coal
if nargin == 5
    counties = unique(prep_purchases.county); 
    for i = 1:size(counties,1)
        idx = cq_samples.fips_code == counties(i,1);
        cq_samples.Hg(idx) = cq_samples.Hg(idx)*(1-0.783);
        cq_samples.Se(idx) = cq_samples.Se(idx)*(1-0.803);
        cq_samples.As(idx) = cq_samples.As(idx)*(1-0.846);        
        cq_samples.Cl(idx) = cq_samples.As(idx)*(1-0.68);        
    end 
end 

%%
plant_list = unique(coal_gen_boiler_apcd.Plant_Code); 
plant_list_cq_dist = table2array(cell2table(cfpp_coal_purch(:,1)));
dist_plant_coal_blend = cell(1,1); 
count = 0;
for i = 1:size(plant_list,1) % for each coal plant 
%     plant_list(i)
    county_data = 1;
    if sum(plant_list_cq_dist == plant_list(i)) > 0 
        plant_data = cfpp_coal_purch(plant_list_cq_dist == plant_list(i),:); % find all coal purchases made by plant
        purch_counties = plant_data{1,2}; % counties plant purchased coal from
        plant_purch = plant_data{1,3}; % how much coal is purchased at each county 
        hg_conc = zeros(trials,size(purch_counties,1)); 
        se_conc = zeros(trials,size(purch_counties,1)); 
        as_conc = zeros(trials,size(purch_counties,1)); 
        cl_conc = zeros(trials,size(purch_counties,1)); 
        coal_blend_conc = zeros(trials,4);
        for j = 1:size(purch_counties,1) % for each county
            county_samples = cq_samples(cq_samples.county_rank == purch_counties(j),:); 
            state_rank = rem(purch_counties(j)*10,10)/10.0 + floor(purch_counties(j)/1e3);
            state_samples = cq_samples(cq_samples.state_rank == state_rank,:);
            % take 10000 coal sample draws
            index = floor(1 + size(county_samples,1)*rand(trials,1));
            if size(county_samples,1) > 0 % if there are samples at the county level 
                % minimize trace element concentrations
%                 hg_conc(:,j) = min(county_samples.Hg(index)); 
%                 se_conc(:,j) = min(county_samples.Se(index));
%                 as_conc(:,j) = min(county_samples.As(index));
%                 cl_conc(:,j) = min(county_samples.Cl(index));
                
                % normal implementation
                hg_conc(:,j) = county_samples.Hg(index);
                se_conc(:,j) = county_samples.Se(index);
                as_conc(:,j) = county_samples.As(index);
                cl_conc(:,j) = county_samples.Cl(index);
            elseif size(state_samples,1) > 0 % use the state if there are county-level samples
                % minimize trace element concentrations
%                 hg_conc(:,j) = min(state_samples.Hg(index));
%                 se_conc(:,j) = min(state_samples.Se(index));
%                 as_conc(:,j) = min(state_samples.As(index));
%                 cl_conc(:,j) = min(state_samples.Cl(index));
                
                % normal implementation
                hg_conc(:,j) = state_samples.Hg(index);
                se_conc(:,j) = state_samples.Se(index);
                as_conc(:,j) = state_samples.As(index);
                cl_conc(:,j) = state_samples.Cl(index);                 
            else 
                county_data = 0; 
                count = count + 1; 
                break;
            end 
        end 
        if county_data == 1
            coal_blend_conc(:,1) = hg_conc*plant_purch/sum(plant_purch);
            coal_blend_conc(:,2) = se_conc*plant_purch/sum(plant_purch);
            coal_blend_conc(:,3) = as_conc*plant_purch/sum(plant_purch);
            coal_blend_conc(:,4) = cl_conc*plant_purch/sum(plant_purch);

            dist_plant_coal_blend(i,1) = {coal_blend_conc(:,1)}; 
            dist_plant_coal_blend(i,2) = {coal_blend_conc(:,2)}; 
            dist_plant_coal_blend(i,3) = {coal_blend_conc(:,3)}; 
            dist_plant_coal_blend(i,4) = {coal_blend_conc(:,4)}; 
        else
            dist_plant_coal_blend(i,1) = {nan};
        end 
    end
end

display(count)

% boot_cq_TE = 0; 
% boot_cq_TE = horzcat(table2cell(unique(coal_gen_boiler_apcd(:,{'Plant_Code'}))),...
%     boot_cq_hg, boot_cq_se, boot_cq_as, boot_cq_cl);
boot_cq_TE = horzcat(table2cell(array2table(plant_list)), dist_plant_coal_blend);

end 

 



