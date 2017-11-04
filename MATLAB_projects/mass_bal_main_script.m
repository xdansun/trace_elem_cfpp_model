% description needed 

clear; clc; close all;
warning('off','all');
% add folders for functions in different directory 
addpath('utility_scripts'); % contains data scrubbing functions
addpath('plot_functions'); % contains all plotting functions 

%% Input EIA Generator, boiler, and fuel data
% add coal generators and boilers into the analysis 
% exclude coal generators based on boiler/generator data limitations given in SI Section ??
[coal_generators, coal_gen_boilers, ann_coal_gen] = ...
    create_coal_single_gen_boiler;  
% obtain coal purchase data, exclude coal generators based on coal purchase
% data limitations given in SI Section XX??
[coal_gen_boilers, coal_purchases_2015] = ...
    compile_coal_purchases(coal_gen_boilers, ann_coal_gen, 2015); 
% create coal:generator:boiler:fuels table, adds fuel consumption data at
% the boiler level 
coal_gen_blrs_wfuels = boiler_fuel_consumption(coal_gen_boilers,ann_coal_gen); 

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

%% Produce Figure 2 - partitioning of trace elements by study in the literature
% Calculate partitioning by air pollution control for each study 
% further fixing required; 
% data in lit_partition_apcd_all used to create Table S4 
[lit_partition_apcd_all, fgd_ww_ratio] = trace_elem_partition_lit; % include international studies
lit_partition_US = lit_partition_apcd_all(1:21,:); % select only domestic studies for bootstrap partitioning

close all; 
plot_TE_partition_v2(lit_partition_US);

%% Produce Figure 3 - estimate TE concentrations in coal blends by bootstrapping
% For each coal purchase, find location of coal purchase
% for each location, randomly draw one sample from all coal samples at that location in CQ 
% TE conc = weighted average of TE samples by purchase quantity 

% create discrete distributions of trace element concentrations in coal 
[cq_hg_2015, cq_se_2015, cq_as_2015, cq_cl_2015, plants_no_cl_data] = coalqual_dist(coal_gen_boiler_apcd, coal_purchases_2015, 0);

% calculate generation associated with chlorine plants removed 
plants_no_cl_data = array2table(plants_no_cl_data(plants_no_cl_data > 0));
plants_no_cl_data.Properties.VariableNames = {'Plant_Code'}; 
plants_no_cl_data = innerjoin(plants_no_cl_data, plant_gen); 
fprintf('generation of chlorine plants removed (MWh) %1.0f\n', sum(plants_no_cl_data.Gen_MWh)); 

trials = 10000; % define the number of trials for bootstrapping
% bootstrap TE concentrations in coal blends for all plants in analysis 
boot_cq_TE = boot_coal_blend_conc(coal_gen_boiler_apcd, cq_hg_2015, cq_se_2015, ...
    cq_as_2015, cq_cl_2015, trials);

% Plot Figure 3A)-3D) - boxplots of TE concentraitons in coal blend at plant level
close all;
plot_boot_coal_blend(boot_cq_TE, 'Hg');
plot_boot_coal_blend(boot_cq_TE, 'Se');
plot_boot_coal_blend(boot_cq_TE, 'As');
plot_boot_coal_blend(boot_cq_TE, 'Cl'); % revise to plot fewer plants and plants with data 

% Plot Figure 3E)-3H) - CDF of median of coal blends 
% close all;
[conc_stats_hg, conc_stats_se, conc_stats_as, conc_stats_cl] = plot_med_coal_blend(boot_cq_TE);

%% summary statistics - calculate min, median, max, and mean of trace element conc in coal blends 
disp('min, median, and max of trace element concentrations of all plants for Hg, Se, As, and Cl'); 
[min(conc_stats_hg.median), median(conc_stats_hg.median), max(conc_stats_hg.median)]
[min(conc_stats_se.median), median(conc_stats_se.median), max(conc_stats_se.median)]
[min(conc_stats_as.median), median(conc_stats_as.median), max(conc_stats_as.median)]
[min(conc_stats_cl.median), median(conc_stats_cl.median), max(conc_stats_cl.median)]

