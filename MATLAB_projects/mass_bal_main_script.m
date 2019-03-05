% description needed 

clear; clc; close all;
warning('off','all');
% add folders for functions in different directory 
addpath('utility_scripts'); % contains data scrubbing functions
addpath('utility_scripts/hatch'); % important plotting function
addpath('functions'); % contains functions for performing calculations
addpath('plot_functions'); % contains all plotting functions 

%% Input EIA Generator, boiler, and fuel data
% add coal generators and boilers into the analysis exclude coal generators
% that are linked to multiple boilers and vice versa
[coal_generators, coal_gen_boilers, ann_coal_gen, num_coal_plants] = create_coal_single_gen_boiler;  

% Add EIA coal purchase data to boilers 
[coal_gen_boilers, coal_purchases_2015] = ...
    compile_coal_purchases(coal_gen_boilers, ann_coal_gen, num_coal_plants, 2015); 
% Add EIA coal consumption data to boilers, creating coal:generator:boiler:fuels table
coal_gen_blrs_wfuels = boiler_fuel_consumption(coal_gen_boilers,ann_coal_gen, num_coal_plants); 

% calculate elec generation at the plant level 
plant_gen = unique(coal_gen_boilers.Plant_Code); 
plant_gen(:,2) = 0; 
for i = 1:size(plant_gen,1)
    plant_gen(i,2) = sum(coal_gen_boilers.Net_Generation_Year_To_Date(...
        plant_gen(i,1) == coal_gen_boilers.Plant_Code)); 
end 
plant_gen = array2table(plant_gen); 
plant_gen.Properties.VariableNames = {'Plant_Code','Gen_MWh'}; 
plant_gen = sortrows(plant_gen,'Gen_MWh','descend');
%% Input air pollution control data 
% find which post-combustion air pollution controls are installed at the
% boiler level (boiler:apcd)
[boiler_pm, boiler_so2, boiler_nox, boiler_hg] = apcd_link;

% merge the coal:generator:boiler:fuels table with the boiler:apcd table
coal_gen_boiler_apcd = outerjoin(coal_gen_blrs_wfuels,boiler_pm,'Type','left','MergeKeys',true);
coal_gen_boiler_apcd = outerjoin(coal_gen_boiler_apcd,boiler_so2,'Type','left','MergeKeys',true);
coal_gen_boiler_apcd = outerjoin(coal_gen_boiler_apcd,boiler_nox,'Type','left','MergeKeys',true);
coal_gen_boiler_apcd = outerjoin(coal_gen_boiler_apcd,boiler_hg,'Type','left','MergeKeys',true);

% convert apcd combinations to numerical code for easier processing
% SO2 control installed is thousands place
% PM control is hundreds place
% NOx control is tens place
% mercury control is ones place 
coal_gen_boiler_apcd = identify_apcd_base10(coal_gen_boiler_apcd); 

%% Create Figure - partitioning of trace elements by literature study
% Calculate partitioning by air pollution control for each study 
% data in lit_partition_apcd_all used to create table with all partitioning
% studies
[lit_partition_apcd_all, fgd_ww_ratio] = trace_elem_partition_lit; % include international studies
lit_partition_US = lit_partition_apcd_all(1:25,:); % select only domestic studies for bootstrap partitioning
lit_partition_international = lit_partition_apcd_all(26:end,:);
% for each air pollution control, calculate partitioning via linked based approach
[pm_removal, so2_removal] = linked_based_partition(lit_partition_US);
[pm_removal_int, so2_removal_int] = linked_based_partition(lit_partition_international);

close all; 
plot_TE_partition_link(pm_removal, so2_removal, fgd_ww_ratio);
% plot_TE_partition_link(pm_removal_int, so2_removal_int, fgd_ww_ratio);

% add sample level data points for specific study 
lit_partition_US_addon = trace_elem_partition_lit_addon(lit_partition_US);
[pm_removal, so2_removal] = linked_based_partition(lit_partition_US_addon);

%% plot median partitioning coefficients for each air pollution control combination 
% for linked based approach and whole process based approach 
% lit_phases_by_TE = plot_TE_partition_v2(lit_partition_US);
% [part_by_apc_link, part_by_apc_whole] = ...
%     plot_link_vs_whole_partition(pm_removal, so2_removal, lit_phases_by_TE, fgd_ww_ratio);

%% Estimate TE concentrations in coal blends by bootstrapping
% For each coal purchase, find location of coal purchase
% for each location, randomly draw one sample from all coal samples at that location in CQ 
% TE conc = weighted average of TE samples by purchase quantity 

% create discrete distributions of trace element concentrations in coal 
LDL_flag = 0.7; % LDL flag = 0.7 means do nothing, LDL flag 0 means set the concentration of all LDL samples to zero 
% [cq_hg_2015, cq_se_2015, cq_as_2015, cq_cl_2015, plants_no_cl_data] = ...
%     coalqual_dist_uncorrelated(coal_gen_boiler_apcd, coal_purchases_2015, 0, LDL_flag);
% correlated apporach 
[coalqual_samples, cfpp_coal_purch] = ...
    coalqual_dist(coal_gen_boiler_apcd, coal_purchases_2015, 0, LDL_flag);

