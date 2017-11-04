function output_cell = num2str_table(table)
    % This function converts all of the numerics in a table to a string
    % and sends it back as a cell. This step is necessary for string
    % concatenation 
    %
    % inputs:
    % table - the table of interest
    %
    % outputs:
    % output_cell - cell version of table input 
    
cell = table2cell(table);

% iterate along the entire table 
for i = 1:size(table,1) 
    for j = 1:size(table,2);
        temp = cell{i,j}; % grab the cell entry 
        if isnumeric(temp) == 1 % if a number
            cell{i,j} = num2str(temp); % convert the number to a string
        end
    end
end

output_cell = cell;

end