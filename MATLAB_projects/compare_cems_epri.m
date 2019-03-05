% compare 2017 CEMS emissions against EPRI estimates this is an analysis
% that functions based on the outputs of an EPRI analysis and CEMS 
% 
% EPRI analysis: Hazardous Air Pollutants (HAPs) Emission Estimates and
% Inhalation Human Health Risk Assessment for U.S. Coal-Fired Electric
% Generating Units, Appendix G 


%%
% clear; clc; close all;
warning('off','all');
% add folders for functions in different directory 
addpath('utility_scripts'); % contains data scrubbing functions
addpath('functions'); % contains functions for performing calculations
addpath('plot_functions'); % contains all plotting functions 

%% load 2017 hg CEMS data
% CEMS data is recorded in lbs, see the header of the hourly data in
% cems_hg_data
load('cems_hg_data/hg_emis_annual.mat'); 

%% read in EPRI data
% epri data is recorded in lbs/yr as written in Section G of Hazardous Air
% Pollutants (HAPs) Emission Estimates and Inhalation Human Health Risk
% Assessment for U.S. Coal-Fired Electric Generating Units
[num,txt,raw] = xlsread('../data/epri/epri emission results.xlsx');
epri_emis = table_scrub(raw, [1 3 12 13 15 16], 1); 

%% load in model results for 2017. Obtained from Daniel Gingerich's model. 
[num,txt,raw] = xlsread('../data/2017_results/2017 Stochastic Partitioning at Boiler Level.csv');
model_emis = table_scrub(raw, [2 6 31], 1); 

% compile results at the plant level 
model_emis_plant = unique(model_emis.Plant_ID); 
for i = 1:size(model_emis_plant,1)
    model_emis_plant(i,2) = sum(model_emis.Hg_gas(model_emis.Plant_ID == model_emis_plant(i,1))); 
end 

model_emis_plant = array2table(model_emis_plant); 
model_emis_plant.Properties.VariableNames = {'ORISPL','hg_model'}; 

%% load in 2017 EIA data for generation
[num,txt,raw] = xlsread('../data/eia9232017/EIA923_Schedules_2_3_4_5_M_12_2017_Final_Revision.xlsx');
eia_gen = table_scrub(raw, [1 14:16 96], 6); 

% EIA generation for coal plants at the plant level 
eia_gen_col = eia_gen(strcmp(eia_gen.AER_Fuel_Type_Code,'COL'),:); 
plant_gen = unique(eia_gen_col.Plant_Id); 
for i = 1:size(plant_gen,1)
    plant_gen(i,2) = sum(eia_gen_col.Net_Generation_Megawatthours(eia_gen_col.Plant_Id == plant_gen(i,1))); 
end 
plant_gen = plant_gen(plant_gen(:,2) ~= 0,:); 
plant_gen = array2table(plant_gen); 
plant_gen.Properties.VariableNames = {'ORISPL','gen_mwh'}; 

%% merge generation data with EPRI plants
% epri_emis = innerjoin(epri_emis, plant_gen); 

%% combine CEMS and EPRI datasets to compare
hg_epri_cems = innerjoin(hg_emis_annual, epri_emis(:,[1 6])); 
hg_epri_cems.Properties.VariableNames{2} = 'hg_cems';
hg_epri_cems.Properties.VariableNames{3} = 'hg_epri';
hg_epri_cems = innerjoin(hg_epri_cems, plant_gen); 
hg_epri_cems.hg_cems = hg_epri_cems.hg_cems/2.2*1e6./hg_epri_cems.gen_mwh; 
hg_epri_cems.hg_epri = hg_epri_cems.hg_epri/2.2*1e6./hg_epri_cems.gen_mwh; 
hg_epri_cems(:,end+1) = array2table(hg_epri_cems.hg_epri - hg_epri_cems.hg_cems); 
hg_epri_cems(:,end+1) = array2table((hg_epri_cems.hg_epri - hg_epri_cems.hg_cems)./hg_epri_cems.hg_cems*100); 
hg_epri_cems.Properties.VariableNames{5} = 'abs_dif';
hg_epri_cems.Properties.VariableNames{6} = 'per_dif';