% calculate generation associated with chlorine plants removed 
% plants_no_cl_data = array2table(plants_no_cl_data(plants_no_cl_data > 1));
% plants_no_cl_data.Properties.VariableNames = {'Plant_Code'}; 
% plants_no_cl_data = innerjoin(plants_no_cl_data, plant_gen); 
% fprintf('generation of chlorine plants removed (TWh) %1.0f\n', sum(plants_no_cl_data.Gen_MWh)/1e6); 

% gather list of counties that operate a preparation plant 
% prep_purchases = coal_purchases_2015(strcmp(coal_purchases_2015.Coalmine_Type, 'P'),:); 

trials = 10000; % define the number of trials for bootstrapping

% bootstrap TE concentrations in coal blends for all plants in analysis 
% to perform extremization, uncomment lines 
% boot_cq_TE = boot_coal_blend_conc_uncorr(coal_gen_boiler_apcd, cq_hg_2015, ...
%     cq_se_2015, cq_as_2015, cq_cl_2015, trials); 
% correlated approach, default 
boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_apcd, coalqual_samples, ...
    cfpp_coal_purch, trials);
% correlated approach with coal preparation purchases accounted for 
% boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_apcd, coalqual_samples, ...
%     cfpp_coal_purch, trials, prep_purchases);

% calculate median trace element concentration in the coal blend of each CFPP
input_te_ppm = zeros(size(coal_gen_boiler_apcd,1),4);
plant_list = table2array(cell2table(boot_cq_TE(:,1))); 
for k = 1:4
    for i = 1:size(coal_gen_boiler_apcd,1)
        input_te_ppm(i,k) = median(boot_cq_TE{coal_gen_boiler_apcd.Plant_Code(i) == ...
            plant_list,k+1}); 
    end 
end 

input_te_mass = zeros(size(coal_gen_boiler_apcd,1),4);
for k = 1:4
    for i = 1:size(coal_gen_boiler_apcd,1)
        input_te_mass(i,k) = coal_gen_boiler_apcd.Fuel_Consumed(i)*907.185*...
            median(boot_cq_TE{coal_gen_boiler_apcd.Plant_Code(i) == ...
            plant_list,k+1})*1e-6; 
    end 
end 
input_te_mass = horzcat(coal_gen_boiler_apcd(:,[1 8 9]), array2table(input_te_mass)); 
input_te_mass.Properties.VariableNames(end-3:end) = {'hg_kg','se_kg','as_kg','cl_kg'}; 

