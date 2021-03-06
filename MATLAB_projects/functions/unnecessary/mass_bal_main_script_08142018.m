% description needed 

clear; clc; close all;
warning('off','all');
% add folders for functions in different directory 
addpath('utility_scripts'); % contains data scrubbing functions
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

%% Create Figure 2 - partitioning of trace elements by literature study
% Calculate partitioning by air pollution control for each study 
% further fixing required; 
% data in lit_partition_apcd_all used to create Table S4 
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
% fix apc codes for a few entries
% [part_by_apc_link, part_by_apc_whole] = ...
%     plot_link_vs_whole_partition(pm_removal, so2_removal, lit_phases_by_TE, fgd_ww_ratio);

%% Estimate TE concentrations in coal blends by bootstrapping
% For each coal purchase, find location of coal purchase
% for each location, randomly draw one sample from all coal samples at that location in CQ 
% TE conc = weighted average of TE samples by purchase quantity 

% create discrete distributions of trace element concentrations in coal 
LDL_flag = 0.7; % LDL flag = 0 means do nothing, LDL flag 1 means set all LDLs to zero 
[cq_hg_2015, cq_se_2015, cq_as_2015, cq_cl_2015, plants_no_cl_data] = ...
    coalqual_dist(coal_gen_boiler_apcd, coal_purchases_2015, 0, LDL_flag);

% calculate generation associated with chlorine plants removed 
% plants_no_cl_data = array2table(plants_no_cl_data(plants_no_cl_data > 1));
% plants_no_cl_data.Properties.VariableNames = {'Plant_Code'}; 
% plants_no_cl_data = innerjoin(plants_no_cl_data, plant_gen); 
% fprintf('generation of chlorine plants removed (TWh) %1.0f\n', sum(plants_no_cl_data.Gen_MWh)/1e6); 

trials = 10000; % define the number of trials for bootstrapping
% bootstrap TE concentrations in coal blends for all plants in analysis 
boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_apcd, cq_hg_2015, cq_se_2015, ...
    cq_as_2015, cq_cl_2015, trials);

% boot_cq_TE_test = boot_coal_blend_conc_verify_dg(coal_gen_boiler_apcd, cq_hg_2015, cq_se_2015, ...
%     cq_as_2015, cq_cl_2015, trials);

% calculate median trace element concentration in the coal blend of each CFPP
input_te_ppm = zeros(size(coal_gen_boiler_apcd,1),4);
for k = 1:4
    for i = 1:size(coal_gen_boiler_apcd,1)
        input_te_ppm(i,k) = median(boot_cq_TE{coal_gen_boiler_apcd.Plant_Code(i) == ...
            boot_cq_TE(:,1),k+1}); 
    end 
end 

input_te_mass = zeros(size(coal_gen_boiler_apcd,1),4);
for k = 1:4
    for i = 1:size(coal_gen_boiler_apcd,1)
        input_te_mass(i,k) = coal_gen_boiler_apcd.Fuel_Consumed(i)*907.185*...
            median(boot_cq_TE{coal_gen_boiler_apcd.Plant_Code(i) == ...
            boot_cq_TE_test(:,1),k+1})*1e-6; 
    end 
end 
input_te_mass = horzcat(coal_gen_boiler_apcd(:,[1 8 9]), array2table(input_te_mass)); 
input_te_mass.Properties.VariableNames(end-3:end) = {'hg_kg','se_kg','as_kg','cl_kg'}; 

%% bootstrap trace element partitioning for each boiler 
% convert partitioning by air pollution controls to phases 
% the cells lit_phases_* are used to create Table S3??
% [lit_phases_hg, lit_phases_se, lit_phases_as, lit_phases_cl] = partition_by_apcd_to_phases(lit_partition_US);

% wFGD partitioning for the pavlish papers should be combined into a single
% paper because they report from the same piece (not upstream pm controls
% are independent) 
% bootstrap trace element partitioning for each boiler 
trials = 10000;

