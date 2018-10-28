function [MapExtractStruct] = GetParamsFromMap(MapPath,MaskPath)
% This function can extract the statistic values & coordinates from a statistics map(volume)
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
%       [MapExtractStruct] = GetParamsFromMap(MapPath,MaskPath);
%       [MapExtractStruct] = GetParamsFromMap(); %select manually
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment V1.0: (29.12.2014): initial implementation

%% load map
try
    if(iscellstr(MapPath))
        if(~exist(MapPath{1},'file'))
            MapPath = spm_select(1,'image','Select Statistics-Map for extracting significant values...');
        else
            MapPath_tmp = MapPath; clear MapPath 
            MapPath = MapPath_tmp{1}; clear MapPath_tmp
        end
    else
        if(~exist(MapPath,'file'))
            MapPath = spm_select(1,'image','Select Statistics-Map for extracting significant values...');
        end
    end
catch CATCH_MapPath
    MapPath = spm_select(1,'image','Select Statistics-Map for extracting significant values...');
end
NII_map = nifti(MapPath);
if(length(NII_map.dat.dim)>3)
    Map_Is4D = 1;
    [tmp1,tmp2,ext] = fileparts(MapPath); clear tmp1 tmp2
    Map_4dIndex = eval(ext(find(ext==',')+1:end)); clear ext
else
    Map_Is4D = 0;
    Map_4dIndex = 1; %default
end
V_map   = spm_vol(MapPath);

%% use mask?
try
    if(iscellstr(MaskPath))
        if(~exist(MaskPath{1},'file'))
            MaskPath = spm_select(1,'image','Select Statistics-Map for extracting significant values...');
            UseMask  = 1;
        else
            MaskPath_tmp = MaskPath; clear MaskPath 
            MaskPath = MaskPath_tmp{1}; clear MaskPath_tmp
            UseMask  = 1;
        end
    else
        if(isempty(MaskPath))
            UseMask = 0;
        else
            if(~exist(MaskPath,'file'))
                MaskPath = spm_select(1,'image','Select Statistics-Map for extracting significant values...');
                UseMask  = 1;
            end
        end
    end
catch CATCH_MaskPath
    if(strcmp('Yes',questdlg('Do you want to use a mask?','Masking of data?','Yes','No','No')))
        MaskPath = spm_select(1,'image','Select Statistics-Map for extracting significant values...');
        UseMask = 1;
    else
        UseMask = 0;
    end  
end