%% combine data with EPRI and CEMS results
hg_comp_all = innerjoin(hg_epri_cems, model_emis_plant); 
hg_comp_all.hg_model = hg_comp_all.hg_model*2.2*1e6./hg_comp_all.gen_mwh; 
% compare emissions against CEMS
hg_comp_all(:,end+1) = array2table(hg_comp_all.hg_model - hg_comp_all.hg_cems); 
hg_comp_all(:,end+1) = array2table((hg_comp_all.hg_model - hg_comp_all.hg_cems)./hg_comp_all.hg_cems); 
hg_comp_all.Properties.VariableNames(end-1:end) = {'abs_dif_model','per_dif_model'}; 

%% plot CDFs comparing the two 
close all; 

figure('Color','w','Units','inches','Position',[1 1 4 4]) % was 1.25
axes('Position',[0.15 0.25 0.7 0.7]) % x pos, y pos, x width, y height

% set(gca, 'Position', [0.55 0.2 0.33 0.7])

plotx = sort(hg_comp_all.abs_dif); 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'r--','LineWidth',1.8);

hold on;
plotx = sort(hg_comp_all.abs_dif_model); 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'k','LineWidth',1.8);

xlabel({'Difference of median bootstrapped', ... 
    'and CEMS gas phase Hg emissions',...
    'intensity (mg/MWh)'});
ylabel('F(x)'); 

set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
% axis([-250 600 0 1]); 
b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])

%% compare with 2015 results instead
% EPRI uses coal purchase and fuel consumption data from 2015:
% From the EPRI report, page 3-1:
% 
% The composition of the coal-fired at each unit is a key input parameter
% used in the estimation of emissions of inorganic HAPs species (e.g.,
% trace elements, acid gas species). This section discusses the methodology
% used to develop the fuel composition input values for each coal-fired
% unit. The general steps used to develop these fuel composition input
% values are listed below. 1. Obtain/generate a database of coal
% composition data by major coal region. 2. Obtain information regarding
% the type and quantity of fuel consumed by each coal-fired power plant
% using EIA Form 923 data from 2015. This was the latest set of available
% data at the time the emission modeling estimates were conducted. 3. Link
% and combine information generated in the first two steps to determine a
% “blended” coal composition for inorganic HAPs and other key coal
% parameters (i.e., heating value, sulfur content, coal ash content). The
% assumption was made that the fuel consumption data from 2015 were
% representative of the coal-fired at each unit for the 2017 base year

% load model 2015 results
results_2015 = comp_boot_cems_hg(:,{'Plant_Code','Plant_Boiler','Gen_MWh','med_hg_emf_stack',...
    'gen_mwh','hg_lbs'}); 
results_2015.Properties.VariableNames{1} = 'ORISPL';
results_2015.Properties.VariableNames{3} = 'gen_mwh_eia';
results_2015.Properties.VariableNames{5} = 'gen_mwh_cems';

% compile results at the plant level
model_emis_plant_2015 = unique(results_2015.ORISPL); 
for i = 1:size(model_emis_plant_2015,1)
    idx = results_2015.ORISPL == model_emis_plant_2015(i,1); 
    model_emis_plant_2015(i,2) = sum(results_2015.gen_mwh_eia(idx)); 
    model_emis_plant_2015(i,3) = sum(results_2015.med_hg_emf_stack(idx).*results_2015.gen_mwh_eia(idx)/1e6); 
    model_emis_plant_2015(i,4) = sum(results_2015.gen_mwh_cems(idx)); 
    model_emis_plant_2015(i,5) = sum(results_2015.hg_lbs(idx)/2.2); 
end 

model_emis_plant_2015 = array2table(model_emis_plant_2015); 
model_emis_plant_2015.Properties.VariableNames = {'ORISPL','gen_mwh_eia','hg_model_kg','gen_mwh_cems','hg_cems_kg'}; 
%% merge with EPRI results 
hg_comp_2015 = innerjoin(model_emis_plant_2015, epri_emis(:,{'ORISPL','Hg_total'}));
hg_comp_2015.Properties.VariableNames(end) = {'hg_epri_kg'};
hg_comp_2015.hg_epri_kg = hg_comp_2015.hg_epri_kg/2.2;