boot_part_hg = boot_partitioning_link(coal_gen_boiler_apcd, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Hg'); 
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

%%
close all; 
% Plot Figure S7 - median waste stream factors of trace elements for coal boilers included in analysis 
% test = plot_med_emf_cdf_blr(boot_blr_emis_hg, boot_blr_emis_se, boot_blr_emis_as, boot_blr_emis_cl);
% Plot Figure 4 - median waste stream factors of trace elements for CFPPs included in analysis 
test = plot_med_emf_cdf_plt(boot_plt_emis_hg, boot_plt_emis_se, boot_plt_emis_as, boot_plt_emis_cl); % create separate function for plant level modeling, some subtleties  

%% SI Section 12 - Compare trace element concentration from COALQUAL vs 
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
[cq_hg_2010, cq_se_2010, cq_as_2010, cq_cl_2010, plants_no_cl_data_2010] = ...
    coalqual_dist(coal_gen_boilers_2010, coal_purchases_2010, haps_sampling_months, LDL_flag);

boot_cq_TE_2010 = boot_coal_blend_conc(coal_gen_boilers_2010, cq_hg_2010, cq_se_2010, cq_as_2010, cq_cl_2010, trials);

% boot_cq_TE_2010 = boot_coal_blend_conc_verify_dg(coal_gen_boilers_2010, cq_hg_2010, cq_se_2010, cq_as_2010, cq_cl_2010, trials);
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
%         cq_ppm(i,k) = comp_cq_haps{i,k+1};
        haps_ppm(i,k) = median(comp_cq_haps{i,k+5}{1,1});
        if isnan(haps_ppm(i,k)) == 1
            med_ppm_dif(i,k) = nan; 
        else
            med_ppm_haps(i,k) = haps_ppm(i,k); 
            med_ppm_dif(i,k) = cq_ppm(i,k) - haps_ppm(i,k); 
        end 
    end 
end 
%%
% Plot SI Figure 12 - Compare trace element concentrations between COALQUAL (CQ) and HAPS 
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


%% Produce Figure 6 - compare bootstrapped mercury estimates to air against CEMS 
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
% Plot Figure 6 - histogram and cdf comparing  
comp_boot_cems_hg = innerjoin(med_hg_emf_stack, cems_hg_emf_2015); 
close all; 
plot_cems_comparison(comp_boot_cems_hg)

% summary statistics - median of CEMS, estimates, and difference of CEMS
% and estimates
fprintf('median CEMS emf, median bootstrap emf, and median difference emf: %2.2f, %2.2f, %2.2f \n', ...
    median(comp_boot_cems_hg.cems_hg_emf_mg_MWh), ...
    median(comp_boot_cems_hg.med_hg_emf_stack), ...
    median(comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh)); 

%% detailed side analysis on cems mercury estimates
comp_boot_cems_hg = innerjoin(med_hg_emf_stack, cems_hg_emf_2015); % from main script
% mercury has an emission limit of 18 mg/MWh (for lignite fuels) and a
% limit of 6 mg/MWh for non lignite fuels
% need to explore what is causing emissions to be so far off 
comp_boot_cems_hg(:,end+1) = array2table(comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh); % estimated - actual 
comp_boot_cems_hg.Properties.VariableNames{end} = 'med_dif';

% append trace element in coal conc 
comp_boot_cems_hg = innerjoin(comp_boot_cems_hg, boot_cq_TE_tbl(:,1:2)); 
foo = zeros(size(comp_boot_cems_hg,1),1); 
for i = 1:size(foo,1)
    foo(i,1) = median(comp_boot_cems_hg.hg_ppm{i,1});
end 
comp_boot_cems_hg(:,end+1) = array2table(foo); 
comp_boot_cems_hg.Properties.VariableNames(end) = {'hg_ppm_med'}; 

overest_hg = comp_boot_cems_hg(comp_boot_cems_hg.med_dif > 18, :); 
overest_hg = innerjoin(overest_hg, coal_gen_boiler_apcd(:,[4 8:end]));
% From playing around with the data, I find that the largest emission
% differences correspond to plants with the largest estimates of hg waste stream to air 
% for example, compare these:
comp_boot_cems_hg = sortrows(comp_boot_cems_hg,'med_hg_emf_stack','descend');
overest_hg = sortrows(overest_hg,'med_hg_emf_stack','ascend');

% append fuel consumption information
comp_boot_cems_hg = innerjoin(comp_boot_cems_hg, coal_gen_boiler_apcd(:,{'Plant_Boiler','Fuel_Consumed'})); 

% estimate required hg removal assuming coal estimates are correct
emf_input = (comp_boot_cems_hg.hg_ppm_med*1e-6.*...
    comp_boot_cems_hg.Fuel_Consumed*2000*453*1e3)./comp_boot_cems_hg.Gen_MWh; %ppm * tons * lbs/tons * g/lbs * mg/g
part_req = (emf_input - comp_boot_cems_hg.cems_hg_emf_mg_MWh)./emf_input; 
boot_part_hg_med = boot_part_hg; 
for i = 1:size(boot_part_hg_med,1)
    boot_part_hg_med(i,4) = {1 - median(boot_part_hg{i,3}(:,3))}; % partition to liq + solids
end
boot_part_hg_med = cell2table(boot_part_hg_med);
boot_part_hg_med.Properties.VariableNames = {'Plant_Code','Plant_Boiler','part','med_part'}; 
comp_boot_cems_hg = innerjoin(comp_boot_cems_hg, boot_part_hg_med(:,{'Plant_Boiler','med_part'})); 
comp_boot_cems_hg = horzcat(comp_boot_cems_hg, array2table(part_req));
comp_boot_cems_hg.Properties.VariableNames(end) = {'req_part'}; 
% take difference of required and estimate partitioning 
comp_boot_cems_hg(:,end+1) = array2table(comp_boot_cems_hg.med_part - comp_boot_cems_hg.req_part); 
comp_boot_cems_hg.Properties.VariableNames(end) = {'dif_part'}; 

% estimate required hg concentration assuming hg removals are accurate
comp_boot_cems_hg = innerjoin(comp_boot_cems_hg, coal_gen_boiler_apcd(:,{'Plant_Boiler','apcds'})); 

fitlm(comp_boot_cems_hg.med_part, comp_boot_cems_hg.med_dif)

figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.25 0.23 0.7 0.7]) % x pos, y pos, x width, y height

