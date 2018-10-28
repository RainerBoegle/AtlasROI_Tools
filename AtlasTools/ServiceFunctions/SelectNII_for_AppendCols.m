function NII_Paths = SelectNII_for_AppendCols()
% This function helps with the selection of NIFTI-files for the function AppendNIFTIvalsToInquiry 
% used in the Atlas Inquiry.
%
% NIFTI images and SPM.mat-files can be selected. 
% If SPM.mat-files are selected then the user will be asked to select the contrasts
% that should be followed to their associated nifti-files.  
%
%Usage:
%       NII_Paths = SelectNII_for_AppendCols(); %select NIFTI-files including indirect selection from SPM.mat contrasts
%
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(04.February.2015): initial implementation based on test script.

%% init
NII_Paths = {}; %later we might end after checking that no files were selected, then this should not lead to an error, but empty return.

%% select NIFTI-files directly
SelImgFiles = spm_select(Inf,'image','Select NIFTI-files for creating "append-list"...');
if(~isempty(SelImgFiles))
    SelImgFiles = cellstr(SelImgFiles);
else
    SelImgFiles = [];
end

%% select SPM.mat files
SelSPMFiles = spm_select(Inf,'SPM.mat','Select SPM.mat-files for creating "append-list"...');
if(~isempty(SelSPMFiles))
    SelSPMFiles = cellstr(SelSPMFiles);
else
    SelSPMFiles = [];
end

%% combine
if((~isempty(SelImgFiles))&&(~isempty(SelSPMFiles)))
    SelFiles = cell(length(SelImgFiles)+length(SelSPMFiles),1);
    SelFiles(1:length(SelImgFiles))=SelImgFiles(1:length(SelImgFiles));
    SelFiles(length(SelImgFiles)+[1:length(SelSPMFiles)])=SelSPMFiles(1:length(SelSPMFiles));
elseif(~isempty(SelImgFiles))
    SelFiles = SelImgFiles;
elseif(~isempty(SelSPMFiles))
    SelFiles = SelSPMFiles;
else
    return; %both empty return NII_Paths which was initialized empty.
end

%% check the files %not necessary any more but who cares
throwInds = zeros(length(SelFiles),1);
for Ind = 1:length(SelFiles)
    throwInds(Ind) = CheckInputs(SelFiles{Ind}); %throw out all unrecognized
end
SelFiles(throwInds==0) = []; %delete the unrecognized ones
throwInds(throwInds==0)= []; %delete from list

%% check if any are SPM.mat and ask user to select the relevant contrasts
for Ind = 1:length(SelFiles)
    if(throwInds(Ind)==2)
        SelFiles{Ind} = SelectNIFTIsFromSPMmat(SelFiles{Ind});
    end
end

%% assign SelFiles-contents to NII_Paths, if a entry in SelFiles is still a cell then it is from a SPM.mat contrast selection, therefore expand it in NII_Paths
IndNew    = 0;
SelInd    = 1;
N         = length(SelFiles);
while(SelInd<=N)
    CurrFile = SelFiles{SelInd};
    if(iscell(CurrFile)) %from SelectNIFTIsFromSPMmat --> expand/extract files
        for Ind = 1:length(CurrFile)
            NII_Paths{IndNew+Ind,1} = CurrFile{Ind};
        end
        IndNew = IndNew+length(CurrFile);
    else
        if(ischar(CurrFile))
            IndNew = IndNew+1;
            NII_Paths{IndNew,1} = CurrFile;
        end
    end
    SelInd = SelInd+1;
end

end

%% subfunctions
function Flag = CheckInputs(File) %throw out all unrecognized
% check file if nifti then Flag==1 if SPM.mat then Flag==2
[BaseDir,fname,ext_org] = fileparts(File); 
ext = regexprep(ext_org,',|\d+','');
switch(ext)
    case {'.nii','.img','.hdr','.NII','.IMG','.HDR'}
        Flag = 1;
    case {'.mat','.MAT'}
        if(strcmp(fname,'SPM'))
            try
                load(File);
                if(isfield(SPM,'xCon')&&isfield(SPM.xCon,'Vspm'))
                    Flag = 2;
                else
                    Flag = 0;
                end
            catch
                Flag = 0;
            end
        else
            Flag = 0;
        end
    otherwise
        disp(['Unrecognized file-type "',fname,ext_org,'"!']);
        Flag = 0;
end
end

%% subfunction for fileselection from SPM.mat
function [NIFTIpaths] = SelectNIFTIsFromSPMmat(SPMmatPath)
%look up the contrasts and output the SPM-image-file-paths for the selected contrasts.

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
    return;
else
    NIFTIpaths = SPMimageNames(SelConds);
end

end