function [cfpp_cq_hg, cfpp_cq_se, cfpp_cq_as, cfpp_cq_cl, plants_no_cl_data] = ...
    coalqual_dist(coal_gen_boiler_apcd, fuel_purchases, plant_months)
% rewrite the description 
% Note that this script currently only works for Hg, as we are performing
% CEMS comparisons 
% this script also accounts for coal cleaning here 
%
% input argument:
% coal_gen_boiler_wapcd - coal:generator:boiler:apcd:fuels table 
% no_wc_domest_fuels - a table of coal purchases that excludes plants with
% foreign fuels and waste coal
% coal_clean_flag - a number (0 or 1) that indicates whether or not we utilize
% the coal cleaning approximations 
%
% outputs
% plant_cq_dist - a cell with the mercury distributions at each county for 
% each plant; In order from left to right, the columns contain 1. the plant
% code, 2. the list of county_rank (counties whole number, decimals are the
% rank of the coal, 0.1 = BIT, 0.2 = SUB, and 0.3 = LIG), 3. the amount of
% coal purchased at each county_rank combination, using state when there
% are no county_rank matches, 4+. and each subsequent column contains the
% distribution of mercury concentration in coal found in each county_rank
% according to COALQUAL 

warning('off'); 
%% extract coalqual data 
[num,txt,raw] = xlsread('../data/coalqual/coalqual_upper_wfips.xlsx','data'); % pull coalqual upper level with fips data  

coalqual_samples = cell2table(raw(2:end,:)); % name the coalqual data as strat_table 
coalqual_samples.Properties.VariableNames = raw(1,:); % set the table headers 

%% count number of samples at each county 
samples_in_counties = unique(coalqual_samples.fips_code); 
samples_in_counties(:,2) = 0; 
for i = 1:size(samples_in_counties,1)
    samples_in_counties(i,2) = sum(coalqual_samples.fips_code == samples_in_counties(i,1)); 
end 

fprintf('Minimum and maximum number of samples in each county %1.0f and %1.0f, respectively\n', [min(samples_in_counties(:,2)) max(samples_in_counties(:,2))]); 

%% determine which states are missing data 
state_list = unique(coalqual_samples.State);
for i = 1:size(state_list,1)
    state_list{i,2} = median(coalqual_samples.Hg(strcmp(coalqual_samples.State, state_list{i,1})),'omitnan');
    state_list{i,3} = median(coalqual_samples.Cl(strcmp(coalqual_samples.State, state_list{i,1})),'omitnan');
end

%% rename the ranks of coal in coalqual to match EIA fuel purchase data 
rank_cell = coalqual_samples.Apparent_Rank; % pull the apparent rank from the table 
% name the apparent ranks into three broad ranks of coal, lignit,
% subbituminous, and bituminous 
lig = {'Lignite A','Lignite B'};
sub = {'Subbituminous A','Subbituminous B','Subbituminous C'};
bit = {'High volatile A bituminous','High volatile B bituminous', ...
    'High volatile C bituminous','Low volatile bituminous', ...
    'Medium volatile bituminous'}; 
for i = 1:size(rank_cell) % for each coalqual sample, 
    if sum(strcmpi(rank_cell{i,1},lig)) == 1 % if the apparent rank belongs under lignite 
        rank_cell{i,2} = 'LIG'; % substitute with new name 
    elseif sum(strcmpi(rank_cell{i,1},sub)) == 1 % if the apparent rank belongs under subbituminous
        rank_cell{i,2} = 'SUB'; 
    elseif sum(strcmpi(rank_cell{i,1},bit)) == 1 % bituminous
        rank_cell{i,2} = 'BIT';
    else % if the apparent rank matches none of the above listed subranks, 
        display(i) % we have an error
        error('Apparent Rank in matrix unmatched in subrank matrices');
    end 
    % add an index into the third column of the cell to keep track of hte
    % indexing 
%     rank_cell{i,3} = i; 
end 

coalqual_samples(:,end+1) = rank_cell(:,2); % add the new column to the table 
coalqual_samples.Properties.VariableNames(end) = {'Rank'}; % name the new column 
%% create a new list in coalqual samples that is the state combined with rank and county combined with rank 
state_rank = coalqual_samples.fips_state; 
state_rank = state_rank + 0.1*strcmp(coalqual_samples.Rank,'BIT'); 
state_rank = state_rank + 0.2*strcmp(coalqual_samples.Rank,'SUB'); 
state_rank = state_rank + 0.3*strcmp(coalqual_samples.Rank,'LIG'); 

county_rank = coalqual_samples.fips_code; 
county_rank = county_rank + 0.1*strcmp(coalqual_samples.Rank,'BIT'); 
county_rank = county_rank + 0.2*strcmp(coalqual_samples.Rank,'SUB'); 
county_rank = county_rank + 0.3*strcmp(coalqual_samples.Rank,'LIG'); 

