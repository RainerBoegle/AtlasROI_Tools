function [Labels] = AtlasOutput2ROILabels(varargin)
% This function allows the user to make Labels (cell-vector) for ROIs
% associated with the coordinates in AtlasOutput.
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(20.January.2015): initial implementation based on test script.

%% check inputs
if(nargin==0)
    InputPath = spm_select(1,'mat','Select *.mat-file containing AtlasOutput...');
    [Temp,Input_fname] = fileparts(InputPath); clear Temp
    Tmp = load(InputPath);
    %% select data
    if(isfield(Tmp,'AtlasOutput'))
        AtlasOutput = Tmp.AtlasOutput;
        clear Tmp;
        SuggestedName = Input_fname;
    else
        %% user select
        SNames = fieldnames(Tmp);
        [FieldIndex, OK] = listdlg('ListString',SNames,'CancelString','Cancel','Name','Select content...','PromptString','Select content of *.mat-file to be used as AtlasOutput...','SelectionMode','single');
        if(OK)
            AtlasOutput = getfield(Tmp, SNames{FieldIndex});
            SuggestedName = SNames{FieldIndex};
        else
            Labels = [];
            return;
        end
    end
else
    if(isstruct(varargin{1}))
        Tmp = varargin{1};
        %% select data
        if(isfield(Tmp,'AtlasOutput'))
            AtlasOutput = Tmp.AtlasOutput;
            clear Tmp;
            SuggestedName = 'XYZ'; %unknown
        else
            %% user select
            SNames = fieldnames(Tmp);
            [FieldIndex, OK] = listdlg('ListString',SNames,'CancelString','Cancel','Name','Select content...','PromptString','Select content of *.mat-file to be used as AtlasOutput...','SelectionMode','single');
            if(OK)
                AtlasOutput   = getfield(Tmp, SNames{FieldIndex});
                SuggestedName = SNames{FieldIndex};
            else
                Labels = [];
                return;
            end
            clear Tmp
        end
    else
        if(iscell(varargin{1}))
            AtlasOutput = varargin{1}; %assume this is AtlasOutput
            SuggestedName = 'XYZ'; %unknown
        elseif(ischar(varargin{1}))
            Tmp = load(varargin{1}); %assume this is the path to AtlasOutput *.mat-file
            [Temp,SuggestedName] = fileparts(varargin{1}); clear Temp
            %% select data
            if(isfield(Tmp,'AtlasOutput'))
                AtlasOutput = Tmp.AtlasOutput;
                clear Tmp;
            else
                %% user select
                SNames = fieldnames(Tmp);
                [FieldIndex, OK] = listdlg('ListString',SNames,'CancelString','Cancel','Name','Select content...','PromptString','Select content of *.mat-file to be used as AtlasOutput...','SelectionMode','single');
                if(OK)
                    AtlasOutput = getfield(Tmp, SNames{FieldIndex});
                    SuggestedName = [SuggestedName,' ',SNames{FieldIndex}];
                else
                    Labels = [];
                    return;
                end
            end
        else
            error('AtlasOutput needs to be a cell! (Or path to *.mat file containing such a cell.)');
        end
    end
end
%% check what we got
if(~iscell(AtlasOutput))
    error('AtlasOutput needs to be a cell!');
end

%% get just the coordinates and labels without the headers in the first row
MainData = AtlasOutput(2:end,:);

