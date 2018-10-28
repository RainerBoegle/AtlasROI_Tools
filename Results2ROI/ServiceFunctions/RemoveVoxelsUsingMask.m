function [Vout] = RemoveVoxelsUsingMask(InputNII_path,MaskNII_path,OutputNII_path)
% This function can be used to remove voxels in the input image, using a mask image. 
% Removal of voxels can be inclusive or exclusive, i.e. remove those inside or outside of mask, respectively.
%
%Usage:
%       [Vout] = RemoveVoxelsUsingMask(InputNII_path,MaskNII_path,OutputNII_path);
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment V1.0: (19.01.2015): initial implementation

%% get input NII including a check if input is4D and treat accordingly
try
    [Input_dat,Vio,Input_fname] = load_InputNII(InputNII_path);
catch CATCH_InputNII_path
    disp_catch(CATCH_InputNII_path)
    [Input_dat,Vio,Input_fname] = load_InputNII([]); %in case InputNII_path is not given
end

%% get mask including a check if input is4D and treat accordingly (should mask be thresholded?)
try
    [Mask_dat,InOrOutsideChoice,Mask_fname] = load_MaskNII(MaskNII_path,Vio);
catch CATCH_MaskNII_path
    disp_catch(CATCH_MaskNII_path);
    [Mask_dat,InOrOutsideChoice,Mask_fname] = load_MaskNII([],Vio); %in case MaskNII_path is not given
end

%% apply removal mask
Input_dat(Mask_dat~=0) = 0;

%% check output path
try
    [OutputNII_path]=CheckOutputNII_path(OutputNII_path,InOrOutsideChoice,Input_fname,Mask_fname);
catch CATCH_OutputNII_path
    disp_catch(CATCH_OutputNII_path)
    [OutputNII_path]=CheckOutputNII_path([],InOrOutsideChoice,Input_fname,Mask_fname); %in case output path is not given
end

%% write out result
Vout       = Vio;
Vout.fname = OutputNII_path;
Vout       = spm_write_vol(Vout,Input_dat);

%% Done.
disp(' ');
disp('Done.');

end


%% subfunctions

%% disp_catch
function [] = disp_catch(CATCHobj,varargin)
if(nargin==2)
    disp(['Error occurred in function "',mfilename,'>',varargin{1},'"...']);
else
    disp(['Error occurred in function "',mfilename,'"...']);
end
disp([CATCHobj.identifier,': ',CATCHobj.message]);

end

%% load InputNII & prepare for output
function [Input_dat,Vio,Input_fname] = load_InputNII(InputNII_path)
%% check input path
try
    if(iscellstr(InputNII_path))
        if(~exist(InputNII_path{1},'file'))
            InputNII_path = spm_select(1,'image','Select Input-NII for removing of voxels via mask...');
        else
            InputNII_path_tmp = InputNII_path; clear InputNII_path 
            InputNII_path = InputNII_path_tmp{1}; clear InputNII_path_tmp
        end
    else
        if(~ischar(InputNII_path))
            InputNII_path = spm_select(1,'image','Select Input-NII for removing of voxels via mask...');
        else
            Index = strfind(InputNII_path,','); %spm format needs to be removed
            if(~isempty(Index)) %spm format needs to be removed
                if(~exist(InputNII_path(1:(Index-1)),'file'))
                    InputNII_path = spm_select(1,'image','Select Input-NII for removing of voxels via mask...');
                end
            else
                if(~exist(InputNII_path,'file'))
                    InputNII_path = spm_select(1,'image','Select Input-NII for removing of voxels via mask...');
                end
            end
            clear Index
        end
    end
catch CATCH_InputNII_path
    disp_catch(CATCH_InputNII_path,'load_InputNII');
    InputNII_path = spm_select(1,'image','Select Input-NII for removing of voxels via mask...');
end
[tmp,Input_fname,ext] = fileparts(InputNII_path); clear tmp ext

%% get NIFTI-object & Volume struct & check if is4D
NII_map = nifti(InputNII_path);
Vio   = spm_vol(InputNII_path);
if(length(NII_map.dat.dim)>3)
    Input_Is4D = 1;
    Input_4dIndex = Vio.n(1);
    Input_dat = NII_map.dat(:,:,:,Input_4dIndex);
else
    Input_Is4D = 0;
    Input_4dIndex = 1; %default
    Input_dat = NII_map.dat(:,:,:);
end

%% get spm-vol structure & prepare for output
if(Input_Is4D) %remove private field and reset n(1)=1; to avoid any 4D issues when outputting a 3D file later
    Vio = rmfield(Vio,'private');%if map is 4D originally then we need to remove this information otherwise spm_write_vol will try to write this as 4D
end
if(Vio.n(1)~=1)
    Vio.n(1) = 1; %3D file has only index 1 as forth nothing else.
