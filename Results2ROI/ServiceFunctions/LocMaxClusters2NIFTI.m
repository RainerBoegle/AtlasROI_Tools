function [OutputPath,Vo] = LocMaxClusters2NIFTI(ClusterNr_vox,Coords_vox,TemplateVol,OutputPath)
% This function will write the clusters produced by FindAllLocMax to a
% NIFTI that can be displayed with DisplayClusters.m, see help there.
%
%Usage:
%      [OutputPath,Vo] = LocMaxClusters2NIFTI(ClusterNr_vox,Coords_vox,TemplateVol,OutputPath);
%      [OutputPath,Vo] = LocMaxClusters2NIFTI(ClusterNr_vox,Coords_vox); %manual selection of Template Volume and OutputPath(+FileName) 
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment V1.0: (27.12.2014): initial implementation (changed version from test script)

%% check inputs
if((length(ClusterNr_vox)~=size(Coords_vox,1))&&(size(ClusterNr_vox,1)~=size(Coords_vox,1)))
    error('ERROR: number of cluster indices and number of voxel subscript-coordinates do not match!');
end
if(size(Coords_vox,2)~=3)
    error('ERROR: "Coords_vox", i.e. the voxel subscript-coordinates, does not have the right shape. Needs to be (NVoxel-x-3)!');
end
if(size(ClusterNr_vox,2)~=1)
    error('ERROR: "ClusterNr_vox" has to be a column vector!');
end

try %TemplateVol
    if(isstruct(TemplateVol))
        if(~(isfield(TemplateVol,'fname')&&isfield(TemplateVol,'dt')&&isfield(TemplateVol,'dim')&&isfield(TemplateVol,'mat'))) %check most important fields of volume
            error('ERROR: "TemplateVol" is not a valid SPM-volume struct.');
        end
    else
        if(exist(TemplateVol,'file'))
            TemplatePath= TemplateVol;
            TemplateVol = spm_vol(TemplatePath); clear TemplatePath
        else
            error(['Could not open file: "',TemplateVol,'".']);
        end
    end
catch CATCH_TemplateVol
    %user selects manually
    TemplateVol = spm_vol(spm_select(1,'image','Select a template volume...'));
end
for IndDim = 1:3
    if(TemplateVol.dim(IndDim)<max(Coords_vox(:,IndDim)))
        error(['Template-Volume seems not to be appropriate! Dim(',num2str(IndDim),')<max(Coords_vox(:,',num2str(IndDim),'))']);
    end
end

try %OutputPath
    [OutputPath_Dir,OutputPath_FileName,ext] = fileparts(OutputPath);
    if(isempty(OutputPath_Dir))
        OutputPath_Dir = pwd;
    else
        if(~exist(OutputPath_Dir,'dir'))
            mkdir(OutputPath_Dir);
        end
    end
    if(isempty(OutputPath_FileName))
        FilterIndex = 0;
        while(~FilterIndex)
            [OutputPath_FileName,OutputPath_Dir,FilterIndex] = uiputfile('.nii','Save Cluster-NIFTI...','Clusters.nii');
        end
    end
    if(isempty(ext))
        ext = '.nii';
    end
    switch ext
        case {'.img'}
            ext = '.img';
        case {'.nii'}
            ext = '.nii';
        otherwise
            error(['"' ext '" is not a recognised extension.']);
    end;
    OutputPath = [OutputPath_Dir,filesep,OutputPath_FileName,ext]; 
    clear OutputPath_FileName OutputPath_Dir FilterIndex
catch CATCH_OutputPath
    FilterIndex = 0;
    while(~FilterIndex)
        [OutputPath_FileName,OutputPath_Dir,FilterIndex] = uiputfile('.nii','Save Cluster-NIFTI...','Clusters.nii');
    end
    [Dir,fName,ext] = fileparts(OutputPath_FileName); clear Dir fName
    if(isempty(ext))
        ext = '.nii';
    end
    switch ext
        case {'.img'}
            ext = '.img';
        case {'.nii'}
            ext = '.nii';
        otherwise
            error(['"' ext '" is not a recognised extension.']);
    end;
    OutputPath = [OutputPath_Dir,filesep,OutputPath_FileName,ext]; 
    clear Dir fName ext OutputPath_FileName OutputPath_Dir FilterIndex
    disp(OutputPath);
end
   
%% assign cluster indices to voxels
Y = zeros(TemplateVol.dim);
for IndVox = 1:size(Coords_vox,1)
    Y(Coords_vox(IndVox,1),Coords_vox(IndVox,2),Coords_vox(IndVox,3)) = ClusterNr_vox(IndVox);
end

%% write NIFTI
Vo = TemplateVol;
if(Vo.dt(1)<16)
    Vo.dt(1) = 16; %not necessary but save
end
Vo.fname = OutputPath;
Vo = spm_write_vol(Vo,Y);

%% Done.
[OutDir,OutfName,Outext] = fileparts(Vo.fname);
disp(' ');
disp(['Clusters have been written to NIFTI-file "',OutfName,Outext,'".']);
disp(['In the directory "',OutDir,'".']);

end