if(UseMask)
    CheckDims = 1;
    while(CheckDims)
        NII_mask = nifti(MaskPath);
        V_mask   = spm_vol(MaskPath);
        if(any(V_mask.dim~=V_map.dim)||any(abs(diag(V_mask.mat))~=abs(diag(V_map.mat))))
            h = helpdlg({'Mask & Map dimensions or resolution do not match!'; ' '; 'Select another mask.'},'ERROR: Dimensions OR Resolution');
            uiwait(h);
            MaskPath = spm_select(1,'image','Select Statistics-Map for extracting significant values...');
        else
            CheckDims = 0;
        end
    end
    if(length(NII_mask.dat.dim)>3)
        Mask_Is4D = 1;
        [tmp1,tmp2,ext] = fileparts(MaskPath); clear tmp1 tmp2
        Mask_4dIndex = eval(ext(find(ext==',')+1:end)); clear ext
    else
        Mask_Is4D = 0;
        Mask_4dIndex = 1; %default
    end
    
    if(Mask_Is4D)
        tmp = NII_mask.dat(:,:,:,Mask_4dIndex);
        UniqueMask = unique(tmp(:)); clear tmp
    else
        UniqueMask = unique(NII_mask.dat(:));
    end
    UniqueMask(UniqueMask==1)= [];
    UniqueMask(UniqueMask==0)= [];
    if(~isempty(UniqueMask)) %not 0,1 mask
        if(strcmp('Mask>0',questdlg({'The Mask is not a [0,1]-type.'; 'Do you want to apply a special threshold or just "Mask>0"?'},'Threshold Mask?','Mask>0','Special Threshold','Mask>0')))
            if(Mask_Is4D)
                Mask_dat = (NII_mask.dat(:,:,:,Mask_4dIndex)>0);
            else
                Mask_dat = (NII_mask.dat(:,:,:)>0);
            end
            ThresMask_answer{1} = 'eps'; %MATLAB epsilon %use minimum value
            ThresMask_answer{2} = '[]';
        else
            h=helpdlg('Note that one of the Thresholds can be left out by setting it EMPTY, i.e. to "[]".','Threshold.');
            uiwait(h);
            CheckThres = 1;
            while(CheckThres)
                ThresMask_answer = inputdlg({'Thres1(Mask)= '; 'Thres2(Mask)= '},'Mask thresholds?',1,{'4.6';'-4.6'});
                if(isempty(eval(ThresMask_answer{1}))&&isempty(eval(ThresMask_answer{2})))
                    h=helpdlg('AT LEAST ONE THRESHOLD MUST BE NON-EMPTY, i.e. NOT BOTH "[]".','ERROR: Threshold.');
                    uiwait(h);
                else
                    CheckThres = 0;
                end
            end
            Mask_dat = zeros(V_mask.dim); %init
            for IndThres = 1:length(ThresMask_answer)
                if(~isempty(eval(ThresMask_answer{IndThres})))
                    if(Mask_Is4D)
                        tmp = NII_mask.dat(:,:,:,Mask_4dIndex);
                    else
                        tmp = NII_mask.dat(:,:,:);
                    end
                    Mask_dat((sign(eval(ThresMask_answer{IndThres})).*tmp(:))>=(abs(eval(ThresMask_answer{IndThres})))) = 1; clear tmp
                end
            end
        end
        Mask_dat = (Mask_dat>0);
    else
        if(Mask_Is4D)
            Mask_dat = (NII_mask.dat(:,:,:,Mask_4dIndex)>0);
        else
            Mask_dat = (NII_mask.dat(:,:,:)>0);
        end
    end
    % inclusive or exclusive masking?
    if(strcmp('Exclusive',questdlg({'Should the mask be used "INCLUSIVE", i.e. only data within the mask shall be extracted,'; 'OR '; 'Should the mask be used "EXCLUSIVE", i.e. only data outside of mask shall be extracted?'},'Inclusive OR Exclusive masking?','"INCLUSIVE"','"EXCLUSIVE"','"EXCLUSIVE"')))
        Mask_dat = ~Mask_dat;
    end
else
    ThresMask_answer = [];
    Mask_dat = [];
    V_mask   = [];
end
    
%% set thresholds
if(strcmp('Map>0',questdlg({'Should the map be thresholded specially?'; 'OR just "Map>0"?'},'Threshold Map?','Map>0','Special Threshold','Map>0')))
    if(Map_Is4D)
        MapThresMask_dat= (NII_map.dat(:,:,:,Map_4dIndex)>0);
    else
        MapThresMask_dat= (NII_map.dat(:,:,:)>0);
    end
    ThresMap_answer{1} = 'eps'; %MATLAB epsilon %use minimum value
    ThresMap_answer{2} = '[]';
else
    h=helpdlg('Note that one of the Thresholds can be left out by setting it EMPTY, i.e. to "[]".','Threshold.');
    uiwait(h);
    CheckThres = 1;
    while(CheckThres)
        ThresMap_answer = inputdlg({'Thres1(Map)= '; 'Thres2(Map)= '},'Map thresholds?',1,{'4.6';'-4.6'});
        if(isempty(eval(ThresMap_answer{1}))&&isempty(eval(ThresMap_answer{2})))
            h=helpdlg('AT LEAST ONE THRESHOLD MUST BE NON-EMPTY, i.e. NOT BOTH "[]".','Threshold.');
            uiwait(h);
        else
            CheckThres = 0;
        end
    end
    MapThresMask_dat= zeros(V_map.dim);
    for IndThres = 1:length(ThresMap_answer)
        if(~isempty(eval(ThresMap_answer{IndThres})))
            if(Map_Is4D)
                tmp = NII_map.dat(:,:,:,Map_4dIndex);
            else
                tmp = NII_map.dat(:,:,:);
            end
            MapThresMask_dat((sign(eval(ThresMap_answer{IndThres})).*tmp(:))>=(abs(eval(ThresMap_answer{IndThres})))) = 1; clear tmp
        end
    end
