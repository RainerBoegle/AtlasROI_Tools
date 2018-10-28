%% get test data
if(strcmp('ExampleData',questdlg('Try your own data or use example data?','Use Example data?','MyData','ExampleData','ExampleData')))
    if(0) %debug
        fname = questdlg('Use "ThresFWE_Map.img" or ""?','Which thresholded image?','ThresFWE_Map.img','ThresB_FWEmap.nii','ThresB_FWEmap.nii');
    else
        fname = 'ThresB_FWEmap.nii';
    end
    try
        MapExtractStruct = GetParamsFromMap(fname,[]);
    catch
        BaseDir = fileparts(mfilename('fullpath'));
        if(isempty(BaseDir))
            BaseDir = fileparts(which('EXAMPLE_ClusterStatsMap'));
        end
        MapExtractStruct = GetParamsFromMap([BaseDir,filesep,fname],[]);
    end
else
    MapExtractStruct = GetParamsFromMap(); %user data --> all selection is manual...
end

%% assign data
for IndData = 1:2
    if(isempty(eval(MapExtractStruct.ThresMap{IndData})))
        disp(['Skipping ',num2str(IndData),'.Entry because it is empty.']);
        continue;
    else
        disp(['Treating ',num2str(IndData),'.Entry for input Map with threshold Thres>',MapExtractStruct.ThresMap{IndData},'.']);
    end
    Coords    = MapExtractStruct.Voxels(IndData).Coords_mm; %dimensions are columns and datapoints are rows
    StatsVals = MapExtractStruct.Voxels(IndData).StatsVals; %statistic values per voxel
    VoxCoords = MapExtractStruct.Voxels(IndData).Coords_vox;
    
    %% minimum distance ???
    answer_SearchDist = inputdlg({'Search distance[mm]: '},'Search distance?',1,{'8'}); %get search distance from user
    LocMaxMinDist_mm  = eval(answer_SearchDist{1}); %search distance for local maxima
    clear answer_SearchDist %cleanup
    
    %% Verbose?
    if(strcmp('Yes',questdlg('Output diagnostic messages?','Verbose?','Yes','No','Yes')))
        Verbose = 1;
    else
        Verbose = 0;
    end
    
    %% use connectedness as well?
    if(strcmp('Yes',questdlg('Use Connections matrix?','ConnectMat?','Yes','No','No')))
        %% Have a look at connectedness over neighbors
        tic
        ConnectionsMat = FindConnectedVoxels(VoxCoords,Verbose);
        t_FindConnectedVoxels = toc;
        disp(['Time needed to run "FindConnectedVoxels" is ',num2str(t_FindConnectedVoxels),'s']);
        ConnectionsSum = sum(ConnectionsMat,2);
        
        %% display connectedness
        NVoxExp = 10^floor(log10((prod(quantile(ConnectionsSum(:),[.25 .5 .75])))^(1/length(quantile(ConnectionsSum(:),[.25 .5 .75]))))); %old; floor((median(ConnectionsSum(:))+quantile(ConnectionsSum(:),.25))/2); %median plus 20%
        figure(); clf;
        subplot(1,3,1); imagesc(ConnectionsMat,[0 1]); colormap(gray); title('connectivity matrix.');
        subplot(1,3,2); imagesc(repmat(ConnectionsSum,1,1),[0,NVoxExp]); title('sum of connections per voxel.');
        subplot(1,3,3); boxplot(ConnectionsSum,'notch','on','labels','ConnectionSums'); title('boxplot sum of connections.');
        
        %% Move Voxels to local maxima
        LocMaxStruct = FindAllLocMax(Coords,StatsVals,LocMaxMinDist_mm,{'VoxelConnections',ConnectionsMat},{'Verbose',Verbose});
    else
        try
            clear ConnectionsMat %making sure we don't have it around from a former call
        end
        LocMaxStruct = FindAllLocMax(Coords,StatsVals,LocMaxMinDist_mm,{'Verbose',Verbose});
    end
    
    %% fig for convergence plot
    if(evalin('base','exist(''Conv_fig_h'',''var'')'))
        Conv_fig_h = evalin('base','Conv_fig_h');
    else
        Conv_fig_h = figure();
        assignin('base','Conv_fig_h',Conv_fig_h);
    end
    
    %% show convergence
    figure(Conv_fig_h); clf;
    [AX,H1,H2]=plotyy(1:length(LocMaxStruct.Iterations.NClusters),LocMaxStruct.Iterations.NClusters,1:length(LocMaxStruct.Iterations.DistanceToConverge),LocMaxStruct.Iterations.DistanceToConverge);
    set(H1,'LineStyle','-','Marker','x');
    set(H2,'LineStyle','-','Marker','o');
    xlabel('Iteration'); title(['Convergence & number of Clusters for LocMax search [Minimum separation ',num2str(LocMaxMinDist_mm),'mm]']);
    % legend('Number of Clusters','Distance to CONVERGENCE');
    set(get(AX(1),'Ylabel'),'String','Number of Clusters')
    set(get(AX(2),'Ylabel'),'String','Distance to CONVERGENCE')
    
    %% change in distance matrix?
    if(evalin('base','exist(''ConvDist_fig_h'',''var'')'))
        ConvDist_fig_h = evalin('base','ConvDist_fig_h');
    else
        ConvDist_fig_h = figure();
        assignin('base','Conv_fig_h',ConvDist_fig_h);
    end
    
    Dist_ORG = squareform(pdist(Coords,'euclidean'),'tomatrix');
    
    figure(ConvDist_fig_h); clf;
    subplot(2,3,1); imagesc(Dist_ORG); title('Original distances'); %axis('square');
    for IndIter = 1:length(LocMaxStruct.Iterations.NClusters)
        Ind_i  = IndIter;
        Dist_i = LocMaxStruct.Iterations.DistMat_LocMax{IndIter};
        if((IndIter+1)<=length(LocMaxStruct.Iterations.NClusters))
            Ind_j = IndIter+1;
            Dist_j = LocMaxStruct.Iterations.DistMat_LocMax{IndIter+1};
        else
            Ind_j = IndIter;
            Dist_j = LocMaxStruct.Iterations.DistMat_LocMax{IndIter};
        end
        
        subplot(2,3,2); imagesc(Dist_i); title(['Distances  [    i= ',num2str(Ind_i),']']); %axis('square');
        subplot(2,3,3); imagesc(Dist_i-Dist_ORG,[-2.5*LocMaxMinDist_mm 2.5*LocMaxMinDist_mm]); title(['Difference [i-ORG=',num2str(Ind_j),'-ORG]']); %axis('square');
        
        subplot(2,3,4); imagesc(Dist_i); title(['Distances  [  i  =',num2str(Ind_i),']']); %axis('square');
        subplot(2,3,5); imagesc(Dist_j); title(['Distances  [j=i+1=',num2str(Ind_j),']']); %axis('square');
        subplot(2,3,6); imagesc(Dist_j-Dist_i,[-LocMaxMinDist_mm LocMaxMinDist_mm]); title(['Difference [ j-i =',num2str(Ind_j),'-',num2str(IndIter),']']); %axis('square');
        pause(1);
    end
    
    %% make NIFTI?
    if(strcmp('Yes',questdlg('Create NIFTI from Clustering and then display Clustering?','Display Clusters?','Yes','No','Yes')))
        if(~exist('ConnectionsMat','var'))
            ShowOverlayClusters(LocMaxStruct.ClusterNo,VoxCoords,MapExtractStruct.V_map,[pwd,filesep,'Clusters_',num2str(LocMaxMinDist_mm),'mm_MinDist_',date]);
        else
            ShowOverlayClusters(LocMaxStruct.ClusterNo,VoxCoords,MapExtractStruct.V_map,[pwd,filesep,'Clusters_',num2str(LocMaxMinDist_mm),'mm_MinDist_UsingConnectionsMatrix_',date]);
        end
    end
    
    %% save LocMaxStruct?
    if(strcmp('Yes',questdlg('Do you want to save the created LocalMaxima-Structure?','Save LocMaxStruct?','Yes','No','Yes')))
        uisave({'LocMaxStruct'},'LocMaxStruct.mat')
    end
end