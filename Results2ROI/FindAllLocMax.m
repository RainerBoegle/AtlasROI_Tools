function LocMaxStruct = FindAllLocMax(Coords_mm,StatsVals,LocMaxMinDist_mm,varargin)
% This function iterates the search for local maxima given the coordinates
% in mm, the statistics values at those coordinates and the MINIMUM
% distance that the local maxima should be separated from each other.
%
% IN CONTRADISTINCTION TO SPM_CLUSTER & FSL CLUSTER, THIS FUNCTION WILL
% RETURN ALL LOCAL MAXIMA FOR THE GIVEN SEPARATION.
%
% Futhermore, the output of this function can be written to a NIFTI that indicates the local
% maxima as VOIs, using LocMax2VOI.m, see help there.
%
% The iteration continues till the number of local maxima (given minimum
% distance) does not change any more for three iterations (this can be
% changed via additonal inputs).
%
%Inputs:
%        Coords_mm          (nx3)   A matrix indicating the 3D-coordinates of each voxel. 
%                                   Each voxel corresponds to a row with X,Y,Z coordinate value in the columns.
%        StatsVals          (nx1)   A column vector indicating statistics values of each voxel.
%                                   NB: Search is for maxima! 
%                                       If statistics values are not z-,F- or t-Vals (larger values indicate more significant),
%                                       i.e. P-Vals, then use StatsVals= 1-P to find maximum significant clusters.
%        LocMaxMinDist_mm   (1x1)   Distance in mm that the local maxima should (AT LEAST!) be apart. 
%
%Additional Inputs: NB should be given as pairs in CELL-format, i.e. {'switch',VALUE}
%        {'ExtraIterConverge',XtraNIterConverge}    (1x1)   A number indicating the additional number of iterations after convergence is reached.
%                                                           NB: This is used as a test to see if the convergence is truly reached and the default value is 3, i.e. three (3) additional (extra) iterations after convergence are done. 
%        {'VoxelConnections',ConnectMatrix}         (nxn)   A matrix indicating the connections between voxels, voxels that are connected have the values 1 
%                                                           and unconnected voxels have the value 0. 
%                                                           The user will be asked how to apply the connections matrix during the search for local maxima.
%                                                           NB1: If this matrix is not given then voxels can be connected to local maxima that are not directly neighbors,
%                                                                but within the minimum distance.
%                                                                However, sometimes it might be interesting to connect only those voxels in the minimum distance to local maxima that are connected, i.e. being neighbors.
%                                                           NB2: Connection can be either as direct neighbors OR over (arbitrary many of) their neighbors.
%                                                                The ConnectMatrix can be generated using FindConnectedVoxels.m, e.g. {'VoxelConnections',FindConnectedVoxels(Coords_vox)}.
%                                                                See the help comments of FindConnectedVoxels.m for an explanation of the input Coords_vox (the coordinates in voxel indices).
%        {'Verbose',1}                              (1x1)   If set to 1 (true==one) then diagnostic messages are output, default is 0, i.e. no output.
%
%
%OUTPUT:
%       LocMaxStruct.
%                   .ClusterNo           (nx1)           The cluster number for each voxel, from 1 to NClusters.
%                                                        The first is the global maxima and the last (NClusters) is the least significant local maxima
%                                                        in the minimum distance LocMaxMinDist_mm.
%                   .LocMaxCoords_mm     (NClustersx3)   The coordinate values of the local maxima.
%                   .CoG_Coords_mm       (NClustersx3)   The coordinate values of the CENTER of GRAVITY of the cluster, i.e. the average of all coordinates for the cluster of the local maxima.
%                   .LocMaxStats         (NClustersx2)   The first column is the statistics value at the local maxima
%                                                        and the second column is the average statistics values of the cluster.
%                   .LocMaxMinDist_mm    (1x1)           Distance in mm that the local maxima should (AT LEAST!) be apart.
%                   .IterNoOfConvergence (1x1)           The index of the iteration in the iterations subfield that corresponds to the EARLIEST OCCURENCE of convergence, i.e. when we saved this result.
%                   .Iterations.         (Struct)        A structure field containing the results of all interations.
%
%
%
%
%Usage:
%       LocMaxStruct = FindAllLocMax(Coords_mm,StatsVals,LocMaxMinDist_mm,varargin);
%       LocMaxStruct = FindAllLocMax(Coords_mm,StatsVals,LocMaxMinDist_mm);
%       LocMaxStruct = FindAllLocMax(Coords_mm,StatsVals,LocMaxMinDist_mm,{'Verbose',1},{'VoxelConnections',ConnectMatrix},{'ExtraIterConverge',XtraNIterConverge});
%
%
%
%V1.2
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment V1.2: (31.01.2015): Bug-fix "LocMaxStruct.LocMaxStats" had identical columns before, but that is fixed now. V1.1: (25.12.2014): initial implementation (changed version from test script FindAllLocMax.m)