end
if(Map_Is4D)
    Map_dat = NII_map.dat(:,:,:,Map_4dIndex).*MapThresMask_dat;
else
    Map_dat = NII_map.dat(:,:,:).*MapThresMask_dat;
end

%% if mask was assigned, use it
if(~isempty(Mask_dat))
    Map_dat = Map_dat.*Mask_dat;
    %% should masked map be output again?
    if(strcmp('Yes',questdlg('Should the thresholded & masked input statistics map be output as a NIFTI-file?','Output masked-map?','Yes','No','Yes')))
        %% make new volume information
        V_ThresMapOut = V_map;
        if((V_ThresMapOut.dim(1)==size(Map_dat,1))&&(V_ThresMapOut.dim(2)==size(Map_dat,2))&&(V_ThresMapOut.dim(3)==size(Map_dat,3)))
            [FileName,PathName,FilterIndex] = uiputfile('*.nii','Save MASKED Stats-Map?','MASKED_StatsMap.nii');
            if(FilterIndex~=0)
                V_ThresMapOut.fname = [PathName,filesep,FileName];
                
                %% write NIFTI
                if(V_ThresMapOut.dt(1)<16)
                    V_ThresMapOut.dt(1) = 16; %not necessary but save
                end
                if(V_ThresMapOut.n(1)~=1)
                    V_ThresMapOut.n(1) = 1; %3D file has only index 1 as forth nothing else.
                end
                if(Map_Is4D) %if map is 4D originally then we need to remove this information otherwise spm_write_vol will try to write this as 4D
                    V_ThresMapOut = rmfield(V_ThresMapOut,'private');
                end
                V_ThresMapOut = spm_write_vol(V_ThresMapOut,Map_dat);
                
                %% Done.
                [OutDir,OutfName,Outext] = fileparts(V_ThresMapOut.fname);
                disp(' ');
                disp(['Thresholded & Masked Statistics-Map has been written to NIFTI-file "',OutfName,Outext,'".']);
                disp(['In the directory "',OutDir,'".']);
                
            else
                disp('Thresholded & Masked Statistics-Map was NOT saved to NIFTI.');
            end
        else
            disp(['Dimensions error![size(Mask_dat)==(',num2str(size(Map_dat,1)),',',num2str(size(Map_dat,2)),',',num2str(size(Map_dat,3)),')=!=(',num2str(V_ThresMapOut.dim(1)),',',num2str(V_ThresMapOut.dim(2)),',',num2str(V_ThresMapOut.dim(3)),')==V_ThresMapOut.dim] Will skip writing out Thresholded & Masked Statistics-Map']);
        end
    end
else
    %% ask user if the thresholded map should be output
    if(strcmp('Yes',questdlg('Should the thresholded input statistics map be output as a NIFTI-file?','Output thres-map?','Yes','No','Yes')))
        %% make new volume information
        V_ThresMapOut = V_map;
        if((V_ThresMapOut.dim(1)==size(Map_dat,1))&&(V_ThresMapOut.dim(2)==size(Map_dat,2))&&(V_ThresMapOut.dim(3)==size(Map_dat,3)))
            [FileName,PathName,FilterIndex] = uiputfile('*.nii','Save THRESHOLDED Stats-Map?','THRES_StatsMap.nii');
            if(FilterIndex~=0)
                V_ThresMapOut.fname = [PathName,filesep,FileName];
                
                %% write NIFTI
                if(V_ThresMapOut.dt(1)<16)
                    V_ThresMapOut.dt(1) = 16; %not necessary but save
                end
                if(V_ThresMapOut.n(1)~=1) %if map is 4D 
                    V_ThresMapOut.n(1) = 1; %3D file has only index 1 as forth nothing else.
                end
                if(Map_Is4D) %if map is 4D originally then we need to remove this information otherwise spm_write_vol will try to write this as 4D
                    V_ThresMapOut = rmfield(V_ThresMapOut,'private');
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
            disp(['Dimensions error![size(Mask_dat)==(',num2str(size(Map_dat,1)),',',num2str(size(Map_dat,2)),',',num2str(size(Map_dat,3)),')=!=(',num2str(V_ThresMapOut.dim(1)),',',num2str(V_ThresMapOut.dim(2)),',',num2str(V_ThresMapOut.dim(3)),')==V_ThresMapOut.dim] Will skip writing out Thresholded Statistics-Map']);
        end
    end