disp('mean of the median concentration of Hg, Se, As, and Cl in coal blends of all plants in analysis'); 
[mean(conc_stats_hg.median), mean(conc_stats_se.median), mean(conc_stats_as.median), mean(conc_stats_cl.median)]

%% plot Figure SI???: coal blend concentrations CDFs by eGRID subregion 
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
for i = 1:size(subrgn_list,1)
    subrgn = subrgn_list{i,1};
    subrgn_cq = boot_cq_TE_subrgn(strcmp(boot_cq_TE_subrgn.egrid_subrgn,subrgn),:);
%     plot_med_coal_blend_egrid(table2cell(subrgn_cq(:,1:5)),subrgn);
end
% Regarding FRCC, only 2 plants have Cl concentrations in the FRCC subrgn.
% two purchase from similar counties with high chlorine concentrations in
% coal.

%% bootstrap trace element partitioning for each boiler 
% convert partitioning by air pollution controls to phases 
% the cells lit_phases_* are used to create Table S3??
[lit_phases_hg, lit_phases_se, lit_phases_as, lit_phases_cl] = partition_by_apcd_to_phases(lit_partition_US);

% bootstrap trace element partitioning for each boiler 
boot_part_hg = boot_partitioning(coal_gen_boiler_apcd, lit_phases_hg, trials, 'Hg'); 
boot_part_se = boot_partitioning(coal_gen_boiler_apcd, lit_phases_se, trials, 'Se'); 
boot_part_as = boot_partitioning(coal_gen_boiler_apcd, lit_phases_as, trials, 'As'); 
boot_part_cl = boot_partitioning(coal_gen_boiler_apcd, lit_phases_cl, trials, 'Cl');

%% Produce Figure S9: median trace element partitioning for each boiler 
plot_med_partition_cdf(boot_part_hg, boot_part_se, boot_part_as, boot_part_cl);

% summary statistics - calculate median partitioning of each boiler 
boot_part_TE = boot_part_cl; % for other trace element, use boot_part_hg, boot_part_se, boot_part_as, or boot_part_cl;
meds = zeros(size(boot_part_TE,1),3); 
for i = 1:size(boot_part_TE)
    meds(i,:) = median(boot_part_TE{i,3}); 
end 
disp('minimum and maximum median partitioning of boilers in the fleet for trace element'); 
min(meds)
max(meds)

%% Produce Figure 4 - median waste stream factors of trace elements for CFPPs included in analysis 
% prepare data for emissions across the US 
% calculate total annual emissions from all plants 
% calculate median and 95% CI of emissions 
[boot_blr_emis_hg, boot_plt_emis_hg] = boot_coal_cq_part_lit(coal_gen_boiler_apcd, boot_cq_TE, boot_part_hg, ann_coal_gen, 'Hg');
[boot_blr_emis_se, boot_plt_emis_se] = boot_coal_cq_part_lit(coal_gen_boiler_apcd, boot_cq_TE, boot_part_se, ann_coal_gen, 'Se');
[boot_blr_emis_as, boot_plt_emis_as] = boot_coal_cq_part_lit(coal_gen_boiler_apcd, boot_cq_TE, boot_part_as, ann_coal_gen, 'As');
[boot_blr_emis_cl, boot_plt_emis_cl] = boot_coal_cq_part_lit(coal_gen_boiler_apcd, boot_cq_TE, boot_part_cl, ann_coal_gen, 'Cl');

close all; 
% Plot Figure S6?? - median waste stream factors of trace elements for coal boilers included in analysis 
plot_med_emf_cdf_blr(boot_blr_emis_hg, boot_blr_emis_se, boot_blr_emis_as, boot_blr_emis_cl)
% Plot Figure 4 - median waste stream factors of trace elements for CFPPs included in analysis 
plot_med_emf_cdf_plt(boot_plt_emis_hg, boot_plt_emis_se, boot_plt_emis_as, boot_plt_emis_cl); % create separate function for plant level modeling, some subtleties 