%% bootstrap trace element partitioning for each boiler 
trials = 10000;
extreme_flag = 0; % turn off extremization
boot_part_hg = boot_partitioning_link(coal_gen_boiler_apcd, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Hg', extreme_flag); 
boot_part_se = boot_partitioning_link(coal_gen_boiler_apcd, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Se'); 
boot_part_as = boot_partitioning_link(coal_gen_boiler_apcd, pm_removal, so2_removal, fgd_ww_ratio, trials, 'As'); 
boot_part_cl = boot_partitioning_link(coal_gen_boiler_apcd, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Cl');

%% Produce Figure 4 - median waste stream factors of trace elements for CFPPs included in analysis 
% prepare data for emissions across the US 
% calculate total annual emissions from all plants 
% calculate median and 95% CI of emissions 
[boot_blr_emis_hg, boot_plt_emis_hg, boot_blr_input_hg] = boot_coal_cq_part_lit(coal_gen_boiler_apcd, boot_cq_TE, boot_part_hg, ann_coal_gen, 'Hg');
[boot_blr_emis_se, boot_plt_emis_se, boot_blr_input_se] = boot_coal_cq_part_lit(coal_gen_boiler_apcd, boot_cq_TE, boot_part_se, ann_coal_gen, 'Se');
[boot_blr_emis_as, boot_plt_emis_as, boot_blr_input_as] = boot_coal_cq_part_lit(coal_gen_boiler_apcd, boot_cq_TE, boot_part_as, ann_coal_gen, 'As');
[boot_blr_emis_cl, boot_plt_emis_cl, boot_blr_input_cl] = boot_coal_cq_part_lit(coal_gen_boiler_apcd, boot_cq_TE, boot_part_cl, ann_coal_gen, 'Cl');

close all; 
% Plot SI Figure - median waste stream factors of trace elements for coal boilers included in analysis 
plot_med_emf_cdf_blr(boot_blr_emis_hg, boot_blr_emis_se, boot_blr_emis_as, boot_blr_emis_cl);
% Plot Figure - median waste stream factors of trace elements for CFPPs included in analysis 
plot_med_emf_cdf_plt(boot_plt_emis_hg, boot_plt_emis_se, boot_plt_emis_as, boot_plt_emis_cl); % create separate function for plant level modeling, some subtleties  

%% SI Section - Compare trace element concentration from COALQUAL vs 
% MATS ICR (refered to as the hazardous air pollutants (HAPS) dataset) 
[plant_trace_haps, haps_plant_data, haps_sampling_months] = read_in_haps_coal_data; % reads in input data

% estimate trace element concentration in coal blends using 2010 coal
% purchase data
% read in 2010 coal purchases
disp('ignore total percent generation ... outputs in this section'); 
[coal_gen_boilers_2010, coal_purchases_2010] = ...
    compile_coal_purchases(coal_gen_boilers, ann_coal_gen, num_coal_plants, 2010); % import coal_purchases in 2010

% create 2010 distribution of trace element concentrations in coal at the plant level 
LDL_flag = 0.7; 
% old method
% [cq_hg_2010, cq_se_2010, cq_as_2010, cq_cl_2010, plants_no_cl_data_2010] = ...
%     coalqual_dist_uncorrelated(coal_gen_boilers_2010, coal_purchases_2010, haps_sampling_months, LDL_flag);
% 
% boot_cq_TE_2010 = boot_coal_blend_conc_uncorr(coal_gen_boilers_2010, cq_hg_2010, cq_se_2010, cq_as_2010, cq_cl_2010, trials);

% new method 
[coalqual_samples, cfpp_coal_purch] = ...
    coalqual_dist(coal_gen_boiler_apcd, coal_purchases_2010, haps_sampling_months, LDL_flag);

% bootstrap TE concentrations in coal blends for all plants in analysis 
boot_cq_TE_2010 = boot_coal_blend_conc(coal_gen_boilers_2010, coalqual_samples, ...
    cfpp_coal_purch, trials);

boot_cq_TE_2010_tbl = cell2table(boot_cq_TE_2010); % convert to table 
boot_cq_TE_2010_tbl.Properties.VariableNames = {'Plant_Code','hg_ppm','se_ppm','as_ppm','cl_ppm'}; 
% boot_cq_TE_2010_tbl = boot_cq_TE_2010_tbl(plants_no_cl_data_2010 == 0,:); 

% calculate difference between HAPS ppm and COALQUAL ppm 
comp_cq_haps = innerjoin(boot_cq_TE_2010_tbl, plant_trace_haps); % merge HAPS data with CQ bootstrap  
med_ppm_dif = zeros(size(comp_cq_haps,1),4); % initialize array to store ppm difference 
med_ppm_haps = nan(size(comp_cq_haps,1),4); % initialize array to store median haps concentrations
cq_ppm = zeros(size(comp_cq_haps,1),4); 
haps_ppm = zeros(size(comp_cq_haps,1),4); 
for k = 1:4
    for i = 1:size(comp_cq_haps,1)
        cq_ppm(i,k) = median(comp_cq_haps{i,k+1}{1,1});
        haps_ppm(i,k) = median(comp_cq_haps{i,k+5}{1,1});
        if isnan(haps_ppm(i,k)) == 1
            med_ppm_dif(i,k) = nan; 
        else
            med_ppm_haps(i,k) = haps_ppm(i,k); 
            med_ppm_dif(i,k) = cq_ppm(i,k) - haps_ppm(i,k); 
        end 
    end 
end 

% Plot SI Figure - Compare trace element concentrations between COALQUAL (CQ) and HAPS 
close all; 
plot_mats_cq_coal_comp(comp_cq_haps, med_ppm_dif);

% summary statistics - number of plants in MATS ICR 
counts = zeros(1,4); 
for k = 1:4
    for i = 1:size(plant_trace_haps,1)
        if size(plant_trace_haps{i,k+1}{1,1},1) > 0
            counts(1,k) = counts(1,k) + 1;
        end 
    end 
end 
fprintf('number of plants in MATS ICR for Hg, Se, As, and Cl: %3.0f, %3.0f, %3.0f, %3.0f\n', counts);

gen_haps = innerjoin(plant_trace_haps(:,{'Plant_Code'}), coal_gen_boilers_2010); 
fprintf('Generation in 2010 produced by plants in MATS ICR and all coal in 2010: %3.0f %3.0f\n', ...
    sum(gen_haps.Net_Generation_Year_To_Date)/1e6, sum(coal_gen_boilers_2010.Net_Generation_Year_To_Date)/1e6) % only covers about 46% of coal generation 

fprintf('number of plants in CQ and HAPS: %3.0f\n', size(comp_cq_haps,1)); 
gen_haps_cq = innerjoin(comp_cq_haps(:,{'Plant_Code'}), coal_gen_boilers_2010); 
fprintf('Generation in 2010 produced by plants in both MATS ICR and CQ: %3.0f\n', ...
    sum(gen_haps_cq.Net_Generation_Year_To_Date)/1e6); 
fprintf('number of plants in common for Hg, Se, As, and Cl: %3.0f, %3.0f, %3.0f, %3.0f\n', ...
    sum(~isnan(med_ppm_dif(:,1))), sum(~isnan(med_ppm_dif(:,2))), sum(~isnan(med_ppm_dif(:,3))), sum(~isnan(med_ppm_dif(:,4)))); 
fprintf('median MATS conc Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', median(haps_ppm,'omitnan')); 
fprintf('median CQ conc Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', median(cq_ppm,'omitnan')); 
fprintf('median dif conc Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', median(med_ppm_dif,'omitnan')); 
fprintf('median percent errors Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', median(med_ppm_dif./med_ppm_haps*100,'omitnan')); 
fprintf('mean percent errors Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', mean(med_ppm_dif./med_ppm_haps*100,'omitnan')); 

%% SI Section - compare partitioning to solid + liquid from MATS ICR against results from literature
% input coal and emissions data from the MATS ICR dataset
partition_haps_data = partition_gas_haps(haps_plant_data); 

% bootstrap partitioning coefficients from hap air pollution control device data 
boot_part_hg_haps_v2 = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Hg', extreme_flag); 
boot_part_hg_haps = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Hg'); 
boot_part_se_haps = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Se'); 
boot_part_as_haps = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'As'); 
boot_part_cl_haps = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Cl');

% estimate partitioning to not air (solids + liquids) from the MATS ICR 
% compare partitioning between literature and MATS ICR 
comp_lit_mats_hg_v2 = comp_TE_partitioning(partition_haps_data, boot_part_hg_haps_v2, 'Hg');
comp_lit_mats_hg = comp_TE_partitioning(partition_haps_data, boot_part_hg_haps, 'Hg');
comp_lit_mats_se = comp_TE_partitioning(partition_haps_data, boot_part_se_haps, 'Se');
comp_lit_mats_as = comp_TE_partitioning(partition_haps_data, boot_part_as_haps, 'As');
comp_lit_mats_cl = comp_TE_partitioning(partition_haps_data, boot_part_cl_haps, 'Cl');

% plot SI figure comparing removals 
close all; 
plot_mats_lit_partition_comp(comp_lit_mats_hg, comp_lit_mats_se, comp_lit_mats_as, comp_lit_mats_cl);

% summary statistics - calculate generation in the MATS ICR - literature comparison dataset
foo = unique(vertcat(comp_lit_mats_hg(:,{'Plant_Boiler'}), comp_lit_mats_se(:,{'Plant_Boiler'}),...
    comp_lit_mats_as(:,{'Plant_Boiler'}), comp_lit_mats_cl(:,{'Plant_Boiler'}))); 
foo = innerjoin(foo, coal_gen_boilers_2010(:,{'Plant_Boiler','Net_Generation_Year_To_Date'})); 
disp('fraction of coal generation from the MATS ICR - literature comparison dataset'); 
sum(foo.Net_Generation_Year_To_Date)/sum(coal_gen_boilers_2010.Net_Generation_Year_To_Date)

%% Compare bootstrapped mercury estimates to air against CEMS 
% Load CEMS data
% data generated from cems_hg_data/combine_annual_cems_data.m
load('cems_hg_data/cems_hg_emf_2015.mat'); 
cems_hg_emf_2015.Properties.VariableNames(end) = {'cems_hg_emf_mg_MWh'};

% median of mercury estimates exiting CFPPs in air 
med_hg_emf_stack = zeros(size(boot_blr_emis_hg,1),1); 
for i = 1:size(boot_blr_emis_hg,1)
    hg_emf = boot_blr_emis_hg.emf_mg_MWh{i,1};
    med_hg_emf_stack(i) = median(hg_emf(:,3));
end 

med_hg_emf_stack = horzcat(boot_blr_emis_hg, array2table(med_hg_emf_stack)); 
comp_boot_cems_hg = innerjoin(med_hg_emf_stack, cems_hg_emf_2015); 
comp_boot_cems_hg = innerjoin(comp_boot_cems_hg, coal_gen_boiler_apcd(:,{'Plant_Boiler','Energy_Source_1'})); 
comp_boot_cems_hg(:,end+1) = array2table(comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh);
comp_boot_cems_hg.Properties.VariableNames(end) = {'dif'}; 

% summary statistics - median of CEMS, estimates, and difference of CEMS
% and estimates
fprintf('median CEMS emf, median bootstrap emf, and median difference emf: %2.2f, %2.2f, %2.2f \n', ...
    median(comp_boot_cems_hg.cems_hg_emf_mg_MWh), ...
    median(comp_boot_cems_hg.med_hg_emf_stack), ...
    median(comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh)); 

%% Figure - summarizes all comparison results 
% summarize coal concentration comparison 
plot_coal_comp_summary(med_ppm_dif, med_ppm_haps); 

% summarize partitioning comparision  
plot_partition_comp_summary(comp_lit_mats_hg, comp_lit_mats_se, comp_lit_mats_as, comp_lit_mats_cl);

% summarize Hg gas phase emission comparison  
plot_cems_comparison(comp_boot_cems_hg)

% summarize mass flow rates to wFGD waste stream comparison 
plot_wfgd_comp(boot_plt_emis_hg, boot_plt_emis_se, boot_plt_emis_as, boot_plt_emis_cl); 

% error('success'); % goal post used to save time

%% SI Section - figure of Hg emissions when selecting minimum coal concentration and max 
% This analysis requires a lot of set up. Proceed with caution 

% partitioning vs median run results

% create CDF of differences in medians 
% med_dif_min = comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh; % estimated - actual 
% med_dif_med = comp_boot_cems_hg_v2.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh; 
% 
% close all; 
% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.15 0.25 0.7 0.7]) % x pos, y pos, x width, y height
% 
% hold on;
% plotx = sort(med_dif_med); 
% ploty = linspace(0,1,size(plotx,1));
% plot(plotx,ploty,'k','LineWidth',1.8);
% 
% plotx = sort(med_dif_min); 
% ploty = linspace(0,1,size(plotx,1));
% plot(plotx,ploty,'r--','LineWidth',1.8);
% 
% xlabel({'Difference of modeled and CEMS', ... 
%     'generation normalized Hg gas phase',...
%     'emissions (mg/MWh)'});
% ylabel('F(x)'); 
% 
% set(gca,'FontName','Arial','FontSize',13)
% a=gca;
% set(a,'box','off','color','none')
% % axis([-25 75 0 70]); 
% % axis([-20 60 0 1]); 
% b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
% axes(a)
% linkaxes([a b])
% legend('Mininum estimate', 'Median estimate','Location','southeast');
% legend boxoff; 
% 
% % 
% print('../Figures/FigSI_cems_min_hg_cdf','-dpdf','-r300') % save figure (optional)

