function [Output_Path,Vo]=CombineClustersVisually(ClusterNII_path)
% This function can be used to combine ROIs/Clusters via selecting the numbers of clusters
% iteratively.
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(21.January.2015): initial implementation based on test script.

%% check inputs
try
    if(iscell(ClusterNII_path))
        ClusterNII_path_tmp = ClusterNII_path; clear ClusterNII_path
        ClusterNII_path = ClusterNII_path_tmp{1}; clear ClusterNII_path_tmp
    else
        if(~ischar(ClusterNII_path))
            ClusterNII_path = spm_select(1,'image','Select Clusters/ROI volume...');
        else
            if(~exist(ClusterNII_path,'file'))
                ClusterNII_path = spm_select(1,'image','Select Clusters/ROI volume...');
            end
        end
    end
catch CATCH_input
    disp_catch(CATCH_input,'check inputs');
    ClusterNII_path = spm_select(1,'image','Select Clusters/ROI volume...');
end

%% get Clusters Volume
Vin = spm_vol(ClusterNII_path);
[BaseDir,fname_in] = fileparts(Vin.fname);
Vo  = Vin; %for final output
Vo.fname = [BaseDir,filesep,'ClustersCombinedVisually_',fname_in,'.nii'];
Vcheck = Vin; %for temporary display
Vcheck.fname = [BaseDir,filesep,'TMPcheck_ClustersCombinedVisually_',fname_in,'.nii'];

NIIin   = nifti(ClusterNII_path);
NII_data= NIIin.dat(:,:,:);

%% save data in inital state for initial display
Vo = spm_write_vol(Vo,NII_data);

%% Combine Areas till user stops combining
%% the idea is to take out all the selected labels and show them once before combining to avoid errors/mistakes
%% if user agrees with combining then we give them their lowest number and after adding all remaining reorder them.
%% continue until user stops combination process
KeepCombining = 1;
while(KeepCombining)
    H_all = DisplayClusters(Vo.fname,Inf); %display initial setting before combine choice and wait for user to continue
    UniqueVals   = unique(NII_data(:)); UniqueVals(UniqueVals==0)=[]; %what is in the volume that is not zero, i.e. a cluster?
    [CombineIndices, KeepCombining] = listdlg('ListString',{num2str(UniqueVals)},'CancelString','Quit','Name','Select Clusters...','PromptString','Select Cluster-Numbers to combine these Clusters...','ListSize',[200 300]);
    if(KeepCombining)
        ClusterInd = min(CombineIndices);
        %% prepare example data for show
        CheckThis_data = zeros(size(NII_data)); %example display data
        for Ind = 1:length(CombineIndices)
            CheckThis_data(NII_data==CombineIndices(Ind)) = Ind;
        end
        Vcheck = spm_write_vol(Vcheck,CheckThis_data);
        pause(0.1); %bug fix
        H_CurrSel = DisplayClusters(Vcheck.fname,1); %% display for user
        pause(0.1); %bug fix
        %% ask user if really combine --> yes combine --> no try again
        if(strcmp('Yes',questdlg('Combine these Clusters to one?','Combine these?','Yes','No','Yes')))
            if(strcmp('Yes',questdlg({'Combine these Clusters with SPATIAL specifics?'; ' '; 'The default is NOT to do so.'},'SPATIAL-SPECIFIC combine?','Yes','No','No'))) %combine special?
                %% get spatial specifics 
                SpatialSpecifics = get_spatial_specifics(Vo,CombineIndices); %from where to where do each of them stay the master cluster, i.e. the others combine with this one?
                %% apply spatial specifics for combination
                for Ind = 1:length(SpatialSpecifics.ClusterIndex)
                    NII_data(CheckThis_data~=0&SpatialSpecifics.CombineMasks{Ind}~=0) = CombineIndices(SpatialSpecifics.ClusterIndex(Ind));
                end
            else
                NII_data(CheckThis_data~=0) = ClusterInd;
            end
            % new ordering
            UniqueVals = unique(NII_data(:)); UniqueVals(UniqueVals==0) = [];
            NII_data_Org = NII_data;
            for Ind = 1:length(UniqueVals)
                NII_data(NII_data_Org==UniqueVals(Ind)) = Ind;
            end
            %write out
            Vo = spm_write_vol(Vo,NII_data);
            pause(0.1); %bug fix
        else
            if(strcmp('Yes',questdlg('Delete these clusters? (Only do so if really small!)','Delete clusters?','Yes','No','No')))
                NII_data(CheckThis_data~=0) = 0;
                % new ordering
                UniqueVals = unique(NII_data(:)); UniqueVals(UniqueVals==0) = [];
                NII_data_Org = NII_data;
                for Ind = 1:length(UniqueVals)
                    NII_data(NII_data_Org==UniqueVals(Ind)) = Ind;
                end
                %write out
                try
                    delete(Vo.fname); %delete version of previous steps
                end
                Vo.fname = [BaseDir,filesep,'ClustersCombinedAndDeletedVisually_',fname_in,'.nii']; %new, more appropriate name
                Vo = spm_write_vol(Vo,NII_data);
                pause(0.1); %bug fix
            end 
            continue;
        end
        %% close windows of last state, but keep main overview if process is stopped.
        try
            close(H_CurrSel);
        end
        try
            close(H_all);
        end
    end
end
Output_Path = Vo.fname;

%% clean up
try
    delete(Vcheck.fname);
end

%% done
disp(' ');
disp('Done.');

end

%% subfunctions

