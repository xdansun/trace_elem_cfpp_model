% compare hg emissions exiting the stacks based on model results vs the
% reported mercury removal from CEMs in 2015. 

% approximate run time is 5 minutes

clear; clc;
%%
plant_data_hourly = cell(12,5);
tic
month = 1; 
for i = 1:12 % for each month (Jan, July); can be adapted to only run for a few months, i and months are functionally the same when i = 1:12
    % read in monthly data 
    if i < 10
        filename = strcat('cems_hg_data_2015/MATS emissions 0', num2str(i), '_2015.csv'); 
    else
        filename = ['cems_hg_data_2015/MATS emissions ', num2str(i), '_2015.csv']; 
    end 
    filename
    fid = fopen(filename, 'r');
    formatspec = [repmat('%s ', 1, 24) '%*[^\n]'];
    headers = textscan(fid, formatspec, 1, 'delimiter', ',');
    formatspec = '%s %q %f %s %s %f %f %f %f %f %f %s %f %f %f %s %f %f %f %s %s %s %s %q'; % check "headers" for correct formatting
    tmp = textscan(fid, formatspec, 'delimiter', ',', 'EmptyValue', nan);
    fclose(fid);
    % choose columns: plant id, unit ID, time, operating time, gross load
    % (MW), Hg emis (lb), Hg EMF (lb/GWh)
    plant_data_hourly(month,:) = horzcat(tmp(1,3),tmp(1,4),tmp(1,7),tmp(1,8),tmp(1,11)); 
    toc
    month = month + 1; 
end 
clear tmp; 

%% create plant boiler IDs and write them into a separate text file (takes about 3 minutes)
% % the user can skip running this block of code and waiting for a long time
% raw_data_cems = horzcat(plant_data_hourly(:,1:2), cell(size(plant_data_hourly,1),1), plant_data_hourly(:,3:end)); 
% 
% tic 
% for month = 1:12
%     plant_id = raw_data_cems{month,1};
%     boiler_id = raw_data_cems{month,2};
%     plant_boiler = cell(size(plant_id,1),1); 
%     for i = 1:size(plant_boiler,1)
%         plant_boiler(i,1) = strcat(num2str(plant_id(i)),'_',boiler_id(i,1));
%     end
%     % compile data into a single cell
%     raw_data_cems{month,3} = plant_boiler; 
%     display(month); toc 
% end 
% 
% % rewrite plant boilers as txt output (takes about 1 minute)
% tic
% for month = 1:12
%     if month < 10 
%         filename = strcat('cems_hg_data_2015/plant_boiler_0', num2str(month), '.txt');    
%     else 
%         filename = strcat('cems_hg_data_2015/plant_boiler_', num2str(month), '.txt');    
%     end 
%     month_plant_boiler = cell2table(horzcat(raw_data_cems{month,3})); 
%     writetable(month_plant_boiler,filename,'FileType','text','Delimiter',','); 
%     toc
% end 

%% 
tic 
raw_cems_plant_boiler = cell(12,1); 
for month = 1:12
    if month < 10
        filename = strcat('cems_hg_data_2015/plant_boiler_0', num2str(month), '.txt');    
    else 
        filename = strcat('cems_hg_data_2015/plant_boiler_', num2str(month), '.txt');    
    end 
    fid = fopen(filename, 'r');
    formatspec = [repmat('%s ', 1, 1) '%*[^\n]'];
    tmp = textscan(fid, formatspec, 1, 'delimiter', ','); % remove the first line, which is "Var1"
    raw_cems_plant_boiler(month,1) = textscan(fid, formatspec, 'delimiter', ',', 'EmptyValue', nan);
    fclose(fid);
    toc 
end 
% columns: plant id, unit ID, plant_unit, time, operating time (hr), gross load (MW), Hg (lbs)
raw_data_cems = horzcat(plant_data_hourly(:,1:2), raw_cems_plant_boiler, plant_data_hourly(:,3:end)); 


%% for each month, aggregate monthly data together 
tic
raw_jan = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,1); 
raw_feb = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,2); 
raw_mar = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,3); 
raw_apr = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,4); 
raw_may = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,5); 
raw_jun = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,6); 
raw_jul = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,7); 
raw_aug = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,8); 
raw_sep = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,9); 
raw_oct = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,10); 
raw_nov = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,11); 
raw_dec = aggregate_monthly_Hg_cems_boiler_level(raw_data_cems,12); 
toc

%% create annual data 
% combine all monthly data together 
raw_ann = vertcat(raw_jan, raw_feb, raw_mar, raw_apr, raw_may, raw_jun, raw_jul, raw_aug, raw_sep, raw_oct, raw_nov, raw_dec);

% calculate annual emissions and generation 
Plant_Boiler = unique(raw_ann.Plant_Boiler); 
Plant_Code = zeros(size(Plant_Boiler,1),1); 
hrs_oper = zeros(size(Plant_Boiler,1),1); 
gen_mwh = zeros(size(Plant_Boiler,1),1); 
hg_lbs = zeros(size(Plant_Boiler,1),1); 
for i = 1:size(Plant_Boiler,1)
    idx = find(strcmp(raw_ann.Plant_Boiler, Plant_Boiler{i,1}));
    Plant_Code(i) = raw_ann.Plant_Code(idx(1));
    hrs_oper(i) = sum(raw_ann.hours_oper(idx)); 
    gen_mwh(i) = sum(raw_ann.Gen_MWh(idx)); 
    hg_lbs(i) = sum(raw_ann.Hg_lbs(idx));    
end 
hg_emf_mg_mwh = hg_lbs./gen_mwh*453592; 
cems_hg_emf_2015 = horzcat(array2table(Plant_Code), cell2table(Plant_Boiler),...
    array2table(hrs_oper), array2table(gen_mwh), array2table(hg_lbs), array2table(hg_emf_mg_mwh));
% remove all boilers with zero generation 
cems_hg_emf_2015(cems_hg_emf_2015.gen_mwh == 0,:) = []; 

save('cems_hg_emf_2015.mat','cems_hg_emf_2015'); 








