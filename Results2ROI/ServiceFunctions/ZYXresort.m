function [FinalResortingIndices] = ZYXresort(Coords_mm)
% resort by z-direction, such that voxels in a z-slice are together
% AND then resort by y-direction PER z-slice, i.e. unique(Coords_mm(:,3)).
% AND then resort by x-direction PER y-slice resorted PER z-slice
%
%Usage: 
%       [FinalResortingIndices] = ZYXresort(Coords_mm); %Coords_mm is a NVoxel-x-3 matrix (NB, Column 1:3==xyz) of coordinates
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment V1.0: (14.12.2014): initial implementation (changed version from DisplayMasksNIFTIsOnSlices.m)

%% preparation (currently only for debug, maybe in future extension make sorting controlable
apply_ysort = 1;
if(apply_ysort)
    apply_xsort = 1;
else
    apply_xsort = 0; %xsort only if ysort has been done. (Future extension might change this.)
end

%% sort
[SortedData,SortingIndices_z] = sort(Coords_mm(:,3)); clear SortedData
Coords_mm = Coords_mm(SortingIndices_z,:);
if(apply_ysort)
    Z_slices  = unique(Coords_mm(:,3));
    IndicesZslice = cell(length(Z_slices),1); %for collecting all indices for final resorting
    FinalResortingIndices = []; %init empty
    for IndZslice = 1:length(Z_slices)
        %get all indices that belong to the same Z-Slice
        IndicesZslice{IndZslice} = find(Coords_mm(:,3)==Z_slices(IndZslice)); %the voxel indices that are of one z-slice
        %Y-Values in this Z-Slice
        YVals = Coords_mm(IndicesZslice{IndZslice},2); %y-direction values for the current z-slice (UNSORTED, yet)
        %Sort Y-Values in this Z-Slice
        [YSortedData,SortingIndices_YperZslice] = sort(YVals); clear YVals YSortedData %resorting y-values
        %rearrange the indices for Z-Slice such that Y-Values in this Z-Slice are sorted.
        %(When the Z-Slices are put together again one after the other, and given that they are sorted, then the sorting will be combined.)
        IndicesZslice{IndZslice} = IndicesZslice{IndZslice}(SortingIndices_YperZslice); %the order of voxel indices such that y-values are sorted for this z-slice
        if(apply_xsort)
            %Get the resorted Y-Values (just to make sure)
            YVals = Coords_mm(IndicesZslice{IndZslice},2); %y-direction values for the current z-slice RESORTED
            %Get each Y-Slice Value in the current z-slice
            CurrYslices = unique(YVals); %all the y-values in the current z-slice
            %For each Y-Slice in the current Z-Slice resort the X-Values and collect the sorting indices to apply later to z-sorting indices ordering.
            IndicesZCurrYslice = cell(length(CurrYslices),1); %for collecting current resorting of all y AFTER sorting of x.
            SortingIndices_YperZslice = []; %init empty %combine Indices RESORTED(according to x-dir) CurrYslices
            for IndYslice = 1:length(CurrYslices)
                IndicesZCurrYslice{IndYslice} = find(YVals==CurrYslices(IndYslice));
                XValsCurr = Coords_mm(IndicesZslice{IndZslice}(IndicesZCurrYslice{IndYslice}),1); %current x-values of interest
                [XSortedData,SortingIndices_XcurrPerYperZslice] = sort(XValsCurr); clear XValsCurr XSortedData %resorting x-values of a certain y-slice PER Z-slice
                IndicesZCurrYslice{IndYslice} = IndicesZCurrYslice{IndYslice}(SortingIndices_XcurrPerYperZslice);
                SortingIndices_YperZslice = [SortingIndices_YperZslice; IndicesZCurrYslice{IndYslice}];
            end
            %change z-slice indices to have the final resorting done and collect
            IndicesZslice{IndZslice} = IndicesZslice{IndZslice}(SortingIndices_YperZslice); %the order of voxel indices such that ALSO X-values AND y-values are sorted for this z-slice
        end
        %collect indices for resorting
        FinalResortingIndices = [FinalResortingIndices; IndicesZslice{IndZslice}];
    end
else
    FinalResortingIndices = SortingIndices_z
end


end
