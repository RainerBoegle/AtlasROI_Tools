function [AtlasQueryOutput] = AllNonZeroMapVals2Atlas(MapNII_path)
% This function is a very simple version of the atlas lookup from a NIFTI-map.
% Here ALL NON-ZERO VOXELS are used for iquiry of the selected atlases.
%
% This can take very long!
%
%Usage:
%       [AtlasQueryOutput] = AllNonZeroMapVals2Atlas(MapNII_path); %take all non-zero voxels from NIFTI at MapNII_path and inquire atlases.
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(19.January.2015): initial implementation based on test script.

%% get all non-zero voxels 
try
    MapExtractStruct = GetParamsFromMap(MapNII_path); %user data --> all selection is manual...
catch
    MapExtractStruct = GetParamsFromMap(); %user data --> all selection is manual...
end

AtlasQueryOutput = cell(2,1); %init
for IndData = 1:2
    if(~isempty(MapExtractStruct.Voxels(IndData).Coords_mm))
        %% assign to LocMaxStruct such that we can use the standard functions
        LocMaxStruct.LocMaxCoords_mm = MapExtractStruct.Voxels(IndData).Coords_mm; %dimensions are columns and datapoints are rows
        
        %% use LocMaxStruct2Atlas function
        AtlasQueryOutput_tmp = LocMaxStruct2Atlas(LocMaxStruct);
        
        %% append map vals
        NCol = size(AtlasQueryOutput_tmp,2); %initial number of columns
        AtlasQueryOutput_tmp{1,NCol+1} = 'MapVals';
        for Ind = 1:size(MapExtractStruct.Voxels(IndThres).StatsVals,1)
            AtlasQueryOutput_tmp{1+Ind,NCol+1} = MapExtractStruct.Voxels(IndThres).StatsVals(Ind,1); %statistics values
        end
        
        %% output
        AtlasQueryOutput{IndData} = AtlasQueryOutput_tmp;
    end
end

%% done
disp(' ');
disp('Done.');

end