%% go over coordinates and ask user to decide Label from atlas output
Labels = cell(size(MainData,1),1);
SphereSize = 6; %Voxels in each direction
for IndLocMax = 1:size(MainData,1)
    CurrCoord = eval(['[',MainData{IndLocMax,1},']']);
    %% generate a sphere around the coordinate in question & display
    GenerateSphereDisplay(CurrCoord,SphereSize);
    pause(.25); %bug fix
    
    %% let user choose atlas entries & adjust string if necessary
    KeepPickingNames = 1;
    while(KeepPickingNames)
        CurrAtlasEntries = squeeze(MainData(IndLocMax,2:end)');
        [SuggestedEntries, OK] = listdlg('ListString',CurrAtlasEntries,'CancelString','fully MANUAL','Name','Select Label names...','PromptString','Select Label names from AtlasOutput...','ListSize',[400 200]);
        if(OK)
            LabelStr = [num2str(IndLocMax),'.[',MainData{IndLocMax,1},']:'];
            for IndSel = 1:length(SuggestedEntries)
                LabelStr = [LabelStr,' ',deblank(CurrAtlasEntries{SuggestedEntries(IndSel)})];
            end
        else
            LabelStr = ['ROI ',num2str(IndLocMax),' [',MainData{IndLocMax,1},']'];
        end
        
        %% ask once more if user accepts this string
        answer_str = inputdlg({['ROI ',num2str(IndLocMax),' [',MainData{IndLocMax,1},'] Name: ']},'ROI-name?',1,{deblank(LabelStr)});
        if(~isempty(answer_str))
            KeepPickingNames  = 0; %stop this continue to next local maxima/voxel/atlas entry
            Labels{IndLocMax} = answer_str{1};
        else
            KeepPickingNames = KeepPickingNames+1;
        end
        if(KeepPickingNames>2) %stop it user doesn't want to continue
            error('obviously you want to stop, don''t you?');
        end
    end
    
    %% clean up & next
    clear CurrAtlasEntries LabelStr answer_str
    try
        close(gcf);
    end
end

%% save labels
uisave({'Labels'},['Labels_from_',SuggestedName,'.mat']);

%% Done.
disp(' ');
disp('Done.');

end

%% subfunctions

%% GenerateSphereDisplay(CurrCoord,SphereSize)
function [] = GenerateSphereDisplay(Coord,SphereSize)
% This function generates a NIFTI for display with DisplayClusters.m
% The NIFTI contains a sphere with values 4 in the voxel coordinate and
% value 3 & 2 for the overnext and direct neighbors and 1 around those till a distance of SphereSize-Voxels,
% otherwise the volume contains "0". 
%
% In this way we will see the voxel position and the sphere very clearly.

%% check input
if((size(Coord,2)==3)&&(size(Coord,1)==1)) %switch around to be column vector
    Coord = Coord';
end

%% get template volume 
BaseDir = fileparts(mfilename('fullpath'));
TemplateVol_path = [BaseDir,filesep,'TemplateVol_1mmISO.nii'];
TempVol = spm_vol(TemplateVol_path);

%% transform the Coord to voxel coordinate (round) 
% get transformation matrices
v2m=spm_get_space(TempVol.fname);
m2v=inv(v2m);

% create voxel indices
vox=m2v(1:3,1:3)*Coord + m2v(1:3,4);
vox=round(vox); %for use in array

%% write the sphere
Y = zeros(TempVol.dim);
for Ind3 = max([1;(vox(3)-SphereSize)]):min([(vox(3)+SphereSize);TempVol.dim(3)]) 
    for Ind2 = max([1;(vox(2)-SphereSize)]):min([(vox(2)+SphereSize);TempVol.dim(2)])
        for Ind1 = max([1;(vox(1)-SphereSize)]):min([(vox(1)+SphereSize);TempVol.dim(1)])
            Value = 1; %Default
            if((sqrt((Ind1-vox(1))^2)<(SphereSize/2)) && (sqrt((Ind2-vox(2))^2)<(SphereSize/2)) && (sqrt((Ind3-vox(3))^2)<(SphereSize/2))) %neighbors
                Value = 2;
                if((sqrt((Ind1-vox(1))^2)<=2) && (sqrt((Ind2-vox(2))^2)<=2) && (sqrt((Ind3-vox(3))^2)<=2)) %next neighbors to the center
                    Value = 3;
                    if((sqrt((Ind1-vox(1))^2)<1) || (sqrt((Ind2-vox(2))^2)<1) || (sqrt((Ind3-vox(3))^2)<1)) %the center
                        Value = 4;
                    end
                end
            end
            Y(Ind1,Ind2,Ind3) = Value;
        end
    end
end

%% overwrite the template
TempVol = spm_write_vol(TempVol,Y);
pause(.125); %bug fix

%% display the volume using DisplayClusters.m
DisplayClusters(TempVol.fname);

%% done.
disp('Done with Sphere display.');

end