%% examine boilers that have positive emissions even after extremizing 
% used for debugging and testing 
% boiler_input = zeros(size(coal_gen_boiler_apcd,1),4);
% for i = 1:size(coal_gen_boiler_apcd,1)
%     boiler_input(i,1) = median(boot_cq_TE{coal_gen_boiler_apcd.Plant_Code(i) == ...
%         plant_list,2}); 
%     boiler_input(i,2:4) = median(boot_part_hg{i,3});
% end 
% boiler_input = horzcat(coal_gen_boiler_apcd(:,[1 7 8 14]), array2table(boiler_input));
% boiler_input.Properties.VariableNames(5:end) = {'hg_ppm','hg_part_sol','hg_part_liq','hg_part_gas'}; 
% boiler_input = innerjoin(boiler_input, comp_boot_cems_hg(:,[2 9 13 14])); 
% plant_input.Properties.VariableNames = {'Plant_Code','hg_ppm','se_ppm','as_ppm','cl_ppm'}; 

%% SI Section 1 - Calculate coal generation at each eGRID subregion 
% read in eGRID subregion data
[num,txt,raw] = xlsread('../data/egrid/egrid2014_data_v2.xlsx','PLNT14'); % pull coalqual upper level with fips data  

egrid_subrgns = cell2table(raw(3:end,[4 12])); % name the coalqual data as strat_table 
egrid_subrgns.Properties.VariableNames = {'Plant_Code','egrid_subrgn'}; % set the table headers 