%% Produce Figure 4 - median waste stream factors of trace elements for CFPPs by eGRID subregions
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
%     plot_med_emf_cdf_plt_subrgn(subrgn_hg, subrgn_se, subrgn_as, subrgn_cl, subrgn_list{i,1}) % create separate function for plant level modeling, some subtleties
end 

clear subrgn_hg subrgn_se subrgn_as subrgn_cl;  

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
append_lat_long(boot_plt_emis_hg, plant_coord,'Hg'); 
append_lat_long(boot_plt_emis_se, plant_coord,'Se'); 
append_lat_long(boot_plt_emis_as, plant_coord,'As'); 
append_lat_long(boot_plt_emis_cl, plant_coord,'Cl'); 

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
median(comp_boot_cems_hg.cems_hg_emf_mg_MWh)
median(comp_boot_cems_hg.med_hg_emf_stack)
median(comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh)

%% see what kind of plants are dramatically overestimating 
comp_boot_cems_hg(:,end+1) = array2table(comp_boot_cems_hg.med_hg_emf_stack - comp_boot_cems_hg.cems_hg_emf_mg_MWh); % estimated - actual 
comp_boot_cems_hg.Properties.VariableNames{end} = 'med_dif';

overest_hg = comp_boot_cems_hg(comp_boot_cems_hg.med_dif > 13, :); 
overest_hg = innerjoin(overest_hg, coal_gen_boiler_apcd(:,[4 8:end]));
% From playing around with the data, I find that the largest emission
% differences correspond to plants with the largest estimates of hg waste stream to air 
% for example, compare these:
comp_boot_cems_hg = sortrows(comp_boot_cems_hg,'med_hg_emf_stack','descend');
overest_hg = sortrows(overest_hg,'med_hg_emf_stack','ascend');

% therefore, investigate if these plants also have the highest mercury
% concentrations in coal 

% see if these plants have lower removals than expected 
overest_hg = innerjoin(overest_hg, conc_stats_hg(:,{'Plant_Code','median'}));
med_remov = zeros(size(boot_part_hg,1),1); 
for i = 1:size(boot_part_hg,1)
    med_remov(i) = median(boot_part_hg{i,3}(:,3));
end 
med_remov = horzcat(cell2table(boot_part_hg(:,2)), array2table(med_remov)); 
med_remov.Properties.VariableNames = {'Plant_Boiler','med_remov'}; 
overest_hg = innerjoin(overest_hg, med_remov);
% needed removal 
foo = (overest_hg.median.*overest_hg.Fuel_Consumed*907./overest_hg.gen_mwh - ...
    overest_hg.cems_hg_emf_mg_MWh)./(overest_hg.median.*overest_hg.Fuel_Consumed*907./overest_hg.gen_mwh);
overest_hg(:,end+1) = array2table(foo); 


disp('end of main paper'); 
%% End of main paper - Begin SI 
%% SI Section 2 - calculate generation associated with air pollution controls  
% determine generation across the fleet for single apcd type 
% gen_pm_ctrls, gen_so2_ctrls, gen_nox_ctrls, and gen_hg_ctrls are used to
% make Table S1
gen_pm_ctrls = single_apcd_generation(coal_gen_boiler_apcd, 'PM'); 
gen_so2_ctrls = single_apcd_generation(coal_gen_boiler_apcd, 'SO2'); 
gen_nox_ctrls = single_apcd_generation(coal_gen_boiler_apcd, 'NOx'); 
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

%% summary statistics - calculate generation associated with hsESP and ACI 
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


%% SI Section 7 - Calculate coal generation at each eGRID subregion 
coal_blrs_egrid = innerjoin(coal_gen_boilers, egrid_subrgns); % merge coal boilers (note, this includes all coal boilers) with egrid subregions
subrgn_list = unique(egrid_subrgns.egrid_subrgn);  % compile list of subrgns 
subrgn_list(1,:) = []; % remove first row which is blank 