%% check inputs
if(size(Coords_mm,2)~=3)
    error('ERROR: Coords_mm, the coordinates in mm has the wrong dimension. Should be a matrix with three (3) columns!');
end
if((size(StatsVals,1)~=size(Coords_mm,1))||(size(StatsVals,2)~=1))
    error('ERROR: StatsVals, the statistics values per voxel does not have the right shape. Should be a column vector with one entry per voxel in Coords_mm.');
end
if(length(LocMaxMinDist_mm)~=1)
    error('ERROR: LocMaxMinDist_mm, the minimum distance of the local maxima has to be a number!');
end

%% check for additional inputs
if(nargin>3)
    ExtraInputs = varargin;
    [ConnectMat,XtraNIterConverge,Verbose]=EvalXtraInputs(ExtraInputs,size(Coords_mm,1));
else
    %[ConnectMat,XtraNIterConverge,Verbose]=EvalXtraInputs([],size(Coords_mm,1)); %get defaults
    ConnectMat = [];
    XtraNIterConverge = 3;
    Verbose = 0;
end

%% run iterations 
if(size(Coords_mm,1)<=1500)
    if(size(Coords_mm,1)<500)
        NIterMax   = round(size(Coords_mm,1)/5); %maximal iterations are a fifth of the number of voxels!
    else
        NIterMax   = round(size(Coords_mm,1)/10); %maximal iterations are one tenth of the number of voxels!
    end
else
    if(size(Coords_mm,1)<5000)
        NIterMax   = round(size(Coords_mm,1)/5); %maximal iterations are a fifth of the number of voxels!
    else
        NIterMax   = 1000; %this is the absolute maximum.
    end
end

