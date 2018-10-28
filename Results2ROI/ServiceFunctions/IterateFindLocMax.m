function [ClusterNr_LocMax,Coords_LocMax,StatsVals_LocMax,DistMat_LocMax,LocMaxCoords,LocMaxCoGCoords,LocMaxStatsVals,DistMat] = IterateFindLocMax(Coords,StatsVals,SearchDist_mm,ConnectionsMat,Verbose)
%        [ClusterNr_LocMax,Coords_LocMax,StatsVals_LocMax,DistMat_LocMax,LocMaxCoords,LocMaxCoGCoords,LocMaxStatsVals,DistMat] = IterateFindLocMax(Coords,StatsVals,SearchDist_mm);
% This function will assign all voxels in the list "Coords"(nx3)[in mm] to their
% local maximum that is found in the list "StatsVals"(nx1)[something like z-, F- or t-vals]
% given the search-distance "SearchDist_mm"(1x1) in mm.
% NB: As an additional input the ConnectionsMatrix of the voxels can be given,
%     which will only allow connected voxels to be searched in appropriate SearchDist_mm.
%
%Outputs:
%         LocMaxCoords      <--   Coordinates (NClustersx3) of the Local Maxima that were found in SearchDist_mm distance.
%         LocMaxCoGCoords   <--   AVERAGE Coordinates (NClustersx3) of the CLUSTER for the Local Maxima that were found in SearchDist_mm distance.
%         LocMaxStatsVals   <--   Statistics Value (NClustersx2) of the local maxima; 1st Column is local maxima 2nd Column is average stats val of cluster.
%         ClusterNr_LocMax  <--   The Cluster Number for each local maximum from the highest to the lowest local maximum stats-values.
%                                 NB: You can get LocMaxCoords    by LocMaxCoords    = Coords_LocMax(ClusterNr_LocMax,:); 
%                                     and you get LocMaxStatsVals by LocMaxStatsVals = StatsVals_LocMax(ClusterNr_LocMax);
%                                     Also NClusters = max(ClusterNr_LocMax);
%         Coords_LocMax     <--   NEW Coordinates(nx3) made from moving original Coordinates(nx3) to the Local Maxima Coordinate
%                                 (using "DistMat", "SearchDist_mm" and "StatsVals")
%         StatsVals_LocMax  <--   NEW Statistic-Values(nx1) made from assigning Local Maxima values to original Statistic-Values(nx1)
%         DistMat_LocMax    <--   NEW Distance-Matrix(nxn) made by considering the Euclidean-Distances of the NEW Coordinates(nx3) "Coords_LocMax",
%                                 which themselves were made by looking up the local maxima coordinate, i.e. the maximum statistics value
%                                 in the distance below "SearchDist_mm" using the ORIGINAL Distance-Matrix(nxn) "DistMat"(nxn) as a guidance.
%         DistMat           <--   ORIGINAL Distance-Matrix(nxn) made by considering the Euclidean-Distances of the ORIGINAL Coordinates "Coords"(nx3)
%
%Usage:
%      [ClusterNr_LocMax,Coords_LocMax,StatsVals_LocMax,DistMat_LocMax,LocMaxCoords,LocMaxCoGCoords,LocMaxStatsVals,DistMat] = IterateFindLocMax(Coords,StatsVals,SearchDist_mm);
%      [ClusterNr_LocMax,Coords_LocMax,StatsVals_LocMax,DistMat_LocMax,LocMaxCoords,LocMaxCoGCoords,LocMaxStatsVals,DistMat] = IterateFindLocMax(xSPM.XYZmm',xSPM.Z',8); %use SPM-statistics results and search local maxima in 8mm distance.
%
%
%V1.9
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(25.December.2014): Additional Outputs and Ordering of Outputs. Ready for main script. (V1.5 - 21.December.2014: Speeded up version.) 

%NB: this is kind of a ensemble approach because each voxel get's its own
%preparation that is the initial condition for all of them, like a ensemble
%being prepared in the same way. 

%% checks
try
    isempty(ConnectionsMat);
catch
    ConnectionsMat = [];
end
if(~isempty(ConnectionsMat))
    UseConnectionsMat = 1;
else
    UseConnectionsMat = 0;
end

try 
    Verbose;
catch
    Verbose = 0;
end

if(Verbose&&UseConnectionsMat)
    disp(['Using ConnectionsMatrix to constrain search in a distance of ',num2str(SearchDist_mm),'mm']);
end
    

%% Initial distances
% DistMat = MakeDistMat(Coords);
DistMat = squareform(pdist(Coords,'euclidean'),'tomatrix');

