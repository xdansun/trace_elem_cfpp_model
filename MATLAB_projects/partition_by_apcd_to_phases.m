function [lit_phases_hg, lit_phases_se, lit_phases_as, lit_phases_cl] = ...
    partition_by_apcd_to_phases(lit_partition_by_apcd)
% description needed 

% calculate air, solid, and liquid removals 
% merge pm removal into so2 removal; use strcmp to determine which are
% worth adding 

%% plot by air pollution control combination 
% 0 is irrelevant, 100 is csESP, 101 is csESP+ACI, 200 is hsESP, 300 is FF,
% 301 is FF + ACI , 1100 is wFGD + csESP, 1110 is SCR+csESP+wFGD, 1200 is
% wFGD + hsESP, 1210 is wFGD+hsESP+SCR, 1300 FF+wFGD, 1301 ACI+FF+wFGD, etc
% it may be worth only showing control combinations we have data for 

%% calculate solids, liquids, and gas for each trace element 
gas = zeros(size(lit_partition_by_apcd,1),4);
liq = zeros(size(lit_partition_by_apcd,1),4);
solid = zeros(size(lit_partition_by_apcd,1),4);
for i = 1:size(lit_partition_by_apcd,1)
    gas(i,:) = lit_partition_by_apcd{i,7};
    liq(i,:) = lit_partition_by_apcd{i,6};
    solid(i,:) = lit_partition_by_apcd{i,3} + lit_partition_by_apcd{i,4} + lit_partition_by_apcd{i,5};
end 
gas(gas == 0) = nan; 
liq(liq == 0) = nan; 
solid(solid == 0) = nan; 

lit_phases = horzcat(lit_partition_by_apcd(:,1), lit_partition_by_apcd(:,2)); %,...
for i = 1:size(lit_phases,1)
    lit_phases(i,3) = {solid(i,:)}; 
    lit_phases(i,4) = {liq(i,:)}; 
    lit_phases(i,5) = {gas(i,:)}; 
    % double check that solid, liq, gases add up to one
    for k = 1:4
        if abs(solid(i,k) + liq(i,k) + gas(i,k) - 1) > 1e-5 && isnan(solid(i,k) + liq(i,k) + gas(i,k)) ~= 1 % if the phases do not add up to one or is not a number 
            [i,k]
            solid(i,k) + liq(i,k) + gas(i,k)
            error('problem'); 
        end 
    end 
end 
%     table2cell(array2table(solid)),table2cell(array2table(liq)),table2cell(array2table(gas))); 

lit_phases_by_TE = lit_partition_by_apcd(:,1:2); 
for k = 1:4
    for i = 1:size(lit_phases,1)
        lit_phases_by_TE(i,k+2) = {[solid(i,k) liq(i,k) gas(i,k)]}; 
    end 
end 
lit_phases_by_TE = cell2table(lit_phases_by_TE); 
lit_phases_by_TE = sortrows(lit_phases_by_TE,'lit_phases_by_TE1','ascend');
lit_phases_by_TE = table2cell(lit_phases_by_TE); 

lit_phases_hg = sep_lit_remov_by_TE(lit_phases_by_TE,1);
lit_phases_se = sep_lit_remov_by_TE(lit_phases_by_TE,2);
lit_phases_as = sep_lit_remov_by_TE(lit_phases_by_TE,3);
lit_phases_cl = sep_lit_remov_by_TE(lit_phases_by_TE,4);

end 

function lit_phase_TE = sep_lit_remov_by_TE(lit_phases, k)
%% description: 
% separates "lit_phases" by trace elements and removes all studies that do
% not have removal data 

%%
lit_phase_TE = zeros(size(lit_phases,1),4); % apcds, solid, liq, gas 
for i = 1:size(lit_phases,1)
    lit_phase_TE(i,:) = horzcat(lit_phases{i,2}, lit_phases{i,k+2}); 
    flag = isnan(lit_phase_TE(:,end)); % mark any studies that do not have gas partition fraction 
end 
lit_phase_TE = horzcat(lit_phases(:,1), table2cell(array2table(lit_phase_TE))); 
lit_phase_TE(flag == 1,:) = []; 

end 