tic; %start the clock!       
KeepIterating      = 1; %init (ALSO USE AS COUNTER)
ConvergenceOccured = 0; %init
Coords_LocMax      = Coords_mm; %init
while(KeepIterating)
    %iterate voxel distribution and save
    [ClusterNr_LocMax,Coords_LocMax,StatsVals_LocMax,DistMat_LocMax,LocMaxCoords,LocMaxCoGCoords,LocMaxStatsVals] = IterateFindLocMax(Coords_LocMax,StatsVals,LocMaxMinDist_mm,ConnectMat,Verbose);
    %save current iteration
    LocMaxStruct.Iterations.ClusterNr_LocMax{KeepIterating,1} = ClusterNr_LocMax;
    LocMaxStruct.Iterations.Coords_LocMax{KeepIterating,1}    = Coords_LocMax;
    LocMaxStruct.Iterations.StatsVals_LocMax{KeepIterating,1} = StatsVals_LocMax;
    LocMaxStruct.Iterations.DistMat_LocMax{KeepIterating,1}   = DistMat_LocMax;
    if(KeepIterating==1)
        rSSD = max(ClusterNr_LocMax(:)); %init from first step.
    else
        rSSD = sqrt((max(LocMaxStruct.Iterations.ClusterNr_LocMax{KeepIterating-1}(:))-max(ClusterNr_LocMax(:)))^2); %squareroot of the squared successive distance
    end
    LocMaxStruct.Iterations.DistanceToConverge(KeepIterating,1) = rSSD; %squareroot of the squared successive difference.
    %if verbose inform about current iteration.
    if(Verbose)
        if(ConvergenceOccured)
            disp([num2str(KeepIterating),'.Iteration (',num2str(max(ClusterNr_LocMax(:))),'Clusters), CONVERGENCE OCCURED ALREADY! Current distance from Convergence point: ',num2str(rSSD)]);
        else
            disp([num2str(KeepIterating),'.Iteration (',num2str(max(ClusterNr_LocMax(:))),'Clusters). Current distance from Convergence point: ',num2str(rSSD)]);
        end
    end
    
    %check if convergence has happened (at least once)
    if(rSSD==0)
        if(~ConvergenceOccured) %make sure to only save the result at the convergence point, in case we have odd behavior later for some reason.
            %save this as final result
            LocMaxStruct.ClusterNo          = ClusterNr_LocMax; %(NVoxelx1)      The (final) cluster number per input voxel.
            LocMaxStruct.LocMaxCoords_mm    = LocMaxCoords;     %(NClustersx3)   The coordinate values of the local maxima.
            LocMaxStruct.CoG_Coords_mm      = LocMaxCoGCoords;  %(NClustersx3)   The coordinate values of the CENTER of GRAVITY of the cluster, i.e. the average of all coordinates for the cluster of the local maxima.
            LocMaxStruct.LocMaxStats        = GetLocMax_n_ClusterAverage_StatsVals(StatsVals,ClusterNr_LocMax); %OLD: LocMaxStatsVals;  %(NClustersx2)   The first column is the statistics value at the local maxima and the second column is the average statistics values of the cluster.
            if(sum((LocMaxStruct.LocMaxStats(:,1)-LocMaxStatsVals(:,1)).^2)~=0) %check the assignments
                disp('unexpected difference! check stats vals!');
            end
            LocMaxStruct.LocMaxMinDist_mm   = LocMaxMinDist_mm; %(1x1)           The minimum distance of the local maxima.
            LocMaxStruct.IterNoOfConvergence= KeepIterating;    %(1x1)           The index of the iteration in the iterations subfield that corresponds to the EARLIEST OCCURENCE of convergence, i.e. when we saved this result.
            if(~isempty(ConnectMat))
                LocMaxStruct.ConnectMat  = ConnectMat;       %(NVoxelxNVoxel) The connections matrix for all voxels that was used.
            end
            ConvergenceOccured = 1; %now is the time/iteration that reached convergence for the first time, i.e. same number of clusters as before.
        end
    end
    
    %update counter or quit; check if convergence was noted AND keep track of the behavior of the extra iterations after convergence.
    if(ConvergenceOccured)
        %check if we reached additional iterations after convergence
        if(KeepIterating>(LocMaxStruct.IterNoOfConvergence+XtraNIterConverge))
            KeepIterating = 0; %end
        else
            KeepIterating = KeepIterating+1; %next iteration
        end
        if(Verbose && (rSSD~=0))
            disp(['WARNING!!! We had a convergence before (',num2str(LocMaxStruct.IterNoOfConvergence),'.Iteration), but now we are again at a distance of ',num2str(rSSD),'>0 from convergence!?']);
        end
    else
        KeepIterating = KeepIterating+1; %next iteration
    end
    
    if(KeepIterating>=NIterMax)
        error('ERROR! NIterMax reached. Something is strange.');
    end
end
t_iterations = toc;

%% evaluate final result
LocMaxStruct.Iterations.NClusters = zeros(length(LocMaxStruct.Iterations.DistanceToConverge),1);
for IndIter = 1:length(LocMaxStruct.Iterations.DistanceToConverge)
    LocMaxStruct.Iterations.NClusters(IndIter) = max(LocMaxStruct.Iterations.ClusterNr_LocMax{IndIter}(:));
end

disp(' ');
disp(['Search for LOCAL MAXIMA with a minimum distance of ',num2str(LocMaxMinDist_mm),'mm reached convergence after ',num2str(LocMaxStruct.IterNoOfConvergence),' Iterations.']);
if(~isempty(ConnectMat))
    disp('[NB: Voxel-connectedness was used for constraining the clustering.]');
end
if(XtraNIterConverge>=2)
    AfterConvergenceDist = LocMaxStruct.Iterations.DistanceToConverge(LocMaxStruct.IterNoOfConvergence:end);
    if(sum(AfterConvergenceDist(:))~=0)
        disp('WARNING: The distance to the convergence point, i.e. the squareroot of the successive difference of number of clusters, did not stay zero, after the first time "zero-distance" had been reached.');
        disp('WARNING: Note that the first reach of "zero-distance" is the final result that was saved.');
        disp('WARNING: You can investigate the results of each iteration by looking at the data saved in the "Iterations"-field of the output struct.');
    else
        disp(['The number of clusters did not change during the additional ',num2str(XtraNIterConverge),'-iterations.']);
        disp( 'CONCLUSION: It is most likely that a stable configuration has been reached.');
    end
