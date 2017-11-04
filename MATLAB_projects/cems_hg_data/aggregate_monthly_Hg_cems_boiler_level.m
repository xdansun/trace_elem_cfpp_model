function monthly_aggregated_data = aggregate_monthly_Hg_cems_boiler_level(cems_emis,month)
% based on aggregate_monthly_cems_boiler_level_v4
%% at each boiler, aggregate data 
hours_in_month = [31 28 31 30 31 30 31 31 30 31 30 31]*24; %2015 is not a leap year
all_boilers = cems_emis{month,3}; 
% unique_plant_boiler = unique(all_boilers); % uncomment when checking
% against filtered data
num_boilers = size(all_boilers,1)/hours_in_month(month); % each boiler should have 744 hours of observations 

data_input = horzcat(cems_emis{month,4}, cems_emis{month,5}, cems_emis{month,6}); 
numeric_output = zeros(size(num_boilers,1),3); 
plant_boiler_list = cell(size(num_boilers,1),1); 
% want columns: time oper, gload, sload, so2, nox, co2, heat input

for i = 1:num_boilers
%     index = find(strcmp(all_boilers, unique_plant_boiler{i,1})); % uncomment when cems_emis = baseline_emis_filtered_out
    index = ((i-1)*hours_in_month(month)+1):(i*hours_in_month(month)); % comment when cems_emis = baseline_emis_filtered_out
    numeric_output(i,1) = sum(data_input(index, 1), 'omitnan'); % calculate hours operate 
    numeric_output(i,2) = sum(data_input(index, 1).*data_input(index, 2), 'omitnan'); % calculate gross generation 
    numeric_output(i,3) = sum(data_input(index, 3), 'omitnan'); % calculate Hg emissions
    plant_boiler_list(i,1) = all_boilers(index(1),1); % this makes sure that the plant_boilers are paired correctly with the data 
    
    if size(unique(all_boilers(index)),1) ~= 1 % two safe checks 
        error('different boilers within hours of month'); 
    end 
end 

if size(unique(plant_boiler_list),1) ~= num_boilers % comment when cems_emis = baseline_emis_filtered_out
    error('total number of boilers is incorrect'); 
end 

%% separate plant and boiler ID from plant boiler 
unique_plant = zeros(size(plant_boiler_list)); 
unique_boiler = cell(size(plant_boiler_list)); 
for i = 1:size(plant_boiler_list)
    plt_blr = plant_boiler_list{i,1};
    index = regexp(plt_blr,'_'); 
    unique_plant(i) = str2double(plt_blr(1:index-1)); 
    unique_boiler(i) = {plt_blr(index+1:end)};
end 

%% create an output for internal record keeping 
monthly_aggregated_data = horzcat(array2table(unique_plant), cell2table(plant_boiler_list),...
    array2table(numeric_output));
monthly_aggregated_data.Properties.VariableNames = {'Plant_Code','Plant_Boiler','hours_oper','Gen_MWh','Hg_lbs'}; 

end 