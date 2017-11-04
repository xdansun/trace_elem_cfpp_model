function foo = table_scrub(cell, column_numbers, row_start)
    % the purpose of this function is to convert a portion of a cell, which
    % starts at a row (row_start) for select columns (defined by
    % column_numbers), into a table. The first row, indicated by row_start,
    % will be the headers of that table. This function will also reformat
    % the headers into a form that MATLAB tables can support. 
    %
    % inputs:
    % cell - cell of raw data 
    % row_start - row where data starts. This is the row of the headers of
    % the table 
    % column_numbers - the columns of the raw data we want. 
    %
    % outputs:
    % foo - the resulting table 

% convert the cell to a table     
foo = cell2table(cell(row_start+1:end,column_numbers));
% extract the headers from the input array and the index 
headers = cell(row_start,column_numbers);

% replace all characters in the cell at row_start that cannot be used in a
% table
headers = strrep(headers,' ','_');
headers = strrep(headers,'/','_');
headers = strrep(headers,'(','');
headers = strrep(headers,')','');
headers = strrep(headers,'%','');
headers = strrep(headers,sprintf('\n'),'_');
    
foo.Properties.VariableNames = headers; % assign headers to table
    
end