else
    if(XtraNIterConverge==1)
        disp('The number of clusters did not change during the additional iteration.');
        disp('CONCLUSION: It is probable that a stable configuration has been reached.');
    else
        disp('The iteration was stopped at the convergence point.');
        disp('CONCLUSION: It is unlikely that further iterations might not have stayed at that configuration');
        disp('            and therefore it is quite likely that a stable configuration has been reached.');
    end
end
disp(['Number of LOCAL MAXIMA at convergence was ',num2str(max(LocMaxStruct.ClusterNo(:))),'. (Total time for all iterations was ',num2str(t_iterations),'s)']);
disp(' ');

end

%% subfunctions
function [ConnectMat,XtraNIterConverge,Verbose]=EvalXtraInputs(XtraInputs,NVoxel)
%% init DEFAULTS
ConnectMat = []; %init as not given
XtraNIterConverge = 3; %init as 3
Verbose = 0; %init as not set

%% Go over extra inputs and evaluates the switches.
if(~isempty(XtraInputs)) %something has been input, therefore check.
    for IndXtraInputs = 1:length(XtraInputs)
        CurrXtra = XtraInputs{IndXtraInputs};
        if(~iscell(CurrXtra))
            error('ERROR: Extra Inputs must be given as cell!');
        else
            if(length(CurrXtra)~=2)
                error('ERROR: Each extra Input must be a cell of length 2!');
            end
        end
        switch(CurrXtra{1})
            case 'VoxelConnections'
                ConnectMat = CurrXtra{2};
                if(size(ConnectMat,1)~=size(ConnectMat,2))
                    if(size(ConnectMat,2)==1)
                        ConnectMat = squareform(ConnectMat,'tomatrix');
                    else
                        error('ERROR: Extra Input "ConnectMatrix", i.e. Voxel-Connections must be a square matrix of size NVoxel-x-NVoxel! (OR A SQUAREFORM)');
                    end
                else
                    if(size(ConnectMat,1)~=NVoxel)
                        error('ERROR: Extra Input "ConnectMatrix", i.e. Voxel-Connections must be a square matrix of size NVoxel-x-NVoxel!');
                    end
                end
            case 'ExtraIterConverge'
                XtraNIterConverge = CurrXtra{2};
                if(length(XtraNIterConverge)~=1)
                    error('ERROR: Extra Input "ExtraNIterConverge", i.e. the number of additional iterations after convergence should be a number!');
                else
                    if(XtraNIterConverge<0)
                        error('ERROR: Extra Input "ExtraNIterConverge", i.e. the number of additional iterations after convergence should be zero-positive!');
                    else
                        if(rem(XtraNIterConverge,1)~=0)
                            disp(['WARNING: "ExtraNIterConverge" is not an integer, will replace it with ',num2str(round(XtraNIterConverge)),'.']);
                            XtraNIterConverge = round(XtraNIterConverge);
                        end
                    end
                end
            case 'Verbose'
                Verbose = CurrXtra{2};
                if(length(Verbose)~=1)
                    error('ERROR: Extra Input "Verbose", must be a number or logical of length 1!');
                else
                    if((Verbose~=0)&&(Verbose~=1))
                        Verbose = Verbose/Verbose;
                    end
                end
                if(Verbose)
                    disp(' ');
                    disp('Will output diagnostic messages...');
                    disp(' ');
                end
            otherwise
                error(['ERROR: Unknown Extra Input switch "',CurrXtra{1},'"!']);
        end
    end
end
end            

%% local maxima stats and average stats of cluster
function LocMaxStatsVals_n_ClusterAverage = GetLocMax_n_ClusterAverage_StatsVals(StatsVals,ClusterNr_LocMax)
%LocMaxStatsVals_n_ClusterAverage (NCluster-x-2) first column is local
%maximum statistics value for each cluster and second column is mean of the
%statistics values of all voxels in the cluster.

%% init
Clusters = unique(ClusterNr_LocMax(:));
LocMaxStatsVals_n_ClusterAverage = zeros(length(Clusters),2);

%% pick local max stats val of cluster as maximum (as before) and generate average stats val as mean
for IndCluster = 1:length(Clusters)
    CurrStatsVals = StatsVals(ClusterNr_LocMax==Clusters(IndCluster));
    LocMaxStatsVals_n_ClusterAverage(IndCluster,1) = max( CurrStatsVals(:));
    LocMaxStatsVals_n_ClusterAverage(IndCluster,2) = mean(CurrStatsVals(:));
end

end