coalqual_samples = horzcat(coalqual_samples, array2table([state_rank county_rank])); 
coalqual_samples.Properties.VariableNames(end-1:end) = {'state_rank','county_rank'}; 
%% gather the list of plants, list of counties each plant bought coal from, the purchase amount from each county, and the rank of all coals 
plant_list = unique(coal_gen_boiler_apcd.Plant_Code);
plant_cq_dist = table2cell(array2table(plant_list)); 
% create new column with county and rank of coal 
for i = 1:size(plant_list,1) % for each power plant 
    if plant_months == 0 
        fuel_purchases_months = fuel_purchases; % do nothing
    else
        min_month = plant_months(plant_months(:,1) == plant_list(i,1),2); 
        max_month = plant_months(plant_months(:,1) == plant_list(i,1),3); 
        if size(min_month,1) > 0
            fuel_purchases_months = fuel_purchases(fuel_purchases.MONTH >= min_month, :);
            fuel_purchases_months = fuel_purchases_months(fuel_purchases_months.MONTH <= max_month, :);
        else
            fuel_purchases_months = fuel_purchases; % do nothing
        end
    end 
    county_rank = fuel_purchases_months.county; 
    county_rank = county_rank + 0.1*strcmp(fuel_purchases_months.ENERGY_SOURCE,'BIT');
    county_rank = county_rank + 0.2*strcmp(fuel_purchases_months.ENERGY_SOURCE,'SUB');
    county_rank = county_rank + 0.3*strcmp(fuel_purchases_months.ENERGY_SOURCE,'LIG');
    % all_counties = no_wc_domest_fuels.county; % create a list of all counties where purchases took place
    all_purchase_amts = fuel_purchases_months.QUANTITY; % create a list of all purchase amounts in tons
    county_rank_at_plant = county_rank(fuel_purchases_months.Plant_Id == plant_list(i,1)); % find all counties where that plant purchased coal from 
    purchase_amt_at_plant = all_purchase_amts(fuel_purchases_months.Plant_Id == plant_list(i,1)); % find out how much coal was purchased for each purchase
    uniq_counties = unique(county_rank_at_plant); % create a unique list of county_rank
    uniq_purch = zeros(size(uniq_counties)); 
    for j = 1:size(uniq_counties,1) % for each county the plant purchased coal from 
        uniq_purch(j) = sum(purchase_amt_at_plant(uniq_counties(j) == county_rank_at_plant)); % add up how much coal was purchased at the county 
    end 
    uniq_purch(uniq_counties < 0) = []; % remove nonexisting counties 
    uniq_counties(uniq_counties < 0) = []; 
    plant_cq_dist(i,2) = {uniq_counties}; % append result to master array 
    plant_cq_dist(i,3) = {uniq_purch};
end 

%%
% initialize outputs with plant IDs, county-rank of purchases, and amount
% purchased
cfpp_cq_hg = assign_CQ_dist(plant_cq_dist, coalqual_samples,'Hg'); 
cfpp_cq_se = assign_CQ_dist(plant_cq_dist, coalqual_samples,'Se'); 
cfpp_cq_as = assign_CQ_dist(plant_cq_dist, coalqual_samples,'As'); 
% chlorine has less data than other trace elements, we keep track of which
% plants we cannot model 
[cfpp_cq_cl, plants_no_cl_data] = assign_CQ_dist(plant_cq_dist, coalqual_samples,'Cl'); 


end


function [cfpp_cq_TE, plants_without_data] = assign_CQ_dist(cfpp_cq_TE, coalqual_samples,poll)
%% add TE distribution associated with each county at the plant 
% keep track of plants without coal information, namely they purchase from
% states without coal data
plants_without_data = zeros(size(cfpp_cq_TE,1),1); 
TE_samples = table2array(coalqual_samples(:,poll)); 
for j = 1:size(cfpp_cq_TE,1)
    county_rank_at_plant = cfpp_cq_TE{j,2}; 
    for i = 1:size(county_rank_at_plant,1) % for each county 
        % pull all coalqual samples that match the rank and location data
        coalqual_match = TE_samples(coalqual_samples.county_rank == county_rank_at_plant(i)); % match at the county level
        coalqual_match(isnan(coalqual_match)) = []; % remove all blank samples 
        if size(coalqual_match,1) > 0 && size(coalqual_match,2) > 0 % if there are county matches 
            cfpp_cq_TE(j,i+3) = {coalqual_match}; 
        else % look for a state match 
            county_rank = county_rank_at_plant(i); % define the state match 
            state_rank = floor(county_rank/1000) + mod(county_rank*10,10)/10; % divide the county rank by 1000 and add the decimal digit 
            coalqual_match = TE_samples(coalqual_samples.state_rank == state_rank); % match at the state level
            coalqual_match(isnan(coalqual_match)) = []; % remove all blank samples 
            if size(coalqual_match,1) == 0
                plants_without_data(j) = cfpp_cq_TE{j,1}; 
            end 
            cfpp_cq_TE(j,i+3) = {coalqual_match};
            
        end 
    end 
end 
cfpp_cq_TE = cfpp_cq_TE(plants_without_data == 0,:); 

end