coal_blrs_egrid = innerjoin(coal_generators, egrid_subrgns); % merge coal boilers (note, this includes all coal boilers) with egrid subregions
subrgn_list = unique(egrid_subrgns.egrid_subrgn);  % compile list of subrgns 
subrgn_list(1,:) = []; % remove first row which is blank 

% for each subrgn, count the number of coal plants, add up coal capacity,
% add up coal generation, and calculate coal capacity factor 
num_cap_gen_cf = zeros(size(subrgn_list,1),8); 
for i = 1:size(subrgn_list,1)
    index = strcmp(coal_blrs_egrid.egrid_subrgn,subrgn_list{i,1});
    num_cap_gen_cf(i,1) = size(unique(coal_blrs_egrid.Plant_Code(index)),1); 
    num_cap_gen_cf(i,2) = sum(coal_blrs_egrid.Net_Generation_Year_To_Date(index))/1e6; 
    num_cap_gen_cf(i,3) = sum(coal_blrs_egrid.Nameplate_Capacity_MW(index))/1e3; 
    num_cap_gen_cf(i,4) = num_cap_gen_cf(i,2)*1e3/(num_cap_gen_cf(i,3)*8760); 
end 

% subrgn_coal_summary is used to create Table S5 in SI Section ??

% compare eGRID level stats with boilers included in analysis 
coal_gen_boiler_apcd_egrid = innerjoin(coal_gen_boiler_apcd, egrid_subrgns);
for i = 1:size(subrgn_list,1)
    index = strcmp(coal_gen_boiler_apcd_egrid.egrid_subrgn,subrgn_list{i,1});
    num_cap_gen_cf(i,5) = size(unique(coal_gen_boiler_apcd_egrid.Plant_Code(index)),1); 
    num_cap_gen_cf(i,6) = sum(coal_gen_boiler_apcd_egrid.Net_Generation_Year_To_Date(index))/1e6; 
end 
num_cap_gen_cf(:,7) = num_cap_gen_cf(:,5)./num_cap_gen_cf(:,1)*100; 
num_cap_gen_cf(:,8) = num_cap_gen_cf(:,6)./num_cap_gen_cf(:,2)*100; 

subrgn_coal_summary = horzcat(subrgn_list, table2cell(array2table(num_cap_gen_cf))); 

