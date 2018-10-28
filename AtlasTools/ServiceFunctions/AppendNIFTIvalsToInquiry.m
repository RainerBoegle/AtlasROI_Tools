function AtlasQueryOutput = AppendNIFTIvalsToInquiry(AtlasQueryResults,varargin)
% This function can be used to append the Atlas Inquiry Results with values
% from selected NIFTI-images.
% This can help with the comparison of difference statistics.
%
%Usage:
%      AtlasQueryOutput = AppendNIFTIvalsToInquiry(AtlasQueryResults,varargin);
%      AtlasQueryOutput = AppendNIFTIvalsToInquiry(AtlasQueryResults); Autoselect NIFTIs using spm_select
%      AtlasQueryOutput = AppendNIFTIvalsToInquiry(AtlasQueryResults,NIFTIpaths); Do Automatic appention using NIFTI-files specified in "NIFTIpaths" 
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(08.December.2014): initial implementation based on test script.

%% get NIFTIs for lookup
if(nargin>1)
    NIFTIpaths = varargin{1};
    if(~iscell(NIFTIpaths))
        NIFTIpaths = cellstr(NIFTIpaths);
    end
    [tmp1,fName,ext] = filesep(NIFTIpaths{1});
    if(strcmp(ext,'.mat') || strcmp(fName,'SPM')) %assume it is a SPM.mat-file
        [NIFTIpaths,ContrastNames] = SelectNIFTIsFromSPMmat(NIFTIpaths{1});
    end
    clear tmp1 fName ext
else
    NIFTIpaths = spm_select(Inf,'image','Select NIFTIs containing statistics results that shall be added to the Atlas Inquiry...');
    if(isempty(NIFTIpaths))
        if(strcmp('Yes',questdlg('You did not select any NIFTIs, do you want to select a SPM.mat-file instead to base the selection on this?','Select SPM.mat instead?','Yes','No','Yes')))
            SPMmatPath = spm_select(1,'SPM.mat','Select SPM.mat to select images via contrasts...');
            [NIFTIpaths,ContrastNames] = SelectNIFTIsFromSPMmat(SPMmatPath);
        else
            AtlasQueryOutput = AtlasQueryResults; %nothing added.
            return;
        end
    else
        NIFTIpaths = cellstr(NIFTIpaths);
    end
end
for IndNIFTI = 1:length(NIFTIpaths)
    Vols(IndNIFTI) = spm_vol(NIFTIpaths{IndNIFTI});
end

%% get coordinates that shall be looked up.
Coords = zeros(size(AtlasQueryResults,1)-1,3);
for IndVoxel = 1:(size(AtlasQueryResults,1)-1)
    Coords(IndVoxel,:) = eval(['[',AtlasQueryResults{1+IndVoxel,1},']']);
end

%% transform to voxel-indices & get value from voxel, then write to AtlasQueryOutput
WriteAsString = 0; %write values as string?
if(exist('ContrastNames','var'))
    ChoiceColumnHeading = questdlg('Use ContrastNames instead of NIFTI-paths as column headings in the appended columns OR use both?','Column headings?','ContrastNames','NIFTI-paths','Both','Both');
else
    ChoiceColumnHeading = 'NIFTI-paths';
end        

AtlasQueryOutput = AtlasQueryResults;
h_wait = waitbar(0,'Appending Atlas Inquiry from NIFTIs...');
for IndNIFTI = 1:length(NIFTIpaths)
    switch(ChoiceColumnHeading)
        case 'NIFTI-paths'
            AtlasQueryOutput{1,size(AtlasQueryResults,2)+IndNIFTI} = NIFTIpaths{IndNIFTI};
        case 'Both'
            AtlasQueryOutput{1,size(AtlasQueryResults,2)+IndNIFTI} = [ContrastNames{IndNIFTI},' (',NIFTIpaths{IndNIFTI},')'];
        case 'ContrastNames'
            AtlasQueryOutput{1,size(AtlasQueryResults,2)+IndNIFTI} = ContrastNames{IndNIFTI};
        otherwise
            AtlasQueryOutput{1,size(AtlasQueryResults,2)+IndNIFTI} = NIFTIpaths{IndNIFTI};
    end
    VoxelInds = GetVoxelInds(Vols(IndNIFTI),Coords);
    NII_tmp = nifti(NIFTIpaths{IndNIFTI});
    for VoxelInd = 1:size(VoxelInds,1)
        if(WriteAsString)
            AtlasQueryOutput{1+VoxelInd,size(AtlasQueryResults,2)+IndNIFTI} = num2str(NII_tmp.dat(VoxelInds(VoxelInd,1),VoxelInds(VoxelInd,2),VoxelInds(VoxelInd,3)));
        else
            AtlasQueryOutput{1+VoxelInd,size(AtlasQueryResults,2)+IndNIFTI} = NII_tmp.dat(VoxelInds(VoxelInd,1),VoxelInds(VoxelInd,2),VoxelInds(VoxelInd,3));
        end
        waitbar(((IndNIFTI-1)*size(VoxelInds,1)+VoxelInd)/(length(NIFTIpaths)*size(VoxelInds,1)),h_wait,['Appending Atlas Inquiry from NIFTIs...(',num2str(((IndNIFTI-1)*size(VoxelInds,1)+VoxelInd)/(length(NIFTIpaths)*size(VoxelInds,1))*100,3),'%; ',num2str(IndNIFTI-1),'of',num2str(length(NIFTIpaths)),'NIFTIs complete)']); %update waitbar
    end
    clear NII_tmp
end
close(h_wait);


end

%% subfunction for voxel lookup
function vox = GetVoxelInds(Vol,Coords)
% get transformation matrices
v2m=spm_get_space(Vol.fname);
m2v=inv(v2m);

% check coords
if(iscell(Coords))
    Coords_tmp = Coords;
    Coords = zeros(length(Coords),3);
    for i = 1:length(Coords_tmp)
        Coords(i,:) = Coords_tmp{i};
    end
else
    if(size(Coords,2)~=3 && size(Coords,1)==3)
        Coords = Coords';
    end
end

% create voxel indices
vox = zeros(size(Coords));
for i=1:size(Coords,1)
    vox(i,1:3)=Coords(i,:)*m2v(1:3,1:3) + m2v(1:3,4)';
end    
vox = round(vox); %for use in array

end

%% subfunction for fileselection from SPM.mat
function [NIFTIpaths,ContrastNames] = SelectNIFTIsFromSPMmat(SPMmatPath)
%look up the contrasts and output the SPM-image-file-paths for the selected
%contrasts.

%load SPM.mat
load(SPMmatPath);
SPMbasedir = fileparts(SPMmatPath);

% get the names of contrasts and SPM-image files that are associated with them.
ContrastNames = cell(length(SPM.xCon),1);
SPMimageNames = cell(length(SPM.xCon),1);
for IndCon = 1:length(ContrastNames)
    ContrastNames{IndCon} = [SPM.xCon(IndCon).STAT,': "',SPM.xCon(IndCon).name,'"'];
    SPMimageNames{IndCon} = [SPMbasedir,filesep,SPM.xCon(IndCon).Vspm.fname];
end

% select conditions of interest
[SelConds,ok] = listdlg('ListString',ContrastNames,'ListSize',[500 300],'Name','Contrast Selection','PromptString','Select Contrast for NIFTI-selection: ','OKString','UseTheseContrasts','CancelString','Quit');
if(~ok)
    NIFTIpaths = [];
    ContrastNames = [];
    return;
else
    NIFTIpaths = SPMimageNames(SelConds);
    ContrastNames = ContrastNames(SelConds);
end

end