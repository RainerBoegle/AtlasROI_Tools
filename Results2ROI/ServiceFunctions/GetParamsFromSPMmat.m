function [MapExtractStruct] = GetParamsFromSPMmat(SPMmatPath,varargin)
% This function can extract the statistic values & coordinates from a contrast statistics evaluation in SPM-results.
% Futhermore, a mask can be applied to include or exclude parts of the map(volume) from extraction 
% and thresholds can be applied.
%
%OUTPUT:
%       MapExtractStruct.
%                       .ThresMap     <--   Map: Positive & Negative threshold (or just >0)
%                       .ThresMask    <--   Mask(if used, otherwise empty): Positive & Negative threshold (if used, otherwise empty)
%
%                       .Voxels(1).   <--   Positive threshold data
%                       .Voxels(2).   <--   Negative threshold data (if used, otherwise empty)
%                                 .Coords_mm   <<   The mm-coordinates of all significant voxels, i.e. above threshold.
%                                 .StatsVals   <<   The statistics values of all significant voxels, i.e. above threshold.
%                                 .Coords_vox  <<   The mm-coordinates of all significant voxels, i.e. above threshold.
%
%                       .V_map.       <--   SPM-vol struct of the input map
%                       .V_mask.      <--   SPM-vol struct of the mask (if used, otherwise empty)
%
%
%
%Usage:
%       [MapExtractStruct] = GetParamsFromSPMmat(SPMmatPath);
%       [MapExtractStruct] = GetParamsFromSPMmat(); %select manually
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment V1.0: (30.12.2014): initial implementation

%% inputs?
if(nargin==2)
    UseResorting = varargin{1};
else
    UseResorting = 0; %do not resort
end

%% get path to SPM.mat
try
    if(iscellstr(SPMmatPath))
        if(~exist(SPMmatPath{1},'file'))
            SPMmatPath = spm_select(1,'SPM.mat','Select SPM.mat for extraction of significant values from Statistics-Map...');
        else
            SPMmatPath_tmp = SPMmatPath; clear SPMmatPath 
            SPMmatPath = SPMmatPath_tmp{1}; clear SPMmatPath_tmp
        end
    else
        if(~exist(SPMmatPath,'file'))
            SPMmatPath = spm_select(1,'SPM.mat','Select SPM.mat for extraction of significant values from Statistics-Map...');
        end
    end
catch CATCH_SPMmatPath
    SPMmatPath = spm_select(1,'SPM.mat','Select SPM.mat for extraction of significant values from Statistics-Map...');
end
SPMmatPath = fileparts(SPMmatPath);

%% get statistics via contrast from SPM.mat 
xSPM.swd = SPMmatPath;
[SPM,xSPM] = spm_getSPM(xSPM);

%% assign values
MapExtractStruct.Voxels(1).Coords_mm = xSPM.XYZmm';
MapExtractStruct.Voxels(1).StatsVals = xSPM.Z';
MapExtractStruct.Voxels(1).Coords_vox= xSPM.XYZ';

MapExtractStruct.Voxels(2).Coords_mm = [];
MapExtractStruct.Voxels(2).StatsVals = [];
MapExtractStruct.Voxels(2).Coords_vox= [];

%% apply resorting
if(UseResorting)
    FinalResortingIndices = ZYXresort(MapExtractStruct.Voxels(1).Coords_mm);
    MapExtractStruct.Voxels(1).Coords_mm = MapExtractStruct.Voxels(1).Coords_mm( FinalResortingIndices,:);
    MapExtractStruct.Voxels(1).StatsVals = MapExtractStruct.Voxels(1).StatsVals( FinalResortingIndices);
    MapExtractStruct.Voxels(1).Coords_vox= MapExtractStruct.Voxels(1).Coords_vox(FinalResortingIndices,:);
end

%% write remaining info to ouput
%volume info
MapExtractStruct.V_map  = xSPM.Vspm;
MapExtractStruct.V_mask = [];
%thresholds
MapExtractStruct.ThresMap{1}  = [xSPM.thresDesc,' (u=',num2str(xSPM.u),';k=',num2str(xSPM.k),')'];
MapExtractStruct.ThresMap{2}  = '[]';
MapExtractStruct.ThresMask = [];

%% save thresholded SPM to NIFTI?
if(strcmp('Yes',questdlg('Should the statistics results be saved as a thresholded map in a NIFTI-file?','Output thresholded-map?','Yes','No','Yes')))
    %% make new volume information
    V_ThresMapOut = MapExtractStruct.V_map;
    
    [FileName,PathName,FilterIndex] = uiputfile('*.nii','Save THRESHOLDED Stats-Map?','THRES_SPM.nii');
    if(FilterIndex~=0)
        V_ThresMapOut.fname = [PathName,filesep,FileName];
        
        %% prepare data
        Map_dat = zeros(V_ThresMapOut.dim);
        for IndVox = 1:length(MapExtractStruct.Voxels(1).Coords_vox,1)
            Map_dat(MapExtractStruct.Voxels(1).Coords_vox(IndVox,1),MapExtractStruct.Voxels(1).Coords_vox(IndVox,2),MapExtractStruct.Voxels(1).Coords_vox(IndVox,3)) = MapExtractStruct.Voxels(1).StatsVals(IndVox);
        end
        
        %% write NIFTI
        if(V_ThresMapOut.dt(1)<16)
            V_ThresMapOut.dt(1) = 16; %not necessary but save
        end
        V_ThresMapOut = spm_write_vol(V_ThresMapOut,Map_dat);
        
        %% Done.
        [OutDir,OutfName,Outext] = fileparts(V_ThresMapOut.fname);
        disp(' ');
        disp(['Thresholded Statistics-Map has been written to NIFTI-file "',OutfName,Outext,'".']);
        disp(['In the directory "',OutDir,'".']);
        
    else
        disp('Thresholded Statistics-Map was NOT saved to NIFTI.');
    end
else
    disp('Will not save Thresholded Statistics-Map to NIFTI.');
end

end