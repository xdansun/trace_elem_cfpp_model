function boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_wapcd_code, cq_hg_2015, cq_se_2015, ...
    cq_as_2015, cq_cl_2015, trials)

boot_cq_hg = boot_cq(coal_gen_boiler_wapcd_code, cq_hg_2015, trials); 
boot_cq_se = boot_cq(coal_gen_boiler_wapcd_code, cq_se_2015, trials); 
boot_cq_as = boot_cq(coal_gen_boiler_wapcd_code, cq_as_2015, trials); 
boot_cq_cl = boot_cq(coal_gen_boiler_wapcd_code, cq_cl_2015, trials);

boot_cq_TE = horzcat(table2cell(unique(coal_gen_boiler_wapcd_code(:,{'Plant_Code'}))),...
    boot_cq_hg, boot_cq_se, boot_cq_as, boot_cq_cl);

end 
function dist_plant_coal_blend = boot_cq(coal_gen_boiler_wapcd_code, cfpp_cq, trials)
%% DESCRIPTION NEEDED 

%% create distributions of TE concentration in coal at each boiler via randomly sampling
% weight based on the purchases 

plant_list = unique(coal_gen_boiler_wapcd_code.Plant_Code); 
plant_list_cq_dist = table2array(cell2table(cfpp_cq(:,1)));
dist_plant_coal_blend = cell(1,1); 
for i = 1:size(plant_list,1) % for each coal plant 
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