data_input_path = 'cems_hg_data_2017/';
input_months = 1:12; 
%% read in monthly data (about 3 minutes)
plant_data_hourly = cell(12,10);
tic
for i = input_months %[1 7] % for each month (Jan, July); can be adapted to only run for a few months, i and months are functionally the same when i = 1:12
    % read in monthly data 
    if i < 10
        filename = strcat(data_input_path, 'Hg_CEMS 0', num2str(i), '_2017.csv'); 
    else
        filename = [data_input_path, 'Hg_CEMS ', num2str(i), '_2017.csv']; 
    end 
    fid = fopen(filename, 'r');
    formatspec = [repmat('%s ', 1, 24) '%*[^\n]'];
    headers = textscan(fid, formatspec, 1, 'delimiter', ',');
%     formatspec = '%s %q %f %s %s %f %f %f %f %f %s %f %s %f %s %f %s %f %s %f %s %f %f %s';
    formatspec = '%s %s %s %s %s %s %s %s %s %s %f %s %s %s %f %s %s %s %s %s %s %s %s %s %*[^\n]';
    tmp = textscan(fid, formatspec, 'delimiter', ',', 'EmptyValue', nan);
    fclose(fid);
    % choose columns:  
    plant_data_hourly(i,:) = horzcat(tmp(1,3),tmp(1,4),tmp(1,6),...
        tmp(1,7),tmp(1,8),tmp(1,9),tmp(1,11),tmp(1,12),tmp(1,13),tmp(1,15)); 
    fprintf('Read hourly CEMS emissions for month %1.0f; time elapsed (s): %3.0f\n', i, toc); 
end 

clear tmp; 

%% compile all plants into a single list
all_plants = cell(1,1); 
for month = input_months
    all_plants = vertcat(all_plants, plant_data_hourly{month,1}); 
end 
plant_list = unique(all_plants(2:end,1));

%% compile hg emissions by plant at each month 
hg_emis_mthly = zeros(size(plant_list,1),12); 
for month = input_months
    hg_emis_hrly = plant_data_hourly{month,7};
    for i = 1:size(plant_list,1)
        hg_emis_mthly(i,month) = sum(hg_emis_hrly(strcmp(plant_list(i), ...
            plant_data_hourly{month,1})),'omitnan');
    end 
end 

%% aggregate to annual level 
hg_emis_annual = sum(hg_emis_mthly,2); 
% combine with plant list 
hg_emis_annual = horzcat(cell2table(plant_list), array2table(hg_emis_annual)); 
hg_emis_annual(end,:) = []; % don't know what LLC is supposed to be

%% convert plant_list string to numeric
plant_list_num = zeros(size(hg_emis_annual,1),1);
for i = 1:size(hg_emis_annual,1)
    plant_list_num(i,1) = str2num(hg_emis_annual{i,1}{1,1});
end 
hg_emis_annual.plant_list = plant_list_num; 
hg_emis_annual = sortrows(hg_emis_annual,'plant_list','ascend');
hg_emis_annual.Properties.VariableNames{1} = 'ORISPL';
%% save output
save('hg_emis_annual.mat', 'hg_emis_annual'); 