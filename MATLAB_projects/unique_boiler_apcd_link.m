function unique_apcd_link = unique_boiler_apcd_link(boiler_apcd_link,apcd_type)
% this function takes the list of all apcds of a particular type (pm, nox,
% so2, or hg) that are associated with the boiler and outputs a unique list
% of the boilers appearing with all of the apcds associated
%
% inputs
% boiler_apcd_link - a table of boiler links to their apcds 
% apcd_type - the type of apcd controls (PM, SO2, NOx, or Hg)
% outputs
% unique_apcd_link - a list of unique plant_boilers and all apcds
% associated with those boilers 

% get a list of all the unique plant-boiler links 
unique_apcd_link = table2cell(unique(boiler_apcd_link(:,'Plant_Boiler')));
% convert the entire link table to a cell 
temp_apcd_link = table2cell(boiler_apcd_link); 
for i = 1:size(unique_apcd_link,1)
    % grab the plant_boiler id 
    temp_plant_boiler = unique_apcd_link{i,1}; 
    % find all apcds associated with the plant_boiler 
    apcds_on_boiler = find(strcmp(temp_plant_boiler,temp_apcd_link(:,1))); 
    % create a cell of all apcds associated with the boiler 
    unique_apcd_link{i,2} = temp_apcd_link(apcds_on_boiler,end); 
end 

% convert the output into a table 
unique_apcd_link = cell2table(unique_apcd_link); 
unique_apcd_link.Properties.VariableNames = {'Plant_Boiler',apcd_type}; 


end 