plot(comp_boot_cems_hg.med_part, comp_boot_cems_hg.med_dif,'k*'); 

xlabel({'Median bootstrapped partitioning','coefficient at the boiler level'});
ylabel({'Difference of bootstrapped and', 'CEMS Hg emission factor (mg/MWh)'}); 

set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

print('../Figures/Fig_part_vs_CEMS_dif','-dpdf','-r300') % save figure (optional)



%% SI Section 13 - compare partitioning to solid + liquid from MATS ICR against results from literature
% input coal and emissions data from the MATS ICR dataset
partition_haps_data = partition_solid_liq_haps(haps_plant_data); 

% bootstrap partitioning coefficients from hap air pollution control device data 
boot_part_hg_haps = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Hg'); 
boot_part_se_haps = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Se'); 
boot_part_as_haps = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'As'); 
boot_part_cl_haps = boot_partitioning_link(partition_haps_data, pm_removal, so2_removal, fgd_ww_ratio, trials, 'Cl');

% estimate partitioning to not air (solids + liquids) from the MATS ICR 
% compare partitioning between literature and MATS ICR 
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

%% create figure that summarizes all comparison results 
% summarize coal concentration results 
close all; 
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.3 0.2 0.7 0.7]) % x pos, y pos, x width, y height

plot_array = median(med_ppm_dif./med_ppm_haps,'omitnan')*100;
bar(plot_array)

xlabel('Trace elements');
ylabel(['Coal concentration validation:' char(10) 'Median difference in' char(10) 'coal concentration (%)']);

a=gca;
set(a,'FontName','Arial','FontSize',13)
set(a,'box','off','color','none')
axis([0 5 0 100]); 
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

a.XTick = 1:4;
a.XTickLabel = {'Hg','Se','As','Cl'};

print('../Figures/Fig4A_coal_comp','-dpdf','-r300') % save figure 

%%
% summarize partitioning results 
close all;
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.3 0.2 0.7 0.7]) % x pos, y pos, x width, y height

% plot_array = [median(comp_lit_mats_hg.remov_dif./comp_lit_mats_hg.haps_med_remov) ...
%     median(comp_lit_mats_se.remov_dif./comp_lit_mats_se.haps_med_remov) ...
%     median(comp_lit_mats_as.remov_dif./comp_lit_mats_as.haps_med_remov) ...
%     median(comp_lit_mats_cl.remov_dif./comp_lit_mats_cl.haps_med_remov)]*100;
% plot_array = [median(comp_lit_mats_hg.gas_dif./comp_lit_mats_hg.haps_gas_part) ...
%     median(comp_lit_mats_se.gas_dif./comp_lit_mats_se.haps_gas_part) ...
%     median(comp_lit_mats_as.gas_dif./comp_lit_mats_as.haps_gas_part) ...
%     median(comp_lit_mats_cl.gas_dif./comp_lit_mats_cl.haps_gas_part)]*100;

plot_array = [median(comp_lit_mats_hg.gas_dif) ...
    median(comp_lit_mats_se.gas_dif) ...
    median(comp_lit_mats_as.gas_dif) ...
    median(comp_lit_mats_cl.gas_dif)];

bar(plot_array)

xlabel('Trace elements');
% ylabel(['Partitioning comparison' char(10) 'percent difference (%)']);
ylabel(['Partitioning validation:' char(10) 'Median difference in gas' char(10) 'partitioning coefficient (%)']);

a=gca;
set(a,'FontName','Arial','FontSize',13)
set(a,'box','off','color','none')
% axis([0 5 -35 0]); 

b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
axis([0 5 0 0.35]); 
% ylim([0 0.4]);

a.XTick = 1:4;
a.XTickLabel = {'Hg','Se','As','Cl'};

print('../Figures/Fig4B_part_comp','-dpdf','-r300') % save figure

%% 
% summarize ELG results In the Environmental Assessment of the Effluent
% Limitation Guidelines, the Environmental Protection Agency estimates flue
% gas desulfurization wastewater discharge from 88 coal plants.18 They
% report the average plant FGD wastewater discharge as 2.5 kg Hg/yr, 641 kg
% Se/yr, 4.3 kg As/yr and 4.6 million kg Cl/yr. See Table 3-4? 3-3. One of
% those tables in chapter 3 of the Environmental Assessment of the ELGs. 

% plot results
close all; 
figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
axes('Position',[0.3 0.2 0.7 0.7]) % x pos, y pos, x width, y height

elg_fgd = [2.5 641 4.3 4.6e6]; 
fgd_tot = zeros(size(boot_plt_emis_hg,1),4); 
for i = 1:size(boot_plt_emis_hg,1)
    fgd_tot(i,1) = boot_plt_emis_hg.emis_mg{i,1}(1,2);
end 
for i = 1:size(boot_plt_emis_se,1)
    fgd_tot(i,2) = boot_plt_emis_se.emis_mg{i,1}(1,2);
end 
for i = 1:size(boot_plt_emis_as,1)
    fgd_tot(i,3) = boot_plt_emis_as.emis_mg{i,1}(1,2);
