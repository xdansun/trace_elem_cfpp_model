function coal_gen_boiler_wapcd_out = identify_apcd_base10(coal_gen_boiler_wapcd) 
% this function pulls all of the apcds associated with the generator and
% renames the combination into a numeric code for easy identification. This
% is different thant he original, because this one employs base 10 
% 
% inputs
% coal_gen_boiler_wapcd - the cfpp:generator:boiler:apcd:fuels table
%
% outputs
% coal_gen_boiler_wapcd_out - same table as coal_gen_boiler_wapcd with an
% additional column that identifies the apcd combination 

%% create numerical codes for individual controls 
% SO2 control installed is thousands place
% PM control is hundreds place
% NOx control is tens place
% mercury control is ones place 
base10_table = cell(1,2); % 
base10_table(1,:) = {'csESP',100}; 
base10_table(2,:) = {'hsESP',200}; 
base10_table(3,:) = {'FF',400};
base10_table(4,:) = {'SCR',10}; 
base10_table(5,:) = {'wFGD',1000}; 
base10_table(6,:) = {'dFGD',2000};
base10_table(7,:) = {'ACI',1}; 

%%
% create an array of apcd codes to mark the acpd combination for convenience 
apcd_code = zeros(size(coal_gen_boiler_wapcd,1),1); 
% ESPs = [0 0 0]; % matrix made for counting the number of hs and cs ESPs
% for testing 
for j = 1:size(coal_gen_boiler_wapcd,1) % for each generator 
    apcd_list = {''}; % create an empty cell 
    % pull apcds for the different pollution controls (PM, SO2, NOx, and Hg) 
    apcd_pm = coal_gen_boiler_wapcd{j,'PM'}{1,1};
    apcd_so2 = coal_gen_boiler_wapcd{j,'SO2'}{1,1};
    apcd_nox = coal_gen_boiler_wapcd{j,'NOx'}{1,1};
    apcd_hg = coal_gen_boiler_wapcd{j,'Hg'}{1,1};

    if size(apcd_pm,1) > 0 % if there is a pm control 
        apcd_list = vertcat(apcd_list, apcd_pm{:,1}); % append all pm controls 
    end
    if size(apcd_so2,1) > 0 % if there is an so2 control 
        apcd_list = vertcat(apcd_list, apcd_so2{:,1}); % append all so2 controls 
    end
    if size(apcd_nox,1) > 0 % if there is a nox control 
        apcd_list = vertcat(apcd_list, apcd_nox{:,1}); % append all nox controls 
    end
    if size(apcd_hg,1) > 0
        apcd_list = vertcat(apcd_list,apcd_hg{:,1}); 
    end 

    % remove any redundant apcd entries
    apcd_list = table2cell(unique(cell2table(apcd_list)));
    
    % The APCD combinations we expect to see are 
    % ESP, ACI+ESP, ESP+wFGD, ACI+ESP+wFGD, SCR+ESP+wFGD, ACI+SCR+ESP+wFGD
    % note that we have a CS-ESP and a HS-ESP split.  
    if sum(strcmp(apcd_list, 'csESP') + strcmp(apcd_list, 'hsESP')) > 1
        j
    end 
    for k = 1:size(apcd_list,1)
        apcd = apcd_list{k,1}; 
        match = strcmp(apcd,base10_table(:,1));
        if sum(match) > 0 
            apcd_code(j) = apcd_code(j) +  base10_table{logical(match),2};
        end 
    end     

end 
%%
% append the apcd codes to the end of the table, name the header, and set
% it to the output 
coal_gen_boiler_wapcd(:,end+1) = array2table(apcd_code); 
coal_gen_boiler_wapcd.Properties.VariableNames(end) = {'apcds'};

coal_gen_boiler_wapcd_out = coal_gen_boiler_wapcd;

end 