% for each subrgn, count the number of coal plants, add up coal capacity,
% add up coal generation, and calculate coal capacity factor 
num_cap_gen_cf = zeros(size(subrgn_list,1),4); 
for i = 1:size(subrgn_list,1)
    index = strcmp(coal_blrs_egrid.egrid_subrgn,subrgn_list{i,1});
    num_cap_gen_cf(i,1) = size(unique(coal_blrs_egrid.Plant_Code(index)),1); 
    num_cap_gen_cf(i,2) = sum(coal_blrs_egrid.Nameplate_Capacity_MW(index)); 
    num_cap_gen_cf(i,3) = sum(coal_blrs_egrid.Net_Generation_Year_To_Date(index)); 
    num_cap_gen_cf(i,4) = num_cap_gen_cf(i,3)/(num_cap_gen_cf(i,2)*8760); 
end 

% subrgn_coal_summary is used to create Table S5 in SI Section ??
num_cap_gen_cf(i,4) = num_cap_gen_cf(i,3)/(num_cap_gen_cf(i,2)*8760); 
subrgn_coal_summary = horzcat(subrgn_list, table2cell(array2table(num_cap_gen_cf))); 

%% SI - variability of coal samples in COALQUAL


%% SI Section 3 - calculate fraction of coal purchases that are prepared 
% see directory SI_coal_prep, load 'coal_prep_data.mat', run line 105 in
% script SI_coal_prep_eia


%% SI Section ?? - Compare trace element concentration from COALQUAL vs 
% MATS ICR (refered to as the hazardous air pollutants (HAPS) dataset) 
[plant_trace_haps, haps_plant_data, haps_sampling_months] = read_in_haps_coal_data; % reads in input data

% estimate trace element concentration in coal blends using 2010 coal
% purchase data
% input 2010 coal purchases 
disp('ignore (total percent generation lost) outputs from script');
[coal_gen_boilers_2010, coal_purchases_2010] = ...
    compile_coal_purchases(coal_gen_boilers, ann_coal_gen, 2010); 
% create 2010 distribution of trace element concentrations in coal at the plant level 
[cq_hg_2010, cq_se_2010, cq_as_2010, cq_cl_2010] = coalqual_dist(coal_gen_boiler_apcd, coal_purchases_2010, haps_sampling_months);
boot_cq_TE_2010 = boot_coal_blend_conc(coal_gen_boiler_apcd, cq_hg_2010, cq_se_2010, cq_as_2010, cq_cl_2010, trials);
boot_cq_TE_2010_tbl = cell2table(boot_cq_TE_2010); % convert to table 
boot_cq_TE_2010_tbl.Properties.VariableNames = {'Plant_Code','hg_ppm','se_ppm','as_ppm','cl_ppm'}; 

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

% Plot SI Figure ?? - Compare trace element concentrations between COALQUAL (CQ) and HAPS 
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

% number of active coal plants
% size(innerjoin(plant_trace_haps(:,1), unique(coal_generators(:,{'Plant_Code'}))),1)

% calculate generation produced in 2015 by plants in the MATS ICR 
gen_haps = innerjoin(plant_trace_haps(:,{'Plant_Code'}), plant_gen); 
fprintf('fraction of generation in 2015 produced by plants in MATS ICR %1.3f\n', ...
    sum(gen_haps.Gen_MWh)/ann_coal_gen) % only covers about 46% of coal generation 
fprintf('number of plants in CQ and HAPS: %3.0f\n', size(comp_cq_haps,1)); 
fprintf('number of plants in common for Hg, Se, As, and Cl: %3.0f, %3.0f, %3.0f, %3.0f\n', ...
    sum(~isnan(med_ppm_dif(:,1))), sum(~isnan(med_ppm_dif(:,2))), sum(~isnan(med_ppm_dif(:,3))), sum(~isnan(med_ppm_dif(:,4)))); 
fprintf('median MATS conc Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', median(haps_ppm,'omitnan')); 
fprintf('median CQ conc Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', median(cq_ppm,'omitnan')); 
fprintf('median dif conc Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', median(med_ppm_dif,'omitnan')); 
fprintf('median percent errors Hg, Se, As, and Cl: %1.3f, %2.3f, %2.3f, %5.0f\n', median(med_ppm_dif./med_ppm_haps*100,'omitnan')); 