%% Use Local Maxima for assigning voxel distances, i.e. move location to next local maxima
Coords_LocMax    = zeros(size(Coords));
StatsVals_LocMax = zeros(size(StatsVals));
for IndVox1 = 1:size(Coords,1)
    %check all values in search distance for maximum and assign this coord to the voxel
    RelevantDistances    = DistMat(IndVox1,:); %The distances from the current voxel
    if(UseConnectionsMat)
        RelevantDistances(~ConnectionsMat(IndVox1,:)) = Inf; %remove all those that are not connected to current voxel.
    end
    IndicesRelDist       = find(RelevantDistances(:)<=SearchDist_mm); %all those voxels that are in search distance 
    
    if(length(IndicesRelDist)<4 && Verbose) %check
        disp(['Warning Voxel ',num2str(IndVox1),' has only ',num2str(length(IndicesRelDist)),'Neighbors in ',num2str(SearchDist_mm),'mm SearchDistance!']);
    end
    
    RelevantStatsVals    = StatsVals(IndicesRelDist); %statistics scores from all those voxels that are in search distance 
    [TmpMax,IndexMax]    = max(RelevantStatsVals(:)); %find maximum
    IndexNearestLocalMax = IndicesRelDist(IndexMax); %Index of voxel that is the local maximum for current voxel
    Coords_LocMax(IndVox1,:) = Coords(IndexNearestLocalMax,:); %assign location of local maximum to current voxel
    StatsVals_LocMax(IndVox1)= TmpMax;
end

%% assign clusters
[Sorted_StatsVals_LocMax,SortingIndices_StatsVals_LocMax] = sort(StatsVals_LocMax,'descend'); clear Sorted_StatsVals_LocMax
Sorted_Coords_LocMax = Coords_LocMax(SortingIndices_StatsVals_LocMax,:);

ClusterNr_LocMax = zeros(size(StatsVals_LocMax));
ClusterInd = 1; %init
while(~isempty(Sorted_Coords_LocMax))
    CurrCoord = Sorted_Coords_LocMax(1,:); %coordinate to check
    %assign Cluster numbers
    for Ind = 1:length(StatsVals_LocMax)
        CheckCoord = Coords_LocMax(Ind,:);
        if((CurrCoord(1)==CheckCoord(1)) && (CurrCoord(2)==CheckCoord(2)) && (CurrCoord(3)==CheckCoord(3)))
            ClusterNr_LocMax(Ind) = ClusterInd;
        end
    end
    %remove all Coords from the list that are the same than CurrCoord (NB: Needs to be done in an extra loop because the list will be changing every iteration.) 
    DeleteInds = [];
    for Ind = 1:size(Sorted_Coords_LocMax,1)
        if((CurrCoord(1)==Sorted_Coords_LocMax(Ind,1)) && (CurrCoord(2)==Sorted_Coords_LocMax(Ind,2)) && (CurrCoord(3)==Sorted_Coords_LocMax(Ind,3)))
            DeleteInds = [DeleteInds; Ind];
        end
    end
    Sorted_Coords_LocMax(DeleteInds,:) = [];
    if(Verbose) %check
        disp(['Cluster Size of Cluster ',num2str(ClusterInd),' is ',num2str(length(DeleteInds)),'Voxels.']);
    end
    ClusterInd = ClusterInd+1; %done with this one so let's raise it.
end

%assign cluster coords and stats vals
LocMaxCoords    = zeros(max(ClusterNr_LocMax(:)),3); %coordinate of the local maxima
LocMaxCoGCoords = zeros(max(ClusterNr_LocMax(:)),3); %average coordinate of the cluster of local maxima
LocMaxStatsVals = zeros(max(ClusterNr_LocMax(:)),2); %stats vals of local maxima (1st column) and the average of the cluster (2nd column)
for IndCluster = 1:max(ClusterNr_LocMax(:))
    IndexCurrLocMax = find(ClusterNr_LocMax==IndCluster); IndexCurrLocMax = IndexCurrLocMax(1); %get first one (they are all the same)
    LocMaxCoords(IndCluster,:)    = Coords_LocMax(IndexCurrLocMax,:); %local maxima coordinate
    LocMaxCoGCoords(IndCluster,:) = mean(Coords(ClusterNr_LocMax==IndCluster,:),1); %average coordinate of the cluster of the local maxima
    LocMaxStatsVals(IndCluster,1) = StatsVals_LocMax(IndexCurrLocMax); %value at the local maxima
    LocMaxStatsVals(IndCluster,2) = mean(StatsVals_LocMax(ClusterNr_LocMax==IndCluster)); %average of the cluster
end

%% Distances after assignment to LocMax
% DistMat_LocMax = MakeDistMat(Coords_LocMax);
DistMat_LocMax = squareform(pdist(Coords_LocMax,'euclidean'),'tomatrix');


end