%% plot CDFs comparing the two 
close all; 

figure('Color','w','Units','inches','Position',[1 1 4 4]) % was 1.25
axes('Position',[0.15 0.25 0.7 0.7]) % x pos, y pos, x width, y height
% subplot(1,2,2); 
% set(gca, 'Position', [0.55 0.2 0.33 0.7])

hold on;
plotx = sort(hg_comp_2015.hg_model_kg./hg_comp_2015.gen_mwh_eia - ...
    hg_comp_2015.hg_cems_kg./hg_comp_2015.gen_mwh_cems)*1e6; 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'k','LineWidth',1.8);

plotx = sort(hg_comp_2015.hg_epri_kg./hg_comp_2015.gen_mwh_eia - ...
    hg_comp_2015.hg_cems_kg./hg_comp_2015.gen_mwh_cems)*1e6; 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'r--','LineWidth',1.8);

xlabel({'Difference of modeled Hg emissions', ... 
    'and CEMS generation normalized',...
    'gas phase Hg emissions (mg/MWh)'});
ylabel('F(x)'); 

set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
axis([-10 30 0 1]); 

b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
% axis([-0.01 0.01 0 1]); 

legend('Monte Carlo','EPRI');
legend boxoff;

print('../Figures/FigR4_epri_comp','-dpdf','-r300') % save figure (optional)

%% compare EPRI results against our results 
% this can only be done if mass_bal_main_script has been run 

% centralize model run results into a single table 
our_results = boot_plt_emis_as(:,1:2); 
te = zeros(size(our_results,1),4); 
for i = 1:size(te,1)
    te(i,1) = boot_plt_emis_hg.emf_mg_MWh{i,1}(1,3); 
    te(i,2) = boot_plt_emis_se.emf_mg_MWh{i,1}(1,3); 
    te(i,3) = boot_plt_emis_as.emf_mg_MWh{i,1}(1,3); 
    te(i,4) = boot_plt_emis_cl.emf_mg_MWh{i,1}(1,3); 
end 

our_results = horzcat(our_results, array2table(te));
our_results.Properties.VariableNames = {'ORISPL','gen','hg_our','se_our','as_our','cl_our'};
our_results.Properties.VariableUnits = {'','MWh','mg/MWh','mg/MWh','mg/MWh','mg/MWh'};

% combine EPRI and model results together 
comp_results = innerjoin(our_results, epri_emis);

% calculate generation normalized emissions intensities 
epri_emf = zeros(size(comp_results,1),4); 
epri_emf(:,1) = comp_results.Hg_total/2.2*1e6./comp_results.gen; 
epri_emf(:,2) = comp_results.Se/2.2*1e6./comp_results.gen; 
epri_emf(:,3) = comp_results.As/2.2*1e6./comp_results.gen; 
epri_emf(:,4) = (comp_results.Cl2 + comp_results.HCl)/2.2*1e6./comp_results.gen; 

our_emf = table2array(comp_results(:,3:6)); 

% compare results
comp_emf = our_emf - epri_emf; 

%% plot results 

figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.2 0.15 0.75 0.75]) % x pos, y pos, x width, y height
for k = 1:4 
    subplot(2,2,k);
    hold on; 
    style = {'r','k','b','g'}; 
    if k == 1
        set(gca, 'Position', [0.15 0.6 0.3 0.3])
    elseif k == 2
        set(gca, 'Position', [0.6 0.6 0.3 0.3])
    elseif k == 3
        set(gca, 'Position', [0.15 0.15 0.3 0.3])
    elseif k == 4
        set(gca, 'Position', [0.6 0.15 0.3 0.3])
    end 

    te = {' Hg',' Se',' As',' Cl'};
    % plotx = sort(epri_emf(:,k))/1e6;
    plotx = sort(epri_emf(:,k))/1e3;
    ploty = linspace(0,1,size(plotx,1));
    plot(plotx,ploty,'r-','LineWidth',1.8);

    plotx = sort(our_emf(:,k))/1e3;
    ploty = linspace(0,1,size(plotx,1));
    plot(plotx,ploty,'b:','LineWidth',1.8);

    % plotx = sort(comp_emf(:,k))/1e6;
    plotx = sort(comp_emf(:,k))/1e3;
    ploty = linspace(0,1,size(plotx,1));
    plot(plotx,ploty,'k-.','LineWidth',1.8);

    set(gca,'FontName','Arial','FontSize',13)
    a=gca;
    
    xlabel({strcat('Generation normalized gas'), ...
        strcat('phase', te{k}, ' emissions (g/MWh)')});
    ylabel('F(x)');  
    
    if k == 3
        legend('EPRI','Our estimates',[char(10), 'Difference', char(10), '(Ours - EPRI)'],'Location','SouthEast');
        legend boxoff;
    end 
    grid off;
    title('');

    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    linkaxes([a b])
    
    if k == 1
        axis([-0.05 0.1 0 1]);
    elseif k == 2 
        axis([-0.5 1.5 0 1]); 
    elseif k == 3
        axis([-0.2 0.8 0 1]); 
    else 
        axis([-400 800 0 1]); 
    end 
        
end 

print('../Figures/epri_comp_all_TE','-dpdf','-r300')


% set(gca,'FontName','Arial','FontSize',13)
% a=gca;
% set(a,'box','off','color','none')
% % axis([-1e5 1e5 0 1]); 
% 
% b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
% axes(a)
% linkaxes([a b])
% % axis([-0.01 0.01 0 1]); 



% print('../Figures/FigR4_epri_comp','-dpdf','-r300') % save figure (optional)

%% compare our results with EPRI plants and CEMS and EPRI plants w/o CEMS
[num,txt,raw] = xlsread('../data/epri/epri hg selection criteria.xlsx');
raw{1,1} = 'Plant_ID_boiler';
epri_hg_mark = table_scrub(raw, [1 8], 1); 

% separate plant and boiler IDs and create plant_boiler identifier link
plant_ids = zeros(size(epri_hg_mark,1),1); 
blr_ids = cell(1,1); 
plant_blr_ids = cell(1,1); 
for i = 1:size(plant_ids,1)
    plant_blr = epri_hg_mark.Plant_ID_boiler{i,1}; 
    idx = strfind(plant_blr,'#'); 
    plant_ids(i,1) = str2double(plant_blr(1:(idx-1))); 
    blr_ids{i,1} = plant_blr(idx+1:end); 
    plant_blr(idx) = '_'; 
    plant_blr_ids{i,1} = plant_blr; 
    
end 

% mark boilers with CEMS and without CEMS data 
cems_mark = zeros(size(epri_hg_mark,1),1); 
for i = 1:size(cems_mark,1)
    if strfind(epri_hg_mark.Total_Mercury_SelectionCriteria_b_{i,1},'AMPD') > 0
        cems_mark(i,1) = 1;
    end 
end 

% recreate epri table using correct labels
epri_hg_mark_blr = horzcat(array2table(plant_ids), cell2table(plant_blr_ids), array2table(cems_mark)); 
epri_hg_mark_blr.Properties.VariableNames = {'ORISPL','Plant_Boiler','cems'}; 

epri_hg_mark_plt = unique(horzcat(array2table(plant_ids), array2table(cems_mark))); 
epri_hg_mark_plt.Properties.VariableNames = {'ORISPL','cems'}; 

%% merge with our results 
% requires running code in mass_bal_main_script. need to generate all
% results in the manuscript (not the SI) to run this code)
mod_emis = table2array(boot_plt_emis_hg(:,1:2)); 
for i = 1:size(mod_emis,1)
    mod_emis(i,3) = boot_plt_emis_hg.emis_mg{i}(1,3)/1e6; 
    mod_emis(i,4) = boot_plt_emis_hg.emf_mg_MWh{i}(1,3); 