%% SI Section 12 - compare partitioning to solid + liquid from MATS ICR against results from literature
% input coal and emissions data from the MATS ICR dataset
partition_haps_data = partition_solid_liq_haps(haps_plant_data); 

% estimate partitioning to not air (solids + liquids) from the MATS ICR 
% compare partitioning between literature and MATS ICR 
comp_lit_mats_hg = comp_TE_partitioning(partition_haps_data, boot_part_hg, 'Hg');
comp_lit_mats_se = comp_TE_partitioning(partition_haps_data, boot_part_se, 'Se');
comp_lit_mats_as = comp_TE_partitioning(partition_haps_data, boot_part_as, 'As');
comp_lit_mats_cl = comp_TE_partitioning(partition_haps_data, boot_part_cl, 'Cl');

%% plot SI figure comparing removals 
close all; 
plot_mats_lit_partition_comp(comp_lit_mats_hg, comp_lit_mats_se, comp_lit_mats_as, comp_lit_mats_cl);

% summary statistics - calculate generation in the MATS ICR - literature comparison dataset
foo = unique(vertcat(comp_lit_mats_hg(:,{'Plant_Boiler'}), comp_lit_mats_se(:,{'Plant_Boiler'}),...
    comp_lit_mats_as(:,{'Plant_Boiler'}), comp_lit_mats_cl(:,{'Plant_Boiler'}))); 
foo = innerjoin(foo, coal_gen_boiler_apcd(:,{'Plant_Boiler','Net_Generation_Year_To_Date'})); 
disp('fraction of coal generation from the MATS ICR - literature comparison dataset'); 
sum(foo.Net_Generation_Year_To_Date)/ann_coal_gen

%% End of SI - Miscellaneous code follows underneath
error('end of script'); 

%% find number of boilers with wFGD PM and no wFGD so2 controls
flag = zeros(size(coal_gen_boiler_apcd,1),2); 
for i = 1:size(coal_gen_boiler_apcd,1)
    pm_ctrls = coal_gen_boiler_apcd.PM{i,1}; 
    so2_ctrls = coal_gen_boiler_apcd.PM{i,1}; 
    for j = 1:size(pm_ctrls,1)
        if size(pm_ctrls{j,1},1) > 0 && strcmp(pm_ctrls{j,1}{1,1},'wFGD') == 1
            flag(i,1) = 1; 
            for k = 1:size(so2_ctrls,1)
                if strcmp(so2_ctrls{k,1}{1,1},'wFGD') == 1
                    flag(i,2) = 1; 
                end 
            end 
        end 
    end 

end 
sum(flag(:,1) - flag(:,2))
sum(flag) 
% looks like things are fine; all wet scrubbers that treat PM are also wFGDs 






%% check how many have retired for comparing coal purchases between 2010 and 2015 
% [num,txt,raw] = xlsread('EIA_860\3_1_Generator_Y2015.xlsx','Retired and Canceled');
% column_numbers = [3 7 24]; % identify columns of interest from raw data files
% row_start = 2; % spreadsheet starts on row 2
% % create a table of all the generators with certain columns of data 
% retire_generators = table_scrub(raw, column_numbers, row_start);
% % create Gen_ID
% col1 = 'Plant_Code'; 
% col2 = 'Generator_ID';
% retire_generators = merge_two_col(retire_generators, col1, col2, {'Plant_Gen'});
% %% 
% retire_generators = retire_generators(strcmp(retire_generators.Status,'RE'),:); 
% retire_plants = unique(retire_generators(:,{'Plant_Code'})); 
% foo = innerjoin(retire_plants, plant_trace_haps);
% test2 = innerjoin(foo, unique(coal_gen_boiler_apcd(:,{'Plant_Code'})));
% match_plants = innerjoin(plant_trace_haps, unique(coal_generators(:,{'Plant_Code'})));
% 
% %% check how many fuel switched
% [num,txt,raw] = xlsread('EIA_860\3_1_Generator_Y2015.xlsx','Operable');
% column_numbers = [3 7 8]; % identify columns of interest from raw data files
% row_start = 2; % spreadsheet starts on row 2
% all_generators = table_scrub(raw, column_numbers, row_start);

