function unique_apcd_combo = multi_apcd_generation(coal_gen_boiler_wapcd, poll_type)
% this function calculates the generation associated with each apcd
% combination
% 
% inputs 
% coal_gen_boiler_wapcd - the coal:generator:boiler:apcd table 
% poll_type - the pollution control type (PM, SO2, NOx, and Hg); for this
% script poll_type should be either (PM, SO2) or (PM, SO2, NOx, and Hg) 
% outputs 
% apcd_table - apcds, generation, and generation utilized in multiple
% controls 

apcd_binary = {''}; % initialize cell 
for k = 1:size(poll_type,2) % for each pollution type 
    apcd_ctrls = table2cell(coal_gen_boiler_wapcd(:,poll_type{k})); % pull all air pollution controls associated with that type of control 
    % determine all pollution controls present for that pollution control type 
    for i = 1:size(apcd_ctrls) 
        apcds_at_boiler = apcd_ctrls{i,1}; % pull all controls associated with the boiler 
        if size(apcds_at_boiler,1) > 0 % if controls are present 
             apcd_binary = vertcat(apcd_binary, apcds_at_boiler(:,1)); % append pollution control 
        end 
    end 
end 

% remove all blanks 
remove_blanks = zeros(size(apcd_binary,1),1); % set a matrix to mark the blanks 
for i = 1:size(apcd_binary,1) % for each apcd in the overall list
    if size(apcd_binary{i,1},1) == 0 % if there is an empty control present 
        remove_blanks(i) = 1; % mark the matrix  
    end
end 
apcd_binary(logical(remove_blanks)) = []; % remove all of the blanks  

apcd_binary = table2cell(unique(cell2table(apcd_binary))); % make a unique list of the pollution controls 
apcd_binary(:,end+1) = {0}; % create a second column of zeros next to the apcd binaries 

for i = 1:size(apcd_binary) % for each apcd
    apcd_binary{i,2} = 2^(i-1); % associate it with a power of 2
end 

% iterate through all generators/boilers and determine air pollution
% combination installed and then determine control combination in place 
apcd_combo = cell(size(coal_gen_boiler_wapcd,1),2); 
apcd_combo(:,2) = {0}; % second column of zeros 
% apcd_combo(:,3) = table2cell(array2table(coal_gen_boiler_wapcd.Nameplate_Capacity_MW)); % third column for capacity
apcd_combo(:,3) = table2cell(array2table(coal_gen_boiler_wapcd.Net_Generation_Year_To_Date)); % third column for generation
for i = 1:size(coal_gen_boiler_wapcd) % for each boiler 
    apcds_at_boiler = {''}; % initialize the cell
    for k = 1:size(poll_type,2) % for each pollution type
        apcd_ctrls = coal_gen_boiler_wapcd{i,poll_type{k}}; % pull controls of that pollution type
        apcds_at_boiler = vertcat(apcds_at_boiler,...
            coal_gen_boiler_wapcd{i,poll_type{k}}{:,1}); % combine all the controls together
    end 
    % remove blanks at that boiler 
    remove_blanks = zeros(size(apcds_at_boiler,1),1); % set a matrix to mark the blanks 
    for j = 1:size(apcds_at_boiler,1) % for each apcd in the overall list
        if size(apcds_at_boiler{j,1},1) == 0 % if there is an empty control present 
            remove_blanks(j) = 1; % mark the matrix  
        end
    end 
    apcds_at_boiler(logical(remove_blanks)) = []; % remove all the blanks
    apcds_at_boiler = table2cell(unique(cell2table(apcds_at_boiler))); % convert the list to a unique cell
    
    for j = 1:size(apcds_at_boiler) % for each pollution control at the boiler 
        index = strcmp(apcds_at_boiler{j,1}, apcd_binary(:,1)); % find the binary index associated with the pollution control
        apcd_combo{i,2} = apcd_combo{i,2} + apcd_binary{index,2}; % add the number to the overall combination code 
    end 
    apcd_combo{i,1} = apcds_at_boiler; % update the combination with the boiler 
end 

apcd_combo_array = table2array(cell2table(apcd_combo(:,2:3))); % convert the combination into an array for convenience and manipulation 
unique_apcd_combo = unique(apcd_combo_array(:,1)); % create a unique combination array 
for i = 1:size(unique_apcd_combo,1) % for each unique combination 
    % add up all the generation associated with the apcd combination
    unique_apcd_combo(i,2) = sum(apcd_combo_array(...
        (apcd_combo_array(:,1) == unique_apcd_combo(i)),2)); 
end

unique_apcd_combo = table2cell(array2table(unique_apcd_combo)); % convert into a cell for ease of manipulation 
apcd_numerical = table2array(cell2table(apcd_combo(:,2))); % make an array of the binary code 
for i = 1:size(unique_apcd_combo,1)
    binary = unique_apcd_combo{i}; % the binary code for the apcd control 
    combination = apcd_combo(binary == apcd_numerical,1); % find all combinations with that binary code 
    unique_apcd_combo{i,3} = combination{1}; % set the apcd control combination with the actual equipment type names to the cell 
end 

unique_apcd_combo = cell2table(unique_apcd_combo); % convert output to table 
unique_apcd_combo.Properties.VariableNames = {'binary_combo','generation','word_combo'}; % label table headers 

end 

%% backup code 
% run through all PM controls and turn all csESPs and hsESPs to ESPs. In
% the paper we discuss these simultaneously, but in the partitioning we
% make the distinction
% pm_ctrls = table2cell(coal_gen_boiler_wapcd(:,'PM')); 
% for i = 1:size(pm_ctrls,1)
%     apcds_at_boiler = pm_ctrls{i,1};
%     dummy = {''}; 
%     for j = 1:size(apcds_at_boiler,1) % if controls are present
%         dummy(j) = apcds_at_boiler{j,1}; % append pollution control
%     end
%     if sum(strcmp('csESP',dummy)) > 0
%         dummy(strcmp('csESP',dummy)) = {'ESP'}; 
%     end 
%     if sum(strcmp('hsESP',dummy)) > 0
%         dummy(strcmp('hsESP',dummy)) = {'ESP'}; 
%     end 
%     pm_ctrls{i,1} = dummy; 
% end 
% 
% coal_gen_boiler_wapcd(:,'PM') = pm_ctrls;