end 
for i = 1:size(boot_plt_emis_cl,1)
    fgd_tot(i,4) = boot_plt_emis_cl.emis_mg{i,1}(1,2);
end 
fgd_avg = zeros(1,4); 
for k = 1:4
    fgd_avg(1,k) = sum(fgd_tot(:,k))/sum(fgd_tot(:,k) > 0)/1e6; 
end 

plot_array = (fgd_avg - elg_fgd)./elg_fgd*100;
bar(plot_array)

xlabel('Trace elements');
ylabel(['FGD waste stream validation:' char(10) 'Median difference in liquid' char(10) 'phase mass flow rate (%)']);

a=gca;
set(a,'FontName','Arial','FontSize',13)
set(a,'box','off','color','none')
xlim([0 5]);
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

a.XTick = 1:4;
a.XTickLabel = {'Hg','Se','As','Cl'};

print('../Figures/Fig4D_fgd_ww_comp','-dpdf','-r300') % save figure

%% End of main paper - Begin SI 
%% SI Section 1 - Calculate coal generation at each eGRID subregion 
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

%% Plot SI Figure - boxplots of TE concentraitons in coal blend at plant level
close all;
% plot_boot_coal_blend(boot_cq_TE, 'Hg');
% plot_boot_coal_blend(boot_cq_TE, 'Se');
% plot_boot_coal_blend(boot_cq_TE, 'As');
% plot_boot_coal_blend(boot_cq_TE, 'Cl'); % revise to plot fewer plants and plants with data 

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

%% plot SI Figure: coal blend concentrations CDFs by eGRID subregion 
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
% for i = 1:2 %size(subrgn_list,1)
% %     subrgn = subrgn_list{i,1};
% %     subrgn_cq = boot_cq_TE_subrgn(strcmp(boot_cq_TE_subrgn.egrid_subrgn,subrgn),:);
% %     plot_med_coal_blend_egrid(table2cell(subrgn_cq(:,1:5)),subrgn);
% end
% Regarding FRCC, only 2 plants have Cl concentrations in the FRCC subrgn.
% two purchase from similar counties with high chlorine concentrations in
% coal.


%% SI Section 4 - calculate fraction of coal purchases that are prepared 
% see directory SI_coal_prep, load 'coal_prep_data.mat', run line 105 in
% script SI_coal_prep_eia

%% SI Section 5 - variability of coal samples in COALQUAL
% extract coalqual data 
[num,txt,raw] = xlsread('../data/coalqual/coalqual_upper_wfips.xlsx','Sheet1'); % pull coalqual upper level with fips data  

coalqual_samples = cell2table(raw(2:end,:)); % name the coalqual data as strat_table 
coalqual_samples.Properties.VariableNames = raw(1,:); % set the table headers 
%%
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
%%
% plot figure 
close all; 
% plot_coalqual_samples_v2(coal_var_county, coalqual_samples, 'Hg'); 
plot_coalqual_samples_v2(coal_var_county, coalqual_samples, 'Se'); 
plot_coalqual_samples_v2(coal_var_county, coalqual_samples, 'As'); 
plot_coalqual_samples_v2(coal_var_county, coalqual_samples, 'Cl'); 

% plot_coalqual_samples(coalqual_samples, 'Cl'); 

%% SI Section 7: median trace element partitioning for each boiler 
test = plot_med_partition_cdf(boot_part_hg, boot_part_se, boot_part_as, boot_part_cl);

% summary statistics - calculate median partitioning of each boiler 
boot_part_TE = boot_part_cl; % for other trace element, use boot_part_hg, boot_part_se, boot_part_as, or boot_part_cl;
meds = zeros(size(boot_part_TE,1),3); 
for i = 1:size(boot_part_TE)
    meds(i,:) = median(boot_part_TE{i,3}); 
end 
disp('minimum and maximum median partitioning to solid, liq, and air of boilers in the fleet'); 
min(meds)
max(meds)

%% SI Section 8 - calculate generation associated with air pollution controls  
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
% is excluded from analysis see SI Section XX??

%% alternate way of calculate generation of air pollution controls at boilers
apcd_hg = floor(rem(apcds,10)); 
apcd_nox = floor(rem(apcds/10,10)); 
apcd_pm = floor(rem(apcds/100,10)); 
apcd_so2 = floor(rem(apcds/1000,10)); 

cond = apcd_pm == 1;
sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date(cond))/1e6
sum(coal_gen_boiler_apcd.Net_Generation_Year_To_Date(cond))/ann_coal_gen


%% SI Section 9 - temporal variability 
% bootstrap concentrations of trace elements in the coal blend of each
% power plant for each month in 2015
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
        coalqual_dist(coal_gen_boilers, month_purch, 0, LDL_flag);
    % skip plants that do not have purchases in the month 