%% plot coal blends between plants, comparing 2010 and 2015 purchases 
% close all;
% amt_purch = amt_purch_2010;
% figure; 
% for i = 1:20
%     hold on;
%     ploty = amt_purch.coal_blend{i,1}; 
%     plotx = ones(size(ploty,1),1)*i;
%     plot(plotx, ploty,'*')
% 
%     for j = 1:size(plotx,1)
%         if j > 3
%             break;
%         end
%         txt1 = num2str(amt_purch.county{i,1}(j,1));
%         text(plotx(j)+0.1,ploty(j),txt1);
%     end
% end 
% 
% amt_purch = amt_purch_2015;
% figure; 
% for i = 1:20
%     hold on;
%     ploty = amt_purch.coal_blend{i,1}; 
%     plotx = ones(size(ploty,1),1)*i;
%     plot(plotx, ploty,'*')
% 
%     for j = 1:size(plotx,1)
%         if j > 3
%             break;
%         end
%         txt1 = num2str(amt_purch.county{i,1}(j,1));
%         text(plotx(j)+0.1,ploty(j),txt1);
%     end
% end 

%%
% amt_purch_2010 = innerjoin(amt_purch_2010, comp_cq_haps(:,{'Plant_Code'})); 
% % compile coal purchase data in 2015 for plants appearing in CQ and HAPS
% amt_purch_2015 = cell2table(cq_hg_2015(:,1:3)); 
% amt_purch_2015.Properties.VariableNames = {'Plant_Code','county','tons'};
% amt_purch_2015 = innerjoin(amt_purch_2015, amt_purch_2010(:,{'Plant_Code'})); 
% % for each county, truncate the number (not interested in difference
% % between ranks of coal) 
% amt_purch = amt_purch_2010
% for i = 1:size(amt_purch,1)
%     counties = amt_purch.county{i,1};
%     amt_purch.county{i,1} = round(counties);
% end 
% amt_purch_2010 = amt_purch; 
% % repeat for 2015
% amt_purch = amt_purch_2015;
% for i = 1:size(amt_purch,1)
%     counties = amt_purch.county{i,1};
%     amt_purch.county{i,1} = round(counties);
% end 
% amt_purch_2015 = amt_purch; 
% 
% % estimate coal blend per each county 
% amt_purch = amt_purch_2010; 
% coal_blend = cell(size(amt_purch,1),1); 
% for i = 1:size(amt_purch,1)
%     coal_blend(i,1) = {amt_purch.tons{i,1}/sum(amt_purch.tons{i,1})};
% end 
% amt_purch(:,end+1) = coal_blend; 
% amt_purch.Properties.VariableNames(end) = {'coal_blend'};
% amt_purch_2010 = amt_purch; 
% 
% amt_purch = amt_purch_2015; 
% coal_blend = cell(size(amt_purch,1),1); 
% for i = 1:size(amt_purch,1)
%     coal_blend(i,1) = {amt_purch.tons{i,1}/sum(amt_purch.tons{i,1})};
% end 
% amt_purch(:,end+1) = coal_blend; 
% amt_purch.Properties.VariableNames(end) = {'coal_blend'};
% amt_purch_2015 = amt_purch; 
% 
% %% number of counties in 2010 that appeared again in 2015
% frac = zeros(size(amt_purch_2010,1),1); 
% for i = 1:size(amt_purch_2010,1)
%     counties_2010 = amt_purch_2010.county{i,1};
%     counties_2015 = amt_purch_2015.county{i,1};
%     for j = 1:size(counties_2010,1)
%         idx = counties_2010(j,1) == counties_2015; 
%         if sum(idx > 0)
%             1
%         else 
%             frac(i) = frac(i) + 1; 
%         end 
%     end 
%     % num
%     frac(i) = frac(i)/size(counties_2010,1);
% end
% histogram(frac,'BinMethod','fd')
% 
% 
% %% estimate the squared error for each plant 
% % amt_purch = amt_purch_2010;
% dif = zeros(size(amt_purch_2010,1),1); 
% for i = 21% 1:size(amt_purch_2010,1)
%     counties_2010 = amt_purch_2010.county{i,1};
%     counties_2015 = amt_purch_2015.county{i,1};
%     coal_blend_2010 = amt_purch_2010.coal_blend{i,1};
%     coal_blend_2015 = amt_purch_2015.coal_blend{i,1};
%     num = zeros(size(counties_2010,1),1); 
%     for j = 1:size(counties_2010,1)
%         idx = counties_2010(j,1) == counties_2015; 
%         if sum(idx == 0)
%             num(j) = coal_blend_2010(j,1)^2; 
%         else
%             num(j) = (coal_blend_2015(idx,1) - coal_blend_2010(j))^2; 
%         end 
%     end 
%     % num
%     dif(i) = sum(num)/sum(coal_blend_2010.*coal_blend_2010); 
% end
% 
% plot(dif,'*');