%% get_spatial_specifics
function SpatialSpecifics = get_spatial_specifics(Vol,ClusterIndices) %from where to where do each of them stay the master cluster, i.e. the others combine with this one?
% get spatial specifics    
%% init
SpatialSpecifics.ClusterIndex = [];

%% get min & max for suggested range
v2m=Vol.mat; %voxel to world, i.e. mm-space, matrix
MinMaxXYZ = zeros(3,2);
MinMaxXYZ(:,1) = v2m(1:3,1:3)*[1;1;1]  + v2m(1:3,4);
MinMaxXYZ(:,2) = v2m(1:3,1:3)*Vol.dim' + v2m(1:3,4);
for IndRow = 1:3
    MinMaxXYZ(IndRow,:) = sort(MinMaxXYZ(IndRow,:));
end
defAns = {['[',num2str(MinMaxXYZ(1,1)),' ',num2str(MinMaxXYZ(1,2)),']']; ['[',num2str(MinMaxXYZ(2,1)),' ',num2str(MinMaxXYZ(2,2)),']']; ['[',num2str(MinMaxXYZ(3,1)),' ',num2str(MinMaxXYZ(3,2)),']']};

%world, i.e. mm-space, to voxel matrix
m2v=inv(v2m);

%List of Clusters
StrList = cell(size(ClusterIndices));
for Ind = 1:length(StrList)
    StrList{Ind} = ['Cluster ',num2str(Ind),' (',num2str(ClusterIndices(Ind)),')'];
end

%% ask user for spatial specifics and cluster number for combining region
H = helpdlg({'Combining clusters using SPATIAL-SPECIFICS proceeds'; 'in the following ITERATIVE (2-Step) way.'; ' '; '1.Specify a spatially-specific region giving '; '   [xyzStart_mm xyzEnd_mm]-Coordinates'; '                      and '; '2.Select which cluster number should be assigned in this spatial region,'; '   when combining the clusters selected before.'; ' '; 'Continue with this until satisfied.'; ' '; 'QUIT the process by selecting "cancel" in any of the two steps.'},'Info about spatial specifics');
uiwait(H);
KeepSpecifying = 1; %init
while(KeepSpecifying)
    answer_region  = inputdlg({'x-direction region:';'y-direction region:';'z-direction region:'},'Specify spatial-specific region',1,defAns);
    KeepSpecifying = ~isempty(answer_region);
    if(KeepSpecifying)
        [SelClusterIndex, KeepSpecifying] = listdlg('ListString',StrList,'SelectionMode','single','Name','Cluster Number Selection','PromptString','Select Cluster Number to be assigned:','CancelString','Quit','OKString','Continue');
        if(KeepSpecifying)
            SpatialSpecifics.ClusterIndex = [SpatialSpecifics.ClusterIndex SelClusterIndex];
            SpatialSpecifics.x_region{length(SpatialSpecifics.ClusterIndex),1} = eval(answer_region{1});
            SpatialSpecifics.y_region{length(SpatialSpecifics.ClusterIndex),1} = eval(answer_region{2});
            SpatialSpecifics.z_region{length(SpatialSpecifics.ClusterIndex),1} = eval(answer_region{3});
        end
    end
end

%% assign masks
if(~isempty(SpatialSpecifics.ClusterIndex))
    SpatialSpecifics.CombineMasks = cell(length(SpatialSpecifics.ClusterIndex),1);
    for IndMask = 1:length(SpatialSpecifics.ClusterIndex)
        CoordMinMax = zeros(3,2);
        CoordMinMax(:,1) = [SpatialSpecifics.x_region{IndMask}(1); SpatialSpecifics.y_region{IndMask}(1); SpatialSpecifics.z_region{IndMask}(1)];
        CoordMinMax(:,2) = [SpatialSpecifics.x_region{IndMask}(2); SpatialSpecifics.y_region{IndMask}(2); SpatialSpecifics.z_region{IndMask}(2)];
        VoxMinMax(:,1)   = m2v(1:3,1:3)*CoordMinMax(:,1) + m2v(1:3,4); VoxMinMax(:,1)=round(VoxMinMax(:,1)); %for use in array
        VoxMinMax(:,2)   = m2v(1:3,1:3)*CoordMinMax(:,2) + m2v(1:3,4); VoxMinMax(:,2)=round(VoxMinMax(:,2)); %for use in array
        for IndRow = 1:3
            VoxMinMax(IndRow,:) = sort(VoxMinMax(IndRow,:)); %get the order right
        end
        SpatialSpecifics.CombineMasks{IndMask} = zeros(Vol.dim);
        SpatialSpecifics.CombineMasks{IndMask}(VoxMinMax(1,1):VoxMinMax(1,2),VoxMinMax(2,1):VoxMinMax(2,2),VoxMinMax(3,1):VoxMinMax(3,2)) = 1;
    end
else
    %default to full space for the smallest cluster number 
    disp('No entry in spatial-specific combination! Using default.');
    SpatialSpecifics.ClusterIndex = min(ClusterIndices);
    SpatialSpecifics.CombineMasks = cell(1,1);
    SpatialSpecifics.CombineMasks = ones(Vol.dim);
end

end

%% disp_catch
function [] = disp_catch(CATCHobj,varargin)
if(nargin==2)
    disp(['Error occurred in function "',mfilename,'>',varargin{1},'"...']);
else
    disp(['Error occurred in function "',mfilename,'"...']);
end
disp([CATCHobj.identifier,': ',CATCHobj.message]);

end