%     if cq_hg_month{
    boot_cq = boot_coal_blend_conc(coal_gen_boilers, cq_hg_month, cq_se_month, ...
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

% count number of plants that purchase from a single county
flag = zeros(size(cq_hg_2015,1),1);
for i = 1:size(cq_hg_2015,1)
    if size(cq_hg_2015{i,2},1) == 1
        flag(i) = 1; 
    end 
end 
fprintf('Number of plants that purchase coal from a single county: %1.0f\n', sum(flag))
% estimate generation from plants that purchase coal from a single county 
test = cell2table(cq_hg_2015(flag == 1,1));
test.Properties.VariableNames = {'Plant_Code'};
test = innerjoin(test, plant_gen); 
fprintf('Generation from plants that purchase coal from a single county: %1.0f\n', sum(test.Gen_MWh)); 


%% comparing Cl concentrations for MATS without plants that purchase coal from counties w/o Cl data
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

%% Produce compare LDL = 0, LDL = 0.7, and LDL = 1
boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_apcd, cq_hg_2015, cq_se_2015, cq_as_2015, cq_cl_2015, trials);

plant_ppm = zeros(size(boot_cq_TE,1),4);
for k = 1:4
    for i = 1:size(boot_cq_TE,1)
        plant_ppm(i,k) = median(boot_cq_TE{i,k+1}); 
    end 
end
%% LDL = 0
% create discrete distributions of trace element concentrations in coal 
LDL_flag = 0; % LDL flag = 0.7 means do nothing, LDL flag 1 means set all LDLs to zero 
[cq_hg0, cq_se0, cq_as0, cq_cl0] = coalqual_dist(coal_gen_boiler_apcd, coal_purchases_2015, 0, LDL_flag);

trials = 10000; % define the number of trials for bootstrapping
% bootstrap TE concentrations in coal blends for all plants in analysis 
boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_apcd, cq_hg0, cq_se0, cq_as0, cq_cl0, trials);

plant_ppm0 = zeros(size(boot_cq_TE,1),4);
for k = 1:4
    for i = 1:size(boot_cq_TE,1)
        plant_ppm0(i,k) = median(boot_cq_TE{i,k+1}); 
    end 
end
%% LDL = 1
LDL_flag = 1; 
[cq_hg1, cq_se1, cq_as1, cq_cl1] = coalqual_dist(coal_gen_boiler_apcd, coal_purchases_2015, 0, LDL_flag);

trials = 10000; % define the number of trials for bootstrapping
% bootstrap TE concentrations in coal blends for all plants in analysis 
boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_apcd, cq_hg1, cq_se1, cq_as1, cq_cl1, trials);

plant_ppm1 = zeros(size(boot_cq_TE,1),4);
for k = 1:4
    for i = 1:size(boot_cq_TE,1)
        plant_ppm1(i,k) = median(boot_cq_TE{i,k+1}); 
    end 
end 
%% plot cdf showing LDL = 0, LDL = 0.7, and LDL = 1
close all; 
figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height
for k = 1:4
    subplot(2,2,k);
%     color = {'r','k','b','g'}; 
    hold on;
    if k == 1
        set(gca, 'Position', [0.15 0.6 0.3 0.33])
    elseif k == 2
        set(gca, 'Position', [0.6 0.6 0.3 0.33])
    elseif k == 3
        set(gca, 'Position', [0.15 0.15 0.3 0.33])
    elseif k == 4
        set(gca, 'Position', [0.6 0.15 0.3 0.33])
    end 
    
    divide_array = [0.6 9 60 1600]; % defined based on the max_trace, based on 25th and 75th percentile 
    hold on; 

%     plotx = sort(plant_ppm(:,k));
%     plotx = sort(plant_ppm1(:,k) - plant_ppm0(:,k));
%     temp = array2table([plant_ppm0(:,k) plant_ppm1(:,k)]);
    plotx0 = sort(plant_ppm0(:,k));
    plotx1 = sort(plant_ppm1(:,k));
    
%     ploty = linspace(0,1,size(plotx,1)); 
     
%     h = plot(plotx,linspace(0,1,size(plotx,1)),'-');
%     set(h,'LineWidth',1.8,'Color',color{k});
    h = plot(plotx0,linspace(0,1,size(plotx0,1)),'-');
    set(h,'LineWidth',1.8,'Color','r');
    h = plot(plotx1,linspace(0,1,size(plotx1,1)),':');
    set(h,'LineWidth',1.8,'Color','k');

%     plot(plotx25,ploty,':','Color',color{k},'MarkerSize',5,'LineWidth',1.8);
%     plot(plotx75,ploty,':','Color',color{k},'MarkerSize',5,'LineWidth',1.8);

    set(gca,'FontName','Arial','FontSize',14)
    a=gca;

    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)

    linspace(0, divide_array(k), 5)
    a.XTick = linspace(0, divide_array(k), 5);
    
    linkaxes([a b])
    axis([0 divide_array(k) 0 1]);

    ylabel('F(x)'); 
    if k == 1
        xlabel(['Median Hg concentration' char(10) 'in coal blend (ppm)']); 
    elseif k == 2
        xlabel(['Median Se concentration' char(10) 'in coal blend (ppm)']); 
    elseif k == 3
        xlabel(['Median As concentration' char(10) 'in coal blend (ppm)']); 
    elseif k == 4
        xlabel(['Median Cl concentration' char(10) 'in coal blend (ppm)']); 
    end 
    legend({'0\timesLDL','1\timesLDL'},'Location','SouthEast'); legend boxoff; 
    grid off;
    title('');