end

%% for each threshold get what is above sign(threshold).*Map
for IndThres = 1:length(ThresMap_answer)
    if(~isempty(eval(ThresMap_answer{IndThres})))
        %% get linear indices above threshold
        LinIndsThres=find((sign(eval(ThresMap_answer{IndThres})).*Map_dat(:))>=(abs(eval(ThresMap_answer{IndThres}))));
        if(size(LinIndsThres,2)~=1 && size(LinIndsThres,1)==1)
            LinIndsThres = LinIndsThres'; %make sure it is a column vector
        else
            if(size(LinIndsThres,2)~=1)
                error('size(LinIndsThres,2)~=1 && size(LinIndsThres,1)~=1!');
            end
        end
        %% get stats vals
        MapExtractStruct.Voxels(IndThres).StatsVals = Map_dat(LinIndsThres);
        
        %% get voxel-subscript indices
        [I1,I2,I3] = ind2sub(V_map.dim,LinIndsThres);
        MapExtractStruct.Voxels(IndThres).Coords_vox = [I1,I2,I3];
        
        %% make coords in mm from subscript-voxel coordinates using mat
        v2m=spm_get_space(V_map.fname);
        MapExtractStruct.Voxels(IndThres).Coords_mm = zeros(size(MapExtractStruct.Voxels(IndThres).Coords_vox));
        for i=1:size(MapExtractStruct.Voxels(IndThres).Coords_vox,1)
            MapExtractStruct.Voxels(IndThres).Coords_mm(i,1:3)=MapExtractStruct.Voxels(IndThres).Coords_vox(i,:)*v2m(1:3,1:3) + v2m(1:3,4)';
        end
        
        %% apply resorting
        FinalResortingIndices = ZYXresort(MapExtractStruct.Voxels(IndThres).Coords_mm);
        MapExtractStruct.Voxels(IndThres).Coords_mm = MapExtractStruct.Voxels(IndThres).Coords_mm( FinalResortingIndices,:);
        MapExtractStruct.Voxels(IndThres).StatsVals = MapExtractStruct.Voxels(IndThres).StatsVals( FinalResortingIndices);
        MapExtractStruct.Voxels(IndThres).Coords_vox= MapExtractStruct.Voxels(IndThres).Coords_vox(FinalResortingIndices,:);
    else
        MapExtractStruct.Voxels(IndThres).Coords_mm = [];
        MapExtractStruct.Voxels(IndThres).StatsVals = [];
        MapExtractStruct.Voxels(IndThres).Coords_vox= [];
    end
end

%% write remaining info to ouput
%volume info
MapExtractStruct.V_map  = V_map;
MapExtractStruct.V_mask = V_mask;
try
    if(MapExtractStruct.V_map.dt(1)<16)
        MapExtractStruct.V_map.dt(1) = 16; %not necessary but save
    end
    if(MapExtractStruct.V_map.n(1)~=1)
        MapExtractStruct.V_map.n(1) = 1; %3D file has only index 1 as forth nothing else.
    end
    if(Map_Is4D) %if map is 4D originally then we need to remove this information otherwise spm_write_vol will try to write this as 4D
        MapExtractStruct.V_map = rmfield(MapExtractStruct.V_map,'private');
    end
end
try
    if(MapExtractStruct.V_mask.dt(1)<16)
        MapExtractStruct.V_mask.dt(1) = 16; %not necessary but save
    end
    if(MapExtractStruct.V_mask.n(1)~=1)
        MapExtractStruct.V_mask.n(1) = 1; %3D file has only index 1 as forth nothing else.
    end
    if(Mask_Is4D) %if map is 4D originally then we need to remove this information otherwise spm_write_vol will try to write this as 4D
        MapExtractStruct.V_mask = rmfield(MapExtractStruct.V_mask,'private');
    end
end
%thresholds
MapExtractStruct.ThresMap  = ThresMap_answer;
MapExtractStruct.ThresMask = ThresMask_answer;

end