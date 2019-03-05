function [partitioning_lit, ww_ratio] = trace_elem_partition_lit
%% description:
% Compile all literature studies of trace element partitioning at coal
% fired power plants into a single set 
% note dFGDs are programed as PM control because that makes implementation
% easier
% inputs: none
%
% outputs: 
% partitioning_lit (cell) - compilation of partitioning of trace elements
% at each air pollution control device  
% ww_ratio (array) - compilation of trace elements partitionig
% between the gypsum and the wastewater waste streams of the wFGD
%%
addpath(genpath('literature'))
%% establish ww coefficients
ww_ratio = zeros(1,4); 

% establish ww ratio for cheng 
trace_exit_streams = cheng_trace_elem; 
for k = 1:4
    post_esp = trace_exit_streams(3:end,k); 
    ww_ratio(1,k) = post_esp(2)/sum(post_esp(1:2)); % Cl purge / (Cl purge + gypsum)
end 

% establish ww ratio for Alvarez Ayuso (not included because Alvarez-Ayuso
% did not study a US CFPP
% [trace_exit_streams, trace_phases, error] = alvarez_ayuso([1 1 1 1]); 
% for k = 1:4
%     post_esp = trace_exit_streams(3:end,k); 
%     ww_ratio(2,k) = post_esp(2)/sum(post_esp(1:2)); % for wFGD
% end 

%% create a cell that contains all studies and each unit's removal 
partitioning_lit = cell(1,7); 

% Karlsson has dFGD removal for Cl


partitioning_lit(end,:) = rubin_trace_elem; 
partitioning_lit(end+1,:) = klein_trace_elem; 
partitioning_lit(end+1,:) = brown_1999_csesp; 
partitioning_lit(end+1,:) = brown_1999_ff;
partitioning_lit(end+1,:) = helble_2000_trace_elem;
partitioning_lit(end+1,:) = brekke_1995_csesp;
partitioning_lit(end+1,:) = brekke_1995_ff;
partitioning_lit(end+1,:) = swanson_2013_esp;
partitioning_lit(end+1,:) = swanson_2013_esp;
partitioning_lit(end,2) = {200}; % swanson is csESP and hsESP 
partitioning_lit(end+1,:) = chu_porcella_1995_ff;
partitioning_lit(end+1,:) = flora_2002_aci_ff;
partitioning_lit(end+1,:) = pavlish_2003_csesp_wfgd; 
partitioning_lit(end+1,:) = pavlish_2003_hsesp_wfgd; 
partitioning_lit(end+1,:) = pavlish_2003_FF_wfgd; 

% this one is done differently for convenience 
partitioning_lit(end+1,1) = {'Cheng et al. (2009)'};
partitioning_lit(end,2) = {1110};
trace_exit_streams = cheng_trace_elem; 
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

partitioning_lit(end+1,:) = ondov_trace_elem; 
partitioning_lit(end+1,:) = laudal_2000_esp_wfgd;
partitioning_lit(end+1,:) = devito_2002_csesp_wfgd;
partitioning_lit(end+1,:) = chu_porcella_1995_esp_wfgd;
partitioning_lit(end+1,:) = laird_trace_elem_dsi;

% separate scripts were not created for convenience 
% ACI + PM controls 
% create entry for ACI controls
aci_removals = zeros(2,6); 
% first, for CSESP + ACI control combo 5 
aci_removals(1,1:6) = [94 85 70 94 65 73]/100; % see Table 5 and 7 of NRMRL study "Control of Mercury Emissions from Coal fired electric utility boilers: an update
% next for HSESP + ACI control combo 6 
aci_removals(2,1:2) = [40 80]/100; % see Table 7 of the above study 
aci_removals(aci_removals == 0) = nan; % set all zeros to NaN so they do not appear on plot
% note that ACI+FF removals listed in the NRMRL study has data for ACI+FF+SDA,
% which includes an SO2 control 

% add NRMRL (2005)
partitioning_lit(end+1,1) = {'NRMRL (2005)'};
partitioning_lit(end,2) = {101};
partitioning_lit(end,3) = {[0 nan nan nan]}; 
partitioning_lit(end,4) = {[mean(aci_removals(1,:)) nan nan nan]};
partitioning_lit(end,5) = {[0 nan nan nan]};
partitioning_lit(end,6) = {[0 nan nan nan]};
partitioning_lit(end,7) = {[1 - mean(aci_removals(1,:)) nan nan nan]};

partitioning_lit(end+1,1) = {'NRMRL (2005)'};
partitioning_lit(end,2) = {201};
partitioning_lit(end,3) = {[0 nan nan nan]}; 
partitioning_lit(end,4) = {[mean(aci_removals(2,1:2)) nan nan nan]};
partitioning_lit(end,5) = {[0 nan nan nan]};
partitioning_lit(end,6) = {[0 nan nan nan]};
partitioning_lit(end,7) = {[1 - mean(aci_removals(2,1:2)) nan nan nan]};

partitioning_lit(end+1,:) = felsvang_1994_dfgd_ff; 
partitioning_lit(end+1,:) = felsvang_1994_dfgd_ff_aci; 
partitioning_lit(end+1,:) = karlsson_1984_dFGD;

%% international studies 
% these are done using the old method, which produces the same output as
% the new method. The new coding method uses fewer lines and is easier to
% modify. The studies below have not been updated as they were not used in
% the main modeling method 
partitioning_lit(end+1,:) = aunela_tapola_dfgd; 

trace_exit_streams = meij_2007_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Meij et al. 2007'};
partitioning_lit(end,2) = {1110};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = lee_2006_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Lee et al. 2006 '};
partitioning_lit(end,2) = {1100};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = zhu_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Zhu 2016'};
partitioning_lit(end,2) = {1100};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = zhu_scr_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Zhu SCR 2016'};
partitioning_lit(end,2) = {1110};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = alvarez_ayuso([1 1 1 1]);
partitioning_lit(end+1,1) = {'Alvarez-Ayuso (2006)'};
partitioning_lit(end,2) = {1100};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = otero_rey_trace_elem;
partitioning_lit(end+1,1) = {'Otero-Rey et al. (2003)'};
partitioning_lit(end,2) = {100};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = aunela_tapola_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Aunela-Tapola (1998)'};
partitioning_lit(end,2) = {100};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = goodarzi_2004_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Goodarzi 1 (2004)'};
partitioning_lit(end,2) = {100};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = goodarzi_2004_hot_side_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Goodarzi 2 (2004)'};
partitioning_lit(end,2) = {200};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = guo_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Guo (2004, 2007)'};
partitioning_lit(end,2) = {200};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

trace_exit_streams = mokhtar_2014_bit_trace_elem([1 1 1 1]);
partitioning_lit(end+1,1) = {'Mokhtar (2014)'};
partitioning_lit(end,2) = {100};
for k = 1:5
    partitioning_lit(end,k+2) = {trace_exit_streams(k,:)}; % second row contains fly ash removal
end

%% define ww in gypsum + cl purge 
for i = 1:size(partitioning_lit,1)
    if partitioning_lit{i,2} > 1000 && strcmp(partitioning_lit{i,1}, 'Cheng et al. (2009)') ~= 1
        wfgd_waste = partitioning_lit{i,5} + partitioning_lit{i,6}; 
        partitioning_lit{i,5} = wfgd_waste.*(1-ww_ratio); 
        partitioning_lit{i,6} = wfgd_waste.*ww_ratio; 
    end 
    
end 

%% check partitioning coefficients by apcds add up to 1 
for i = 1:size(partitioning_lit,1)
    test = zeros(1,4);
    for k = 3:7
        test = vertcat(test,partitioning_lit{i,k}); 
    end 
    test(isnan(test)) = 0; 
    test = sum(test,'omitnan');
    for k = 1:4
        if abs(test(k) - 1) > 1e-5 && test(k) ~= 0
            display('problem'); 
            [i,k]
        end 
    end 
end 

%% check to make sure no negative stack values 
for i = 1:size(partitioning_lit,1)
    test = partitioning_lit{i,end};
    for k = 1:4
        if test(k) < -1e-10 
            % choose  it's possible for emissions to become negative due to roundoff error
            % so we use -1e-10 instead of 0 
            display('negative stacks'); 
            [i,k]
        end 
    end 
end 


end 

