function plot_coal_temporal_variation(cq_month_hg, cq_month_se, cq_month_as, cq_month_cl, plant_gen)
% plot temporal variation in trace element concentrations

figure('Color','w','Units','inches','Position',[0.25 0.25 8 8]) % was 1.25
axes('Position',[0.2 0.15 0.75 0.75]) % x pos, y pos, x width, y height
for k = 1:4 
    subplot(2,2,k);
    hold on; 
    if k == 1
        set(gca, 'Position', [0.15 0.6 0.3 0.33])
        cq_month = array2table(cq_month_hg);
    elseif k == 2
        set(gca, 'Position', [0.6 0.6 0.3 0.33])
        cq_month = array2table(cq_month_se);
    elseif k == 3
        set(gca, 'Position', [0.15 0.15 0.3 0.33])
        cq_month = array2table(cq_month_as);
    elseif k == 4
        set(gca, 'Position', [0.6 0.15 0.3 0.33])
        cq_month = array2table(cq_month_cl);
    end 
    cq_month.Properties.VariableNames(1) = {'Plant_Code'};
    cq_month = innerjoin(cq_month, plant_gen); % merge generation information 
    cq_month = sortrows(cq_month,'Gen_MWh','descend');
    plants_to_plot = [3 9:10 99:100];
    plot(table2array(cq_month(plants_to_plot,2:13))','*--') % the plants are fairly arbitrarily chosen

    set(gca,'FontName','Arial','FontSize',13)
    a=gca;
   
    if k == 1
        ylabel({'Median Hg concentration', 'in coal blend (ppm)'}); 
    elseif k == 2
        ylabel({'Median Se concentration', 'in coal blend (ppm)'}); 
    elseif k == 3
        ylabel({'Median As concentration', 'in coal blend (ppm)'}); 
    elseif k == 4
        ylabel({'Median Cl concentration', 'in coal blend (ppm)'}); 
    end 
    xlabel('Months in 2015'); 
    if k == 1
        legend(num2str(cq_month.Plant_Code(plants_to_plot)),...
            'Location','SouthEast'); legend boxoff; 
    end 
    grid off;
    title('');

    set(a,'box','off','color','none')
    b=axes('Position',get(a,'Position'),'box','on','xtick',[],'ytick',[]);
    axes(a)
    linkaxes([a b])
    scale = [0.2 5 20 1200]; 
    axis([0 13 0 scale(k)]);
    
end 

print('../Figures/Fig_SI_coal_temporal_variation','-dpdf','-r300');

end 