end
if(Vio.dt(1)<16)
    Vio.dt(1) = 16; %not necessary but save
end

end

%% mask
function [Mask_dat,InOrOutsideChoice,Mask_fname] = load_MaskNII(MaskNII_path,Vinput)
%% check mask path
try
    if(iscellstr(MaskNII_path))
        if(~exist(MaskNII_path{1},'file'))
            MaskNII_path = spm_select(1,'image','Select MASK for removing voxels...');
        else
            MaskNII_path_tmp = MaskNII_path; clear MaskNII_path 
            MaskNII_path = MaskNII_path_tmp{1}; clear MaskNII_path_tmp
        end
    else
        if(~ischar(MaskNII_path))
            MaskNII_path = spm_select(1,'image','Select MASK for removing voxels...');
        else
            Index = strfind(MaskNII_path,','); %spm format needs to be removed
            if(~isempty(Index)) %spm format needs to be removed
                if(~exist(MaskNII_path(1:(Index-1)),'file'))
                    MaskNII_path = spm_select(1,'image','Select MASK for removing voxels...');
                end
            else
                if(~exist(MaskNII_path,'file'))
                    MaskNII_path = spm_select(1,'image','Select MASK for removing voxels...');
                end
            end
            clear Index
        end
    end
catch CATCH_MaskNII_path
    disp_catch(CATCH_MaskNII_path,'load_MaskNII');
    MaskNII_path = spm_select(1,'image','Select MASK for removing voxels...');
end

%% check dimension and resolution matches Input image
CheckDims = 1;
while(CheckDims)
    NII_mask = nifti(MaskNII_path);
    V_mask   = spm_vol(MaskNII_path);
    if(any(V_mask.dim~=Vinput.dim)||any(abs(diag(V_mask.mat))~=abs(diag(Vinput.mat))))
        h = helpdlg({'Mask & Input dimensions or resolution do not match!'; ' '; 'Select another mask.'},'ERROR: Dimensions OR Resolution');
        uiwait(h);
        MaskNII_path = spm_select(1,'image','Select MASK for removing voxels...');
        if(isempty(MaskNII_path)) %user wants to stop this
            error('MaskNII_path is empty!');
        end
    else
        CheckDims = 0;
    end
end

%% get mask file name 
[tmp,Mask_fname,ext] = fileparts(MaskNII_path);
clear tmp ext

%% check if 4D & if a [0,1] mask
if(length(NII_mask.dat.dim)>3)
    Mask_Is4D = 1;
    Mask_4dIndex = V_mask.n(1); %change!!! use V.n(1)
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
if(strcmp('Exclusive',questdlg({'Should the mask be used "INCLUSIVE", i.e. only data within the mask shall be removed,'; 'OR '; 'Should the mask be used "EXCLUSIVE", i.e. only data outside of mask shall be removed?'},'Inclusive OR Exclusive masking?','"INCLUSIVE"','"EXCLUSIVE"','"EXCLUSIVE"')))
    Mask_dat = ~Mask_dat;
    InOrOutsideChoice = 'Outside';
else
    InOrOutsideChoice = 'Inside';
end


end

%% check output path
function [OutputNII_path]=CheckOutputNII_path(OutputNII_path,InOrOutsideStr,Input_fname,Mask_fname)
%% check basic input type & use user input if unexpected or error occurs
try
    if(iscellstr(OutputNII_path))
        OutputNII_path_tmp = OutputNII_path; clear OutputNII_path
        OutputNII_path = OutputNII_path_tmp{1}; clear OutputNII_path_tmp
    else
        if(~ischar(OutputNII_path))
            FilterIndex = 0;
            while(FilterIndex==0)
                [FileName,PathName,FilterIndex] = uiputfile('*.nii','Enter filename for saving results...',['RemoveVoxels',InOrOutsideStr,Mask_fname,'_from_',Input_fname,'.nii']);
                OutputNII_path = [PathName,filesep,FileName];
            end
        else
            Index = strfind(OutputNII_path,','); %spm format needs to be removed
            if(~isempty(Index))%spm format needs to be removed
                OutputNII_path = OutputNII_path(1:Index-1);
            end
        end
    end
catch CATCH_OutputNII_path
    disp_catch(CATCH_OutputNII_path,'CheckOutputNII_path');
    FilterIndex = 0;
    while(FilterIndex==0)
        [FileName,PathName,FilterIndex] = uiputfile('*.nii','Enter filename for saving results...',['RemoveVoxels',InOrOutsideStr,Mask_fname,'_from_',Input_fname,'.nii']);
        OutputNII_path = [PathName,filesep,FileName];
    end
end

%% check if directory is available
BaseDir = fileparts(OutputNII_path);
if(~exist(BaseDir,'dir'))
    mkdir(BaseDir);
end

end