end 

print('../Figures/Fig_conc_LDL_cdf','-dpdf','-r300')




%% End of SI - Miscellaneous code follows underneath
error('runs completed successfully - end of script'); 

%%
boot_blr_emis_hg = innerjoin(boot_blr_emis_hg, coal_gen_boiler_apcd(:,{'Plant_Boiler','Nameplate_Capacity_MW','apcds'})); 
boot_blr_emis_se = innerjoin(boot_blr_emis_se, coal_gen_boiler_apcd(:,{'Plant_Boiler','Nameplate_Capacity_MW','apcds'})); 
boot_blr_emis_as = innerjoin(boot_blr_emis_as, coal_gen_boiler_apcd(:,{'Plant_Boiler','Nameplate_Capacity_MW','apcds'})); 
boot_blr_emis_cl = innerjoin(boot_blr_emis_cl, coal_gen_boiler_apcd(:,{'Plant_Boiler','Nameplate_Capacity_MW','apcds'})); 

sum(boot_blr_emis_hg.Gen_MWh)/ann_coal_gen*100
sum(boot_blr_emis_se.Gen_MWh)/ann_coal_gen*100
sum(boot_blr_emis_as.Gen_MWh)/ann_coal_gen*100
% ans =
%    48.1362
sum(boot_blr_emis_cl.Gen_MWh)/ann_coal_gen*100

ann_coal_cap = sum(coal_generators.Nameplate_Capacity_MW);
sum(boot_blr_emis_hg.Nameplate_Capacity_MW)/ann_coal_cap*100
sum(boot_blr_emis_se.Nameplate_Capacity_MW)/ann_coal_cap*100
sum(boot_blr_emis_as.Nameplate_Capacity_MW)/ann_coal_cap*100
% ans =
%    48.1362
sum(boot_blr_emis_cl.Nameplate_Capacity_MW)/ann_coal_cap*100
% ans =
%    33.8268
% size(unique(boot_plt_emis_cl.Plant_Code),1)
% ans =
%    111
% size(unique(boot_plt_emis_hg.Plant_Code),1)/size(unique(coal_generators.Plant_Code),1)*100
% ans =
%    39.9083
% size(unique(boot_plt_emis_se.Plant_Code),1)/size(unique(coal_generators.Plant_Code),1)*100
% ans =
%    40.8257
% size(unique(boot_plt_emis_as.Plant_Code),1)/size(unique(coal_generators.Plant_Code),1)*100
% ans =
%    37.3853
% size(unique(boot_plt_emis_cl.Plant_Code),1)/size(unique(coal_generators.Plant_Code),1)*100
% ans =
%    25.4587

% estimate number of plants with wFGDs (this matters for estimating average
% FGD wastewater discharges)
fprintf('number of plants with wFGD when estimating Hg: %3.0f\n', ...
    size(unique(boot_blr_emis_hg.Plant_Code(floor(boot_blr_emis_hg.apcds/1000) == 1)),1))
fprintf('number of plants with wFGD when estimating Se: %3.0f\n', ...
    size(unique(boot_blr_emis_se.Plant_Code(floor(boot_blr_emis_se.apcds/1000) == 1)),1))
fprintf('number of plants with wFGD when estimating As: %3.0f\n', ...
    size(unique(boot_blr_emis_as.Plant_Code(floor(boot_blr_emis_as.apcds/1000) == 1)),1))
fprintf('number of plants with wFGD when estimating Cl: %3.0f\n', ...
    size(unique(boot_blr_emis_cl.Plant_Code(floor(boot_blr_emis_cl.apcds/1000) == 1)),1))

%% determine which states are missing Cl data in COALQUAL 
% plant_list = plants_no_cl_data.Plant_Code; 
% plant_purch_county = cell2table(cq_hg_2015(:,1:2)); 
% plant_purch_county.Properties.VariableNames = {'Plant_Code','county_purchs'}; 
% plant_purch_county = innerjoin(plants_no_cl_data(:,1), plant_purch_county); 
% plant_purch_county = innerjoin(plant_purch_county, plant_gen); 
%%
states = zeros(2,1); 
for i = 1:size(plant_purch_county,1)
    states = vertcat(floor(plant_purch_county.county_purchs{i}/1000), states); 
end 
%%
states = unique(states); 

%%
counties = zeros(2,1); 
for i = 1:size(plant_purch_county,1)
    counties = vertcat(plant_purch_county.county_purchs{i}, counties); 
end 
counties = unique(rem(counties(counties > 47000 & counties < 50000)*10,10));

% https://www.census.gov/geo/reference/ansi_statetables.html
% 4 is AZ - Rocky mountain province
% 17 is IL - Eastern Interior
% 18 is IN - Eastern interior
% 29 is MO - Western interior
% 47 is TN - multiple basins
% glossary of provinces: https://pubs.usgs.gov/circ/c891/glossary.htm
% map of reserves: https://pubs.usgs.gov/circ/c891/figures/figure7.htm
% however, these reserves apparently means whether or not there are
% economically extractable coal there... it's not clear if they have any
% special geographical distinctions 
% another resource if needed: https://igws.indiana.edu/Coal/Mercury.cfm

