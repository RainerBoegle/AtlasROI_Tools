%% look at stats vals distribution
ClusterNr_LocMax = LocMaxStruct.ClusterNo;
StatsVals %check availability

%% open clustering nifti
try
    [Hcl, colors] = DisplayClusters(spm_select(1,'image','Select the clustering output image associated with the current LocMaxStruct...'));
catch
    bg = [1 1 1; 0 0 0; .05 .05 .05; .1 .1 .1; .15 .15 .15; .25 .25 .25; .35 .35 .35; .45 .45 .45; .5 .5 .5; .65 .65 .65; .75 .75 .75; .85 .85 .85; .9 .9 .9]; %white black gray(s)
    %make colors
    colors = distinguishable_colors(length(unique(ClusterNr_LocMax(:))),bg);
end

%% init
Clusters = unique(ClusterNr_LocMax(:));
LocMaxStatsVals_n_ClusterStats = zeros(length(Clusters),4);
NVoxCl = zeros(length(Clusters),1);

%% pick local max stats val of cluster as maximum (as before) and generate average stats val as quantiles and get number of voxels per cluster
for IndCluster = 1:length(Clusters)
    CurrStatsVals = StatsVals(ClusterNr_LocMax==Clusters(IndCluster));
    NVoxCl(IndCluster) = numel(CurrStatsVals);
    LocMaxStatsVals_n_ClusterStats(IndCluster,1)   = max(CurrStatsVals(:));
    LocMaxStatsVals_n_ClusterStats(IndCluster,2:4) = quantile(CurrStatsVals(:),[.5 .25 .75]); %median, 1st Quartile, 3rd Quartile
end

%% plot
LegendStr = {'LocMax','ClMedian','Cl1stQrt','Cl3rdQrt','NVoxel'};
ColorStrings = {'r','m','g','b'};
figure(42); clf;
for Ind = 1:size(LocMaxStatsVals_n_ClusterStats,2)
    [AX,H1{Ind,1},H2{1,1}] = plotyy(1:length(Clusters),LocMaxStatsVals_n_ClusterStats(:,Ind),1:length(Clusters),NVoxCl); title('Cluster Statistics and LocalMaxima'); hold on
    set(H1{Ind,1},'color',ColorStrings{Ind})
    set(H2{1,1},'marker','x','color',[.5 .5 .5],'linestyle','--','linewidth',2); %NVoxel should be gray
end
xlabel('Cluster Number')
ylabel(AX(1),'StatsVals') % left y-axis
ylabel(AX(2),'NVoxel per Cluster') % right y-axis
legend(cell2mat([H1(:);H2]),LegendStr);
for IndCl = 1:size(LocMaxStatsVals_n_ClusterStats,1)
    H1new = plot(AX(1),IndCl,LocMaxStatsVals_n_ClusterStats(IndCl,1)); hold on
    %[AX,H1new,H2new] = plotyy(IndCl,LocMaxStatsVals_n_ClusterStats(IndCl,1),IndCl,NaN.*NVoxCl(IndCl)); hold on
    set(H1new,'marker','o','color',colors(IndCl,:),'linewidth',2);
    %set(H2new,'marker','o','color',colors(IndCl,:),'linewidth',2); 
end
    