%% SI Section - calculate fraction of coal purchases that are prepared 
% see directory SI_coal_prep, load 'coal_prep_data.mat', run line 105 in
% script SI_coal_prep_eia

%% SI Section - variability of coal samples in COALQUAL
% extract coalqual data 
[num,txt,raw] = xlsread('../data/coalqual/coalqual_upper_wfips.xlsx','Sheet1'); % pull coalqual upper level with fips data  

coalqual_samples = cell2table(raw(2:end,:)); % name the coalqual data as strat_table 
coalqual_samples.Properties.VariableNames = raw(1,:); % set the table headers 

% find range of trace element concentrations at each county 
counties = unique(coalqual_samples.fips_code); 
coal_var_county = zeros(size(counties,1),5); 
coal_var_county(:,1) = counties; 
for i = 1:size(counties,1)
    coal_conc = coalqual_samples.Hg(coalqual_samples.fips_code == counties(i));
    coal_var_county(i,2) = max(coal_conc) - min(coal_conc); 
    coal_conc = coalqual_samples.Se(coalqual_samples.fips_code == counties(i));
    coal_var_county(i,3) = max(coal_conc) - min(coal_conc); 
    coal_conc = coalqual_samples.As(coalqual_samples.fips_code == counties(i));
    coal_var_county(i,4) = max(coal_conc) - min(coal_conc); 
    coal_conc = coalqual_samples.Cl(coalqual_samples.fips_code == counties(i));
    coal_var_county(i,5) = max(coal_conc) - min(coal_conc); 
end 
coal_var_county = array2table(coal_var_county); 
coal_var_county.Properties.VariableNames = {'counties','Hg','Se','As','Cl'}; 

% plot figure 
close all; 
% plot_coalqual_samples_v2(coal_var_county, coalqual_samples, 'Hg'); 
plot_coalqual_samples_v2(coal_var_county, coalqual_samples, 'Se'); 
plot_coalqual_samples_v2(coal_var_county, coalqual_samples, 'As'); 
plot_coalqual_samples_v2(coal_var_county, coalqual_samples, 'Cl'); 

% plot_coalqual_samples(coalqual_samples, 'Cl'); 
%% Plot SI Figure - boxplots of TE concentraitons in coal blend at plant level
close all;
plot_boot_coal_blend(boot_cq_TE, 'Hg');
plot_boot_coal_blend(boot_cq_TE, 'Se');
plot_boot_coal_blend(boot_cq_TE, 'As');
plot_boot_coal_blend(boot_cq_TE, 'Cl'); 

% Plot Figure - CDF of median of coal blends 
% close all;
[conc_stats_hg, conc_stats_se, conc_stats_as, conc_stats_cl] = plot_med_coal_blend(boot_cq_TE);

% summary statistics - calculate min, median, max, and mean of trace element conc in coal blends 
disp('min, median, and max of trace element concentrations of all plants for Hg, Se, As, and Cl'); 
[min(conc_stats_hg.median), median(conc_stats_hg.median), max(conc_stats_hg.median)]
[min(conc_stats_se.median), median(conc_stats_se.median), max(conc_stats_se.median)]
[min(conc_stats_as.median), median(conc_stats_as.median), max(conc_stats_as.median)]
[min(conc_stats_cl.median), median(conc_stats_cl.median), max(conc_stats_cl.median)]

disp('mean of the median concentration of Hg, Se, As, and Cl in coal blends of all plants in analysis'); 
[mean(conc_stats_hg.median), mean(conc_stats_se.median), mean(conc_stats_as.median), mean(conc_stats_cl.median)]

%% plot coal blend concentrations CDFs by eGRID subregion (section may be excluded from SI Section)
% read in eGRID subregion data
[num,txt,raw] = xlsread('../data/egrid/egrid2014_data_v2.xlsx','PLNT14'); % pull coalqual upper level with fips data  

egrid_subrgns = cell2table(raw(3:end,[4 12])); % name the coalqual data as strat_table 
egrid_subrgns.Properties.VariableNames = {'Plant_Code','egrid_subrgn'}; % set the table headers 

% merge coal data with egrid subregion data 
boot_cq_TE_tbl = cell2table(boot_cq_TE); 
boot_cq_TE_tbl.Properties.VariableNames = {'Plant_Code','hg_ppm','se_ppm','as_ppm','cl_ppm'}; 
boot_cq_TE_subrgn = innerjoin(boot_cq_TE_tbl, egrid_subrgns); 

close all; 
subrgn_list = unique(boot_cq_TE_subrgn.egrid_subrgn); 
plot_med_coal_blend_egrid(boot_cq_TE_subrgn,subrgn_list);

%% SI Section: median trace element partitioning for each boiler 
plot_med_partition_cdf(boot_part_hg, boot_part_se, boot_part_as, boot_part_cl);

% summary statistics - calculate median partitioning of each boiler 
boot_part_TE = boot_part_cl; % for other trace element, use boot_part_hg, boot_part_se, boot_part_as, or boot_part_cl;
meds = zeros(size(boot_part_TE,1),3); 
for i = 1:size(boot_part_TE)
    meds(i,:) = median(boot_part_TE{i,3}); 
