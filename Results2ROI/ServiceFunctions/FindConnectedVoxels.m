function [ConnectMat] = FindConnectedVoxels(VoxCoords,varargin)
% This function will assign make a matrix(nxn) of connectedness of all voxels in the list "VoxCoords"(nx3)[in voxel indices],
% given the dimensions of the volume "Dim" (==[Xsize;Ysize;Zsize]).
%
%Outputs:
%         ConnectMat      <--   nVoxel-x-nVoxel matrix of connectedness of voxels.
%                               NB: If a voxel, e.g. a certain column, is connected to another voxel, 
%                                   (i.e. a row index), then this value will be 1 "one" otherwise 0 "zero".
%
%Usage:
%      [ConnectMat] = FindConnectedVoxels(VoxCoords);
%      [ConnectMat] = FindConnectedVoxels(xSPM.XYZ'); %use SPM-statistics results and search connectedness by nearest neighbors and never stop connecting voxels.
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(14.December.2014): initial implementation based on test script.


%% maximum number of iterations?
if(nargin>1)
    Verbose = varargin{1}; %for debug
else
    Verbose = 0; %no messages
end

%% make the starting matrix --> eye
ConnectMat = eye(size(VoxCoords,1),size(VoxCoords,1));

%% for each voxel look at the ones that are already connected and look if they have neighbors.
%% if we do NMaxIter iterations without adding new neighbors we stop for this voxel.
IndicesToDo = [1:size(VoxCoords,1)]'; %init
while(~isempty(IndicesToDo))
    if(Verbose)
        disp(['Treating ',num2str(IndicesToDo(1)),'.Voxel of ',num2str(size(VoxCoords,1)),' Voxels.']);
    end
    [NonZeroNeighborIndices,IndicesToDo] = getNonZeroNeighbors(VoxCoords,IndicesToDo);
    ConnectMat(NonZeroNeighborIndices,NonZeroNeighborIndices) = 1; %update connectivity matrix %this is a symmetrical problem %AND an equivalence relationship exists
    if(Verbose)
        disp([num2str(length(NonZeroNeighborIndices)),' connections found...']);
        if(~isempty(IndicesToDo))
            disp('Going to next voxel that is still unconnected.');
        else
            disp('All done.');
        end
        disp(' ');
    end
end

disp('DONE.');
end

%% subfunctions
%% getNonZeroNeighbors
function [NonZeroNeighborIndices,IndicesToDo] = getNonZeroNeighbors(VoxCoords,IndicesToDo)
%% Pick a start point and check which of the VoxCoords lie in NHood distance, 
%% then use these as next starting point until no new starting points can be added and all have been explored.
NHood = 1; %next neighbors (FUTURE extension could be further neighborhoods maybe including connections...???)
NonZeroNeighborIndices = IndicesToDo(1); %init
NextStartLocation = VoxCoords(IndicesToDo(1),:); %INIT Starting location
IndicesCoveredAlready = IndicesToDo(1); %init
while(~isempty(NextStartLocation))
    CurrStartLocation = NextStartLocation(1,:); %take the first one of those still around to start (or the first in case of first loop)
    NextStartLocation(1,:) = []; %remove such that we can continue with the next; the next time around in the loop OR empty this if nothing is left.
    Diff = repmat(CurrStartLocation,length(IndicesToDo),1)-VoxCoords(IndicesToDo,:); %Difference in steps from current start location
    NewIndices = IndicesToDo(sqrt(Diff(:,1).^2+Diff(:,2).^2+Diff(:,3).^2)<=sqrt(3.*NHood));
    for Ind = 1:length(IndicesCoveredAlready)
        NewIndices = NewIndices(NewIndices~=IndicesCoveredAlready(Ind));
    end
    IndicesCoveredAlready  = [IndicesCoveredAlready; NewIndices]; %these have been covered
    NonZeroNeighborIndices = unique([NonZeroNeighborIndices; NewIndices]); %add those that are maximally NHood away (in our case it is equal if NHood can be different than 1 it needs to be "<=")
    NextStartLocation      = [NextStartLocation; VoxCoords(NewIndices,:)]; %add the ones that are in NHood distance
end

%% remove those indices that have been covered in this run
for Ind = 1:length(NonZeroNeighborIndices) %remove those that have been found from checklist
    if(~isempty(IndicesToDo))
        IndicesToDo = IndicesToDo(IndicesToDo~=NonZeroNeighborIndices(Ind));
    else
        return;
    end
end

end

