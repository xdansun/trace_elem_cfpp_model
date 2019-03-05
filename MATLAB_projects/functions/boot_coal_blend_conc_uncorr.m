function boot_cq_TE = boot_coal_blend_conc_uncorr(coal_gen_boiler_apcd, cq_hg_2015, cq_se_2015, ...
    cq_as_2015, cq_cl_2015, trials)

%% bootstraps the concentration of trace elements in coal prior to entering the boiler 
% for each plant based on the fuel purchases and the coal samples present at each county 
%
% inputs:
% coal_gen_boiler_apcd (table) - coal:generator:boiler:apcd:fuels table 
% assumes that trace elements are uncorrelated from each other
% cfpp_cq_hg (cell) - a cell with the mercury distributions at each county for 
% each plant; In order from left to right, the columns contain 1. the plant
% code, 2. the list of county_rank (counties whole number, decimals are the
% rank of the coal, 0.1 = BIT, 0.2 = SUB, and 0.3 = LIG), 3. the amount of
% coal purchased at each county_rank combination, using state when there
% are no county_rank matches, 4+. and each subsequent column contains the
% distribution of mercury concentration in coal found in each county_rank
% according to COALQUAL 
% cfpp_cq_se, etc are the same as cfpp_cq_hg but for Selenium, Arsenic, and
% Chlorine 
% trials (int) - number of trials for bootstrap. 10000 trials used in the
% paper 
%
% outputs:
% boot_cq_TE (cell) - first column are the plant numbers. Columns 2-5 are
% the bootstrapped concentrations of the coal blend entering the boiler for
% Hg, Se, As, and Cl, respectively. 
% 
% (concentrations of one trace element are independent of other trace
% elements)

%% 


boot_cq_hg = boot_cq(coal_gen_boiler_apcd, cq_hg_2015, trials); 
boot_cq_se = boot_cq(coal_gen_boiler_apcd, cq_se_2015, trials); 
boot_cq_as = boot_cq(coal_gen_boiler_apcd, cq_as_2015, trials); 
boot_cq_cl = boot_cq(coal_gen_boiler_apcd, cq_cl_2015, trials);

boot_cq_TE = horzcat(table2cell(unique(coal_gen_boiler_apcd(:,{'Plant_Code'}))),...
    boot_cq_hg, boot_cq_se, boot_cq_as, boot_cq_cl);

end 
function dist_plant_coal_blend = boot_cq(coal_gen_boiler_apcd, cfpp_cq, trials)

%% create distributions of TE concentration in coal at each boiler via randomly sampling
% weight based on the purchases 

plant_list = unique(coal_gen_boiler_apcd.Plant_Code); 
plant_list_cq_dist = table2array(cell2table(cfpp_cq(:,1)));
dist_plant_coal_blend = cell(1,1); 
for i = 1:size(plant_list,1) % for each coal plant 
%     plant_list(i)
    if sum(plant_list_cq_dist == plant_list(i)) > 0 
        plant_data = cfpp_cq(plant_list_cq_dist == plant_list(i),:); 
        plant_purch = plant_data{1,3}; % gather coal purchases array at the plant level 
        coal_conc = zeros(size(plant_purch,1),trials);
        coal_blend_conc = zeros(trials,1); 
        for j = 4:(3+size(plant_purch,1)) % coal distribution starts on index 4, 
            % then the next few are all coal distributions; 3 is technically
            % the correct to add because for 5 counties, 4-8 is correct indexing
            coal_dist = plant_data{1,j};
             coal_conc(j-3,:) = coal_dist(floor(1 + size(coal_dist,1)*rand(trials,1))); 
            
            % determine if we can underestimate Hg emissions if we select
            % minimum values in Monte Carlo
%             coal_conc(j-3,:) = min(coal_dist)*ones(trials,1); % create vector with size equal to the trials
                        
        end 
        for j = 1:trials
            coal_blend_conc(j) = sum(coal_conc(:,j).*plant_purch)/sum(plant_purch); 
        end 
        dist_plant_coal_blend(i,1) = {coal_blend_conc}; 
    else
        dist_plant_coal_blend(i,1) = {nan};
    end 
end 

end