end 
disp('minimum and maximum median partitioning to solid, liq, and air of boilers in the fleet'); 
min(meds)
max(meds)

%% SI Section calculate generation associated with air pollution controls  
% determine generation across the fleet for single apcd type 
% gen_pm_ctrls, gen_so2_ctrls, gen_nox_ctrls, and gen_hg_ctrls are used to
% make Table S5
gen_pm_ctrls = single_apcd_generation(coal_gen_boiler_apcd, ann_coal_gen, 'PM'); 
gen_so2_ctrls = single_apcd_generation(coal_gen_boiler_apcd, ann_coal_gen, 'SO2'); 
gen_nox_ctrls = single_apcd_generation(coal_gen_boiler_apcd, ann_coal_gen, 'NOx'); 
% single_hg = single_apcd_generation(coal_gen_boiler_wapcd, 'Hg'); 
% calculate generation associated with mercury controls, this is better
% than the function above, because all boilers have a PM control installed,
% all boilers have a pseudo-PM control installed. Therefore, we use the
% modified function below. 
aci = floor(rem(coal_gen_boiler_apcd.apcds,10)); 
gen_hg_ctrls = zeros(2,2); 
gen_hg_ctrls(1,1) = sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date(aci == 1)); 
gen_hg_ctrls(2,1) = sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date) - gen_hg_ctrls(1,1);
gen_hg_ctrls = horzcat(cell2table({'ACI';'None'}), array2table(gen_hg_ctrls)); 
gen_hg_ctrls.Properties.VariableNames = {'apcd_type','generation','multi_gen'}; 
gen_hg_ctrls = sortrows(gen_hg_ctrls,'generation','descend');

% determine generation for combination of post-combustion air emission controls
% calculate generation for each unique apcd code 
% Data from gen_by_apcd_combo is used to create Table S2
gen_by_apcd_combo = unique(coal_gen_boiler_apcd.apcds); 
for i = 1:size(gen_by_apcd_combo,1)
    gen_by_apcd_combo(i,2) = sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date(...
        coal_gen_boiler_apcd.apcds == gen_by_apcd_combo(i,1)))/1e6;
end 
gen_by_apcd_combo(:,3) = floor(rem(gen_by_apcd_combo(:,1)/100,10));
gen_by_apcd_combo(:,4) = floor(rem(gen_by_apcd_combo(:,1)/1000,10));

% summary statistics - calculate generation associated with hsESP and ACI 
apcds = coal_gen_boiler_apcd.apcds; 
pm = floor(rem(apcds/100,10)); % PM controls installed at boilers
display('generation treated by hsESP / generation treated by csESP'); 
sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date(pm == 2))/...
    sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date(pm == 1))
aci = floor(rem(apcds,10)); % mercury controls installed at boilers
display('generation treated by ACI / coal generation'); 
sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date(aci == 1))/ann_coal_gen
display('generation treated by no ACI / coal generation'); 
sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date(aci == 0))/ann_coal_gen
% note that these do not add up to 1, because about 10% of coal generation
% is excluded from analysis 

%% SI Section - temporal variability 
% bootstrap concentrations of trace elements in the coal blend of each
% power plant for each month in 2015, this uses the uncorrelated scripts 
% takes about 2 minutes to run 
cq_month_hg = unique(coal_gen_boilers.Plant_Code); 
cq_month_se = unique(coal_gen_boilers.Plant_Code); 
cq_month_as = unique(coal_gen_boilers.Plant_Code); 
cq_month_cl = unique(coal_gen_boilers.Plant_Code); 
LDL_flag = 0.7; 
for i = 1:12
    month_purch = coal_purchases_2015(coal_purchases_2015.MONTH == i,:); 
    month_purch(month_purch.county == -1,:) = []; % remove purchases that are from counties that do not exist
    [cq_hg_month, cq_se_month, cq_as_month, cq_cl_month] = ...
        coalqual_dist_uncorrelated(coal_gen_boilers, month_purch, 0, LDL_flag);
    % skip plants that do not have purchases in the month 
