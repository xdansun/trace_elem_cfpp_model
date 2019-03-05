function apcd_table = single_apcd_generation(coal_gen_boiler_wapcd, ann_coal_gen, poll_type) 
%%
% this function calculates the generation associated with each apcd based
% on the pollution type and breaks down the generation for individual
% controls that are utilized in multiple control setups 
% 
% inputs 
% coal_gen_boiler_wapcd - the coal:generator:boiler:apcd table 
% poll_type - the pollution control type (PM, SO2, NOx, and Hg) 
% outputs 
% apcd_table - apcds, generation, and generation utilized in multiple
% controls 

% create a list of all possible controls for that pollutant 
apcd_ctrls = table2cell(coal_gen_boiler_wapcd(:,poll_type)); % pull all air pollution controls associated with that type of control 
generation_at_generator = coal_gen_boiler_wapcd.Net_Generation_Year_To_Date; % pull all generation at the generator 
apcd_equip = {'Multi'}; % the first row is the multiple apcd entry 
apcd_equip(2,1) = {'None'}; 
% determine all pollution controls present for that pollution control type 
for i = 1:size(apcd_ctrls,1)
    apcds_at_boiler = apcd_ctrls{i,1}; % pull all controls associated with the boiler 
    if size(apcds_at_boiler,1) > 0 % if controls are present 
         apcd_equip = vertcat(apcd_equip, apcds_at_boiler(:,1)); % append pollution control 
    end 
end 
% remove all '' that are in the apcd_equip list
remove_blanks = zeros(size(apcd_equip,1),1); % set a matrix to mark the blanks 
for i = 1:size(apcd_equip,1) % for each apcd in the overall list
    if size(apcd_equip{i,1},1) == 0 % if there is an empty control present
        remove_blanks(i) = 1; % mark the matrix 
    end
end 
apcd_equip(remove_blanks == 1) = []; % remove all of the blanks 
apcd_equip = table2cell(unique(cell2table(apcd_equip))); % make a unique list of the pollution controls 

%%
apcd_generation = zeros(size(apcd_equip,1),1);  % make a generation array for the list of controls 
multi_breakdown_gen = zeros(size(apcd_equip,1),1);

% loop again to determine generation for single and multiple apcds 
for i = 1:size(apcd_ctrls) 
    apcds_at_boiler = apcd_ctrls{i,1}; % pull all controls associated with the boiler 
    remove_blanks = zeros(size(apcds_at_boiler,1),1); % set a matrix to mark the blanks 
    for j = 1:size(apcds_at_boiler,1) % for each apcd in the overall list
        if size(apcds_at_boiler{j,1},1) == 0 % if there is an empty control present
            remove_blanks(j) = 1; % mark the matrix 
        end
    end 
    apcds_at_boiler(remove_blanks == 1) = []; % remove all of the blanks
    if size(apcds_at_boiler,1) > 0
        apcds_at_boiler = table2cell(unique(cell2table(apcds_at_boiler))); % make a unique list of the pollution controls 
    end 
%     if size(apcds_at_boiler,2) == 0
%         apcds_at_boiler = nan; 
%     end 
    if size(apcds_at_boiler,1) == 1 && size(apcds_at_boiler,2) > 0 % if there is one control at boiler 
        index = strcmp(apcds_at_boiler{1,1}, apcd_equip) == 1; % determine which apcd to add generation for 
        if sum(index) > 0
            apcd_generation(index) = apcd_generation(index) + generation_at_generator(i);
        else 
            index = strcmp('None', apcd_equip) == 1; 
            apcd_generation(index) = apcd_generation(index) + generation_at_generator(i);
        end 
    elseif size(apcds_at_boiler,1) > 1 % if it's multiple 
%         index = strcmp('Multi', apcd_equip) == 1; % add generation to the multiple array 
        for j = 1:size(apcds_at_boiler,1) % breakdown generation of apcds within multiple controls 
            index = strcmp(apcds_at_boiler{j,1}, apcd_equip); 
            apcd_generation(index) = apcd_generation(index) + generation_at_generator(i);
            % add generation and divide by the number of controls present 
            multi_breakdown_gen(index) = multi_breakdown_gen(index) + generation_at_generator(i); %/size(apcds_at_boiler,1); 
        end 
        
    else % if there are no pollution controls present 
        index = strcmp('None', apcd_equip) == 1; 
        apcd_generation(index) = apcd_generation(index) + generation_at_generator(i);
    end
end 

sum(apcd_generation) % sum the total generation for record keeping
a = array2table(apcd_generation/1e6);
b = array2table(multi_breakdown_gen/1e6); 
c = array2table(apcd_generation/ann_coal_gen);
a.Properties.VariableNames = {'dummy'}; 
b.Properties.VariableNames = {'dummy2'}; 
c.Properties.VariableNames = {'dummy3'}; 
apcd_table = horzcat(cell2table(apcd_equip), a, b, c); % create an apcd_table with apcd:generation:multi_gen 
apcd_table.Properties.VariableNames = {'apcd_type','generation','multi_gen','gen_share'}; % name the headers 
apcd_table = sortrows(apcd_table,'generation','descend'); % sort rows for convenience
end