%% compare coal inputs against Daniel G's inputs
[num,txt,raw] = xlsread('../data/Misc_Data/2015 Boiler Trace Element Data.csv');
TE_input_dg = table_scrub(raw, [2 5 6 7 8 9 11 12], 1);
TE_input_dg_condense = unique(TE_input_dg(:,{'Plant_ID','Plant_Boiler'}));
TE_tot = zeros(size(TE_input_dg_condense,1),5); 
for i = 1:size(TE_input_dg_condense,1)
    TE_tot(i,1) = sum(TE_input_dg.Coal(strcmp(TE_input_dg_condense.Plant_Boiler(i), TE_input_dg.Plant_Boiler)));
    TE_tot(i,2) = sum(TE_input_dg.Share_Mercury(strcmp(TE_input_dg_condense.Plant_Boiler(i), TE_input_dg.Plant_Boiler)));
    TE_tot(i,3) = sum(TE_input_dg.Share_Selenium(strcmp(TE_input_dg_condense.Plant_Boiler(i), TE_input_dg.Plant_Boiler)));
    TE_tot(i,4) = sum(TE_input_dg.Share_Arsenic(strcmp(TE_input_dg_condense.Plant_Boiler(i), TE_input_dg.Plant_Boiler)));
    TE_tot(i,5) = sum(TE_input_dg.Share_Chloride(strcmp(TE_input_dg_condense.Plant_Boiler(i), TE_input_dg.Plant_Boiler)));
end 

TE_input_dg_condense = horzcat(TE_input_dg_condense, array2table(TE_tot)); 
TE_input_dg_condense.Properties.VariableNames(end-4:end) = {'Coal','Share_Mercury','Share_Selenium','Share_Arsenic','Share_Chloride'}; 

% comp_dg_ds = innerjoin(TE_input_dg_condense, boot_blr_input_hg(:,2:3)); 
comp_dg_ds = innerjoin(TE_input_dg_condense, input_te_mass(:,2:end)); 

comp_dg_ds(:,end+1) = array2table((comp_dg_ds.Share_Mercury - comp_dg_ds.hg_kg)./comp_dg_ds.hg_kg);
comp_dg_ds.Properties.VariableNames(end) = {'hg_err'}; 
comp_dg_ds(:,end+1) = array2table((comp_dg_ds.Share_Selenium - comp_dg_ds.se_kg)./comp_dg_ds.se_kg);
comp_dg_ds.Properties.VariableNames(end) = {'se_err'}; 
comp_dg_ds(:,end+1) = array2table((comp_dg_ds.Share_Arsenic - comp_dg_ds.as_kg)./comp_dg_ds.as_kg);
comp_dg_ds.Properties.VariableNames(end) = {'as_err'}; 
comp_dg_ds(:,end+1) = array2table((comp_dg_ds.Share_Chloride - comp_dg_ds.cl_kg)./comp_dg_ds.cl_kg);
comp_dg_ds.Properties.VariableNames(end) = {'cl_err'}; 

%% plot histograms of differences 
% histogram for difference in means and medians
comp_dg_ds_plt = unique(comp_dg_ds(:,{'Plant_ID','hg_err','se_err','as_err','cl_err'})); 
close all;
figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height
for k = 1:4
    subplot(2,2,k);
    color = {'r','k','b','g'}; 
    hold on;

    if k == 1
        set(gca, 'Position', [0.15 0.6 0.3 0.33])
    elseif k == 2
        set(gca, 'Position', [0.6 0.6 0.3 0.33])
    elseif k == 3
        set(gca, 'Position', [0.15 0.15 0.3 0.33])
    elseif k == 4
        set(gca, 'Position', [0.6 0.15 0.3 0.33])
    end 
    
    histogram(table2array(comp_dg_ds_plt(:,k+1))*100)

    set(gca,'FontName','Arial','FontSize',14)
    a=gca;

    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)  
    linkaxes([a b])
    axis([-5 5 0 250]);

    ylabel('Number of plants'); 
    xlabel('Percent error (%)'); 
    if k == 1
        title('A) Hg');
    elseif k == 2
        title('B) Se');
    elseif k == 3
        title('C) As');
    elseif k == 4
        title('D) Cl');
    end 

end 

%% Prepare data for Figure 5 
% input coordinate data from EIA 
[num,txt,raw] = xlsread('../data/EIA_860/2___Plant_Y2015_edited.xlsx','Plant'); 
column_numbers = [3 7 8 10 11]; 
row_start = 2; % identify row number in which spreadsheet starts; index is the row of the header
plant_coord = table_scrub(raw, column_numbers, row_start); % create table from raw data
plant_coord = innerjoin(plant_coord, egrid_subrgns); % merge egrid subregion data 
clear raw txt num column_numbers row_start; 

% append latitude and longitude data to estimates of waste stream
% emissions loadings and emissions factors 
% output data into excel files. Use R to create maps. See r_map directory
[map_hg, map_hg_egrid] = append_lat_long(boot_plt_emis_hg, plant_coord,'Hg'); 
[map_se, map_se_egrid] = append_lat_long(boot_plt_emis_se, plant_coord,'Se'); 
[map_as, map_as_egrid] = append_lat_long(boot_plt_emis_as, plant_coord,'As'); 
[map_cl, map_cl_egrid] = append_lat_long(boot_plt_emis_cl, plant_coord,'Cl'); 