%     if cq_hg_month{
    boot_cq = boot_coal_blend_conc_uncorr(coal_gen_boilers, cq_hg_month, cq_se_month, ...
        cq_as_month, cq_cl_month, trials);
    
    for j = 1:size(boot_cq,1)
        cq_month_hg(j,i+1) = median(boot_cq{j,2}); 
    end 
    for j = 1:size(boot_cq,1)
        cq_month_se(j,i+1) = median(boot_cq{j,3}); 
    end 
    for j = 1:size(boot_cq,1)
        cq_month_as(j,i+1) = median(boot_cq{j,4}); 
    end 
    for j = 1:size(boot_cq,1)
        cq_month_cl(j,i+1) = median(boot_cq{j,5}); 
    end 
    
end 
% plot result 
close all;
plot_coal_temporal_variation(cq_month_hg, cq_month_se, cq_month_as, cq_month_cl, plant_gen);

% count number of plants that purchase coal from a single county
flag = zeros(size(cfpp_coal_purch,1),1);
for i = 1:size(cfpp_coal_purch,1)
    if size(cfpp_coal_purch{i,2},1) == 1
        flag(i) = 1; 
    end 
end 
fprintf('Number of plants that purchase coal from a single county: %1.0f\n', sum(flag))
% estimate generation from plants that purchase coal from a single county 
test = cell2table(cfpp_coal_purch(flag == 1,1));
test.Properties.VariableNames = {'Plant_Code'};
test = innerjoin(test, plant_gen); 
fprintf('Generation from plants that purchase coal from a single county: %1.0f\n', sum(test.Gen_MWh)); 

%% Compare LDL = 0, LDL = 0.7, and LDL = 1
% this analysis is done with uncorrelated assumptions (assumes trace
% elements are independent of each other) 
plot_LDL_comp(coal_gen_boiler_apcd, coal_purchases_2015);

%% intentionally left blank
display('success, everything ran fine'); % script ran fine 
















%% Analysis that did not make it to paper:
%% correlation of trace elements against other trace elements in COALQUAL 
% results recorded in OneNote 
[num,txt,raw] = xlsread('../data/coalqual/coalqual_upper_wfips.xlsx','Sheet1'); % pull coalqual upper level with fips data  

% input all COALQUAL samples 
coalqual_samples = cell2table(raw(2:end,:)); % name the coalqual data as strat_table 
coalqual_samples.Properties.VariableNames = raw(1,:); % set the table headers 
coalqual_samples.Properties.VariableNames{10} = 'Apparent_Rank';

% plot correlation (qualitative analysis)
close all;
figure('Color','w','Units','inches','Position',[1.25 1.25 4 4]) % was 1.25
axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height

plot(coalqual_samples.Hg, coalqual_samples.Sulfur, '*'); 

set(gca,'FontName','Arial','FontSize',13)
a = gca;
xlabel('As concentration [ppm]');
ylabel('Cl concentration [ppm]');

set(a,'box','off','color','none')
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

% calculate linear regression (quantitative)
fitlm(coalqual_samples.As, coalqual_samples.Cl)

%% comparing Cl concentrations for MATS without plants that purchase coal from counties w/o Cl data
%% requires additional inputs from co-authors 
% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.15 0.2 0.7 0.7]) % x pos, y pos, x width, y height
% 
% divide_array = [0.3 15 20 1600]; % defined based on the max_trace, but it's an arbitrary rule, so there's no way to automate this process
% scale = max(divide_array); 
% hold on;
% 
% k = 4
% plotx = sort(dif_ds(:,k))*scale/divide_array(k);
% plotx(isnan(plotx)) = [];
% ploty = linspace(0,1,size(plotx,1));
% plot(plotx,ploty,'r-','LineWidth',1.8);
% 
% plotx = sort(dif_dg(:,k))*scale/divide_array(k);
% plotx(isnan(plotx)) = [];
% ploty = linspace(0,1,size(plotx,1));
% plot(plotx,ploty,'k--','LineWidth',1.8);
% 
% xlabel(['Difference in trace element concentration' char(10)...
%     'between model estimates and MATS ICR']);
% ylabel('F(x)');
% set(gca,'FontName','Arial','FontSize',13)
% a=gca;
% set(a,'box','off','color','none')
% % ylim([0 1]);
% axis([-scale scale 0 1]);
% b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
% axes(a)
% linkaxes([a b])
% a.XTick = linspace(-scale, scale, 5);
% % a.XTickLabel = {'1','2','3','4'};
% % legend(['Difference between' char(10) 'bootstrap and MATS ICR'],'MATS ICR');
% legend({'DS','DG'},'Location','SouthEast');
% legend boxoff;

%% Create median waste stream factors of trace elements for CFPPs by eGRID subregions
boot_plt_hg_egrid = innerjoin(boot_plt_emis_hg, egrid_subrgns); 
boot_plt_se_egrid = innerjoin(boot_plt_emis_se, egrid_subrgns); 
boot_plt_as_egrid = innerjoin(boot_plt_emis_as, egrid_subrgns); 
boot_plt_cl_egrid = innerjoin(boot_plt_emis_cl, egrid_subrgns); 

% close all; 
for i = 1:size(subrgn_list,1)
    subrgn_hg = boot_plt_hg_egrid(strcmp(boot_plt_hg_egrid.egrid_subrgn, subrgn_list{i,1}),:);
    subrgn_se = boot_plt_se_egrid(strcmp(boot_plt_se_egrid.egrid_subrgn, subrgn_list{i,1}),:);
    subrgn_as = boot_plt_as_egrid(strcmp(boot_plt_as_egrid.egrid_subrgn, subrgn_list{i,1}),:);
    subrgn_cl = boot_plt_cl_egrid(strcmp(boot_plt_cl_egrid.egrid_subrgn, subrgn_list{i,1}),:);
    plot_med_emf_cdf_plt_subrgn(subrgn_hg, subrgn_se, subrgn_as, subrgn_cl, subrgn_list{i,1}) % create separate function for plant level modeling, some subtleties
end 

clear subrgn_hg subrgn_se subrgn_as subrgn_cl;  

