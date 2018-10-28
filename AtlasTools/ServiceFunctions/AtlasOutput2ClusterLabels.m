function [CompiledLabelsPerCluster,UniqueLabelsPerClusterPerAtlas,OccurrenceUniqueLabelsPerClusterPerAtlas,AdditionalStatsPerClusterPerAtlas] = AtlasOutput2ClusterLabels(AtlasOutput,varargin)
% This function allows the user to make Labels (cell-vector) for ROIs/Clusters
% associated with ALL the coordinates in AtlasOutput that belong to each Cluster number.
% i.e. "CompiledLabelsPerCluster"
%
% Either the AtlasOutput Cell-Matrix has to include the Cluster numbers or
% the Cluster numbers have to be given separately.
%
% In any case, the user has to specify which rows of the AtlasOutput Cell-Matrix
% should be skipped, because it just contains the headings and not the data, 
% AND
% if all atlas outputs are in the 2nd to last column (or 2nd to "Nth" column).
%
%Other Outputs:
%       UniqueLabelsPerClusterPerAtlas             <--   Labels per Cluster & Atlas (without XX% such that there are only the region names).
%       OccurrenceUniqueLabelsPerClusterPerAtlas   <--   How often that Label, i.e. region name OCCURRED per Cluster & Atlas (counting all multiple occurrences with different XX% as well).
%       AdditionalStatsPerClusterPerAtlas          <--   Quartiles of the XX% (if available), i.e. the 1.Quartile, the Median & 3.Quartile or the numbers "XX%" per Label, i.e. Region.
%
%
%Usage:
%       [CompiledLabelsPerCluster,UniqueLabelsPerClusterPerAtlas,OccurrenceUniqueLabelsPerClusterPerAtlas,AdditionalStatsPerClusterPerAtlas] = AtlasOutput2ROILabels(AtlasOutput,varargin);
%       [CompiledLabelsPerCluster,UniqueLabelsPerClusterPerAtlas,OccurrenceUniqueLabelsPerClusterPerAtlas,AdditionalStatsPerClusterPerAtlas] = AtlasOutput2ROILabels(AtlasOutput); %Cluster numbers are also in the AtlasOutput Cell-Matrix
%       [CompiledLabelsPerCluster,UniqueLabelsPerClusterPerAtlas,OccurrenceUniqueLabelsPerClusterPerAtlas,AdditionalStatsPerClusterPerAtlas] = AtlasOutput2ROILabels(AtlasOutput,{'ClusterNumbers',ClusterNums}); %Cluster numbers are given by the column-vector ClusterNums(NVoxelx1) in a cell with the first entry being the command string indicating that these are the cluster numbers.
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(28.January.2015): initial implementation based on test script.

%% check inputs
if(nargin==2)
    OptInputs = varargin{1};
    if(iscell(OptInputs))
        switch(OptInputs{1})
            case {'ClusterNumbers','ClusterNums','clusternumbers','clusternums','ClNums','clnums','ClNumbers','clnumbers'} %some variability allowed
                ClusterNums = OptInputs{2};
            otherwise
                error(['Unknown option "',OptInputs{1},'".']);
        end
    else
        error('optional inputs have to be a cell of length 2 with a command string as first entry and the data or instruction as the second.');
    end
    [MainData,AtlasNames,Coords_mm] = split_AtlasOutputs(AtlasOutput,0);
else
    [MainData,AtlasNames,Coords_mm,ClusterNums] = split_AtlasOutputs(AtlasOutput,1);
end

%% separate by Cluster Number and compile the list
AllClusters = unique(ClusterNums);
NClusters   = length(AllClusterInds);
NAtlases    = length(AtlasNames);
RawLabelsPerClusterPerAtlas             = cell(NClusters,NAtlases); %raw labels
AllLabelsPerClusterPerAtlas             = cell(NClusters,NAtlases); %all labels after separation i.e. cellstr in cell per cluster and atlas
UniqueLabelsPerClusterPerAtlas          = cell(NClusters,NAtlases); %Final labels that are unique
OccurrenceUniqueLabelsPerClusterPerAtlas= cell(NClusters,NAtlases); %How often Final labels that are unique OCCURR.
AdditionalStatsPerClusterPerAtlas       = cell(NClusters,NAtlases); %Additional Statistics for Final labels that are unique, i.e. if there are percentage numbers then we get them all and make a statistic over those.
CompiledLabelsPerCluster                = cell(NClusters,1);        %Collection of the unique labels per cluster
for IndCluster = 1:NClusters
    Tmp = []; %for collecting labels from all atlases
    for IndAtlas = 1:NAtlases
        RawLabelsPerClusterPerAtlas{IndCluster,IndAtlas} = MainData(ClusterNums==AllClusters(IndCluster),IndAtlas);
        AllLabelsPerClusterPerAtlas{IndCluster,IndAtlas} = split_RawLabels(RawLabelsPerClusterPerAtlas{IndCluster,IndAtlas},AtlasNames{IndAtlas}); % %some function using the raw and atlasNames with all those tricks of regexp and so on...
        %% Do Statisics for the list
        [UniqueLabelsPerClusterPerAtlas{IndCluster,IndAtlas},OccurrenceUniqueLabelsPerClusterPerAtlas{IndCluster,IndAtlas},AdditionalStatsPerClusterPerAtlas{IndCluster,IndAtlas}] = stats_Labels(AllLabelsPerClusterPerAtlas{IndCluster,IndAtlas},AtlasNames{IndAtlas});
        %% compile all unique labels from all atlases per cluster
        Tmp = [Tmp; UniqueLabelsPerClusterPerAtlas{IndCluster,IndAtlas}];
    end
    %% assign the compilation
    CompiledLabelsPerCluster{IndCluster} = Tmp; clear Tmp
end

%% Done
disp(' ');
disp('Done.');

end