%% test Daniel G estimates against Hg results 
hg_air = zeros(size(comp_dg_ds.Plant_Boiler,1),1); 
for i = 1:size(hg_air,1)
    idx = strcmp(comp_dg_ds.Plant_Boiler, boot_part_hg{i,2}) == 1;
    hg_air(i) = comp_dg_ds.Share_Mercury(idx)*median(boot_part_hg{i,3}(:,3));
end 
hg_air = horzcat(comp_dg_ds(:,{'Plant_Boiler'}), array2table(hg_air)); 
hg_air = innerjoin(hg_air, coal_gen_boiler_apcd(:,{'Plant_Boiler','Net_Generation_Year_To_Date'})); 
hg_air(:,end+1) = array2table(hg_air.hg_air./hg_air.Net_Generation_Year_To_Date*1e6); 
hg_air.Properties.VariableNames(end) = {'med_hg_emf_stack'}; 
test = innerjoin(hg_air, cems_hg_emf_2015); 
% plot_cems_comparison(test)

fprintf('median CEMS emf, median bootstrap emf, and median difference emf: %2.2f, %2.2f, %2.2f \n', ...
    median(comp_boot_cems_hg.cems_hg_emf_mg_MWh), ...
    median(comp_boot_cems_hg.med_hg_emf_stack), ...
    median(comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh)); 

%% estimate median partitioning 
boot_part_test = boot_part_as;
part_liq_sol = zeros(size(boot_part_test,1),1); 
for i = 1:size(boot_part_test,1)
    part = median(boot_part_test{i,3},1); 
    part_liq_sol(i) = part(1) + part(2); 
end 
boot_part_test = horzcat(cell2table(boot_part_test), array2table(part_liq_sol)); 
boot_part_test.Properties.VariableNames = {'Plant_Code','Plant_Boiler','boot_part','med_part'}; 
boot_part_test = innerjoin(boot_part_test, coal_gen_boiler_apcd(:,{'Plant_Boiler','apcds'})); 
% boot_part_hg_med(:,'boot_part') = [];
clear part part_liq_sol;

%% more testing 
[lit_phases_hg, lit_phases_se, lit_phases_as, lit_phases_cl] = partition_by_apcd_to_phases(lit_partition_US);
boot_part_hg_sys = boot_partitioning(coal_gen_boiler_apcd, lit_phases_hg, trials, 'Hg');
boot_part_se_sys = boot_partitioning(coal_gen_boiler_apcd, lit_phases_se, trials, 'Se');
boot_part_as_sys = boot_partitioning(coal_gen_boiler_apcd, lit_phases_as, trials, 'As');
boot_part_cl_sys = boot_partitioning(coal_gen_boiler_apcd, lit_phases_cl, trials, 'Cl');

%% compare partitioning of link to system 
close all;
comp_part_hg = compare_partitioning(boot_part_hg, boot_part_hg_sys,'Hg');
comp_part_se = compare_partitioning(boot_part_se, boot_part_se_sys,'Se');
comp_part_as = compare_partitioning(boot_part_as, boot_part_as_sys,'As');
comp_part_cl = compare_partitioning(boot_part_cl, boot_part_cl_sys,'Cl');

%% 
comp_part_hg = innerjoin(comp_part_hg, coal_gen_boiler_apcd(:,{'Plant_Boiler','apcds'})); 
comp_part_se = innerjoin(comp_part_se, coal_gen_boiler_apcd(:,{'Plant_Boiler','apcds'})); 
comp_part_as = innerjoin(comp_part_as, coal_gen_boiler_apcd(:,{'Plant_Boiler','apcds'})); 
comp_part_cl = innerjoin(comp_part_cl, coal_gen_boiler_apcd(:,{'Plant_Boiler','apcds'})); 

%% test partitioning
boot_part = boot_part_as;
test = zeros(size(boot_part,1),3); 
for i = 1:size(test,1)
    test(i,1) = median(boot_part{i,3}(:,1)); 
    test(i,2) = median(boot_part{i,3}(:,2)); 
    test(i,3) = median(boot_part{i,3}(:,3)); 
end 
test = cell2table(horzcat(boot_part, table2cell(array2table(test)))); 
test.Properties.VariableNames = {'Plant_Code','Plant_Boiler','partition','med_solid','med_liq','med_gas'}; 

boot_part_sys = boot_part_as_sys;
test2 = zeros(size(boot_part_sys,1),3); 
for i = 1:size(test2,1)
    test2(i,1) = median(boot_part_sys{i,3}(:,1)); 
    test2(i,2) = median(boot_part_sys{i,3}(:,2)); 
    test2(i,3) = median(boot_part_sys{i,3}(:,3)); 
end 
test2 = cell2table(horzcat(boot_part_sys, table2cell(array2table(test2)))); 
test2.Properties.VariableNames = {'Plant_Code','Plant_Boiler','partition','med_solid','med_liq','med_gas'}; 