%% compare coal purchases in 2010 and in 2015
% % comp_cq_haps = innerjoin(boot_cq_TE_2010_tbl, plant_trace_haps); % merge HAPS data with CQ bootstrap  
% % compile coal purchase data in 2010 for plants appearing in CQ and HAPS
% amt_purch_2010 = cell2table(cq_hg_2010(:,1:3)); 
% amt_purch_2010.Properties.VariableNames = {'Plant_Code','county','tons'};
% % iterate through all plants to make sure that all plants have actual
% % county data 
% flag = zeros(size(amt_purch_2010,1),1); 
% for i = 1:size(amt_purch_2010,1)
%     if size(amt_purch_2010.county{i,1},1) == 0
%         flag(i) = 1; 
%     end 
% end 
% amt_purch_2010(flag == 1,:) = []; 
% % amt_purch_2010 = innerjoin(amt_purch_2010, comp_cq_haps(:,{'Plant_Code'})); 
% 
% amt_purch_2015 = cell2table(cq_hg_2015(:,1:3)); 
% amt_purch_2015.Properties.VariableNames = {'Plant_Code','county','tons'};
% amt_purch_2015 = innerjoin(amt_purch_2015, amt_purch_2010(:,{'Plant_Code'})); 
% 
% %% number of counties that appeared in 2010 or 2015 but not in both 
% frac = zeros(size(amt_purch_2010,1),1); 
% for i = 1:size(amt_purch_2010,1) % for each plant in 2010 
%     counties_2010 = amt_purch_2010.county{i,1};
%     counties_2015 = amt_purch_2015.county{i,1};
%     counties = unique(vertcat(counties_2010, counties_2015)); 
%     for j = 1:size(counties,1)
%         idx1 = counties(j,1) == counties_2010; 
%         idx2 = counties(j,1) == counties_2015; 
%         if sum(idx1 > 0) && sum(idx2 > 0)
%             1;
%             frac(i) = frac(i) + 1; % count number of counties that appear in both 2010 and 2015 
%         else
%             1;
%         end 
%     end 
%     % num
%     frac(i) = frac(i)/size(counties,1); % estimate purchase fraction 
% end
% 
% %% plot figure 
% figure('Color','w','Units','inches','Position',[0.25 0.25 4 4]) % was 1.25
% axes('Position',[0.2 0.2 0.75 0.75]) % x pos, y pos, x width, y height
% 
% plotx = sort(frac);
% ploty = linspace(0,1,size(plotx,1));
% 
% % histogram(frac,'BinWidth',0.1)
% plot(plotx, ploty,'k','LineWidth',1.6);
% 
% set(gca,'FontName','Arial','FontSize',14)
% a=gca;
% axis([0 1 0 1]);
% set(a,'box','off','color','none')
% b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
% axes(a)
% linkaxes([a b])
% 
% ylabel('F(x)');
% xlabel('Purchase fraction');
% 
% grid off;
% title('');
% 
% print(strcat('Figures/purchase_fraction_cdf'),'-dpdf','-r300')

