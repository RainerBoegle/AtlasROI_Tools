function [AtlasQueryResults]=InquireAtlases(AvailableAtlasesFSL,VoxCell)
% This function uses "atlasquery" of FSL to look up labels in the atlases
% specified in variable "AvailableAtlasesFSL" which can be created using
% getAtlases.m using the Voxel-Coordinates in mm stored in the variable "VoxCell". 
% 
% The variables should both be cells-VECTORS!
% "AvailableAtlasesFSL" should contain one entry per atlas, i.e. a string signifying the atlas name. (use getAtlases.m)
% "VoxCell" should contain one entry per voxel which itself should be a vector of size 3.
%
%Usage:
%       AtlasQueryResults = InquireAtlases(AvailableAtlasesFSL,VoxCell);
%       AtlasQueryResults = InquireAtlases(getAtlases('select'),VoxCell);  %select atlases to inquire about voxel locations in VoxCell
%       AtlasQueryResults = InquireAtlases(getAtlases(),VoxCell);  %use all available atlases to inquire about voxel locations in VoxCell
%
%V1.5
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(31.January.2015): change output such that we can add the stats vals as well ofter this output.

%% check that voxel inputs are in the right format.
VoxCellsize = size(VoxCell);
if(~iscell(VoxCell))
    Dim3 = find(VoxCellsize==3);
    if(length(Dim3)>1 || length(VoxCellsize)>2)
        error('Can not cast VoxCell input to cell-vector.');
    else
        VoxCell_tmp = VoxCell;
        if(Dim3==1)
            VoxCell = cell(size(VoxCell_tmp,2),1);
            for IndVoxel = 1:size(VoxCell_tmp,2)
                VoxCell{IndVoxel} = VoxCell_tmp(:,IndVoxel);
            end
        else
            VoxCell = cell(size(VoxCell_tmp,1),1);
            for IndVoxel = 1:size(VoxCell_tmp,1)
                VoxCell{IndVoxel} = VoxCell_tmp(IndVoxel,:);
            end
        end
    end
else
    if(length(VoxCellsize)>2)
        if(length(find(VoxCellsize~=1))~=1 && length(VoxCell)~=1)
            error('size of VoxCell is wrong, needs to be a cell-vector containing 3-element numerical vectore with mm-Coordinates');
        end
    end
end
if(length(VoxCell{1})~=3)
    error('size of VoxCell is wrong, needs to be a cell-vector containing 3-element numerical vectore with mm-Coordinates');
end

%% get atlas results
AtlasQueryResults = cell(1+length(VoxCell),2+length(AvailableAtlasesFSL)); %this cell collects the atlas name lookups per voxel and atlas. The first row is reserved for Coordinate[mm]; Atlas name1; ... Atlas nameN; & the lines following are the values.
for IndAtlas = 1:length(AvailableAtlasesFSL)
    AtlasQueryResults{1,1} = 'Coord[XYZmm]';
    AtlasQueryResults{1,2} = 'StatsVals';
    AtlasQueryResults{1,2+IndAtlas} = AvailableAtlasesFSL{IndAtlas};
end

h_wait = waitbar(0,'Performing Atlas Inquiry...');
for IndAtlas = 1:length(AvailableAtlasesFSL)
    for IndVoxel = 1:length(VoxCell)
        %e.g.      =   atlasquery -a        "Juelich Histological Atlas" -c               Xmm                ,              Ymm                ,              Zmm                
        CommandFSL = ['atlasquery -a "',AvailableAtlasesFSL{IndAtlas},'" -c ',num2str(VoxCell{IndVoxel}(1)),',',num2str(VoxCell{IndVoxel}(2)),',',num2str(VoxCell{IndVoxel}(3))];
        %run atlasquery
        [status, result] = system(CommandFSL);
        if(status)
            disp(['Potential Error for Voxel-Coordinate [',num2str(VoxCell{IndVoxel}(1)),',',num2str(VoxCell{IndVoxel}(2)),',',num2str(VoxCell{IndVoxel}(3)),']. Please check.']);
        end
        %check result string
        if(~isempty(result))
            startIndex = regexp(result,'<br>');
            result = result(startIndex+length('<br>'):end);
        end
        AtlasQueryResults{1+IndVoxel,1}          = [num2str(VoxCell{IndVoxel}(1)),',',num2str(VoxCell{IndVoxel}(2)),',',num2str(VoxCell{IndVoxel}(3))];
        AtlasQueryResults{1+IndVoxel,2+IndAtlas} = result;
        try
            waitbar(((IndAtlas-1)*length(VoxCell)+IndVoxel)/(length(AvailableAtlasesFSL)*length(VoxCell)),h_wait,['Performing Atlas Inquiry...(',num2str(((IndAtlas-1)*length(VoxCell)+IndVoxel)/(length(AvailableAtlasesFSL)*length(VoxCell))*100,3),'%; ',num2str(IndAtlas-1),'of',num2str(length(AvailableAtlasesFSL)),'Atlases complete)']); %update waitbar
        catch
            h_wait = waitbar(((IndAtlas-1)*length(VoxCell)+IndVoxel)/(length(AvailableAtlasesFSL)*length(VoxCell)),['Performing Atlas Inquiry...(',num2str(((IndAtlas-1)*length(VoxCell)+IndVoxel)/(length(AvailableAtlasesFSL)*length(VoxCell))*100,3),'%; ',num2str(IndAtlas-1),'of',num2str(length(AvailableAtlasesFSL)),'Atlases complete)']); %update waitbar
        end
    end
end
try
    close(h_wait); %done --> close waitbar.
end

end%of InquireAtlases