end 
mod_emis = array2table(mod_emis); 
mod_emis.Properties.VariableNames = {'ORISPL','gen_mwh','model_kg','emf_mg_mwh'}; 

hg_comp_2015_ext = innerjoin(mod_emis, epri_emis(:,{'ORISPL','Hg_total'})); 
hg_comp_2015_ext = innerjoin(hg_comp_2015_ext, epri_hg_mark_plt); 
% hg_comp_2015_ext = innerjoin(hg_comp_2015,epri_hg_mark_plt); 

coal_plant_char = unique(coal_gen_boiler_apcd(:,[1 4])); 
coal_plant_char.Properties.VariableNames(1) = {'ORISPL'}; 
hg_comp_2015_ext = innerjoin(hg_comp_2015_ext, coal_plant_char);

%%
close all; 

figure('Color','w','Units','inches','Position',[1 1 4 4]) % was 1.25
axes('Position',[0.15 0.25 0.7 0.7]) % x pos, y pos, x width, y height
% subplot(1,2,2); 
% set(gca, 'Position', [0.55 0.2 0.33 0.7])

hold on;
test = hg_comp_2015_ext(hg_comp_2015_ext.cems == 1,:); 
plotx = sort((test.model_kg - test.Hg_total/2.2)./test.gen_mwh*1e6); 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'k','LineWidth',1.8);

% test = hg_comp_2015_ext(hg_comp_2015_ext.cems == 0,:); 
% plotx = sort((test.model_kg - test.Hg_total/2.2)./test.gen_mwh*1e6); 
% ploty = linspace(0,1,size(plotx,1));
% plot(plotx,ploty,'r--','LineWidth',1.8);

xlabel({'Difference of Monte Carlo modeled', ... 
    'and EPRI modeled generation normalized',...
    'gas phase Hg emissions (mg/MWh)'});
ylabel('F(x)'); 

set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
% axis([-250 600 0 1]); 

b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
% axis([-0.01 0.01 0 1]); 

legend('with CEMS','without CEMS');
legend boxoff;

% print('../Figures/FigR4_epri_comp','-dpdf','-r300') % save figure (optional)

%% amended plot combining all three comparisons 
close all; 

figure('Color','w','Units','inches','Position',[1 1 4 4]) % was 1.25
axes('Position',[0.15 0.25 0.7 0.7]) % x pos, y pos, x width, y height
% subplot(1,2,2); 
% set(gca, 'Position', [0.55 0.2 0.33 0.7])

hold on;
plotx = sort(hg_comp_2015.hg_model_kg./hg_comp_2015.gen_mwh_eia - ...
    hg_comp_2015.hg_cems_kg./hg_comp_2015.gen_mwh_cems)*1e6; 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'k','LineWidth',1.8);

test = hg_comp_2015_ext(hg_comp_2015_ext.cems == 1,:); 
plotx = sort((test.model_kg - test.Hg_total/2.2)./test.gen_mwh*1e6); 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'b:','LineWidth',1.8);

plotx = sort(hg_comp_2015.hg_epri_kg./hg_comp_2015.gen_mwh_eia - ...
    hg_comp_2015.hg_cems_kg./hg_comp_2015.gen_mwh_cems)*1e6; 
ploty = linspace(0,1,size(plotx,1));
plot(plotx,ploty,'r--','LineWidth',1.8);

xlabel({'Difference of modeled Hg emissions', ... 
    'and CEMS generation normalized',...
    'gas phase Hg emissions (mg/MWh)'});
ylabel('F(x)'); 

set(gca,'FontName','Arial','FontSize',13)
a=gca;
set(a,'box','off','color','none')
axis([-10 30 0 1]); 

b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
axes(a)
linkaxes([a b])
% axis([-0.01 0.01 0 1]); 

legend(['Monte Carlo' char(10) '(all boilers)'], ...
    ['Monte Carlo (EPRI' char(10) 'boilers with CEMS' char(10) 'data)'],...
    'EPRI');
legend boxoff;

% print('../Figures/FigR4_epri_comp','-dpdf','-r300') % save figure (optional)
