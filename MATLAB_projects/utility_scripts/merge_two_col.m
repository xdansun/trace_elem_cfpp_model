function output_table = merge_two_col(table, col1, col2, name)
% This script combines two columns of a table into a third column as a
% string. That column is combined to the original table. The column with
% the combined content will always be at the end of the table.
%
% inputs:
% table - the table with the columns to merge
% col1 - header name of the first column 
% col2 - header name of the second column 
% name - name of the new header 
%
% outputs:
% output_table - table output with the combined column 

% create a temporary cell 
temp_cell = num2str_table(table);

% the column numbers are based on the variable/header name of the table.
% Therefore, we have to look for the numeric portion of the table. 
col_num_1 = find(strcmp(table.Properties.VariableNames, col1));
col_num_2 = find(strcmp(table.Properties.VariableNames, col2));

% create a temporary table to store output 
temp_table = table;
new_col = temp_cell(:,1); % create a new column 
for i = 1:size(table,1) % iterate along each row 
    row = temp_cell(i,:); % grab the row from the cell 
    if ~isempty(row{col_num_1}) && ~isempty(row{col_num_2}) % if both column have data, 
        temp = strcat(row{col_num_1}, '_', row{col_num_2}); % combine the line 
    else % otherwise assign it blank
        temp = '';
    end 
    new_col(i) = {temp}; % update new column 
end
temp_table = [temp_table new_col]; % add the new column to the end of the table 

temp_table.Properties.VariableNames(end) = name; % assign a header name to the new column 


output_table = temp_table; % ship the output table back 

end
