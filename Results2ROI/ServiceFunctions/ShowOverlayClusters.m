function [H,colors,bg,OutputPath] = ShowOverlayClusters(ClusterNr_vox,Coords_vox,TemplateVol,SavePath)
% This function produces a NIFTI from the clustering results, 
% displays the clusters as an overlay and cleans up afterwards.
%
%Usage:
%      [H,colors,bg,OutputPath] = ShowOverlayClusters(ClusterNr_vox,Coords_vox,TemplateVol,SavePath);
%      [H,colors,bg,OutputPath] = ShowOverlayClusters(ClusterNr_vox,Coords_vox,TemplateVol); %save in current directory
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment V1.0: (27.12.2014): initial implementation (changed version from test script)

%% check inputs
try %SavePath
    [SaveDir,SaveFName,ext] = fileparts(SavePath);
    if(~exist(SaveDir,'dir'))
        mkdir(SaveDir);
    end
    if(isempty(ext))
        ext = '.nii';
    end
    if(isempty(SaveFName))
        SaveFName = ['Clusters_',date];
    end
    while(exist([SaveDir,filesep,SaveFName,ext],'file'))
        SaveFName = [SaveFName,'+'];
    end
    SavePath = [SaveDir,filesep,SaveFName,ext];
catch CATCH_SavePath
    SaveDir   = pwd;
    SaveFName = ['Clusters_',date];
    ext       = '.nii';
    while(exist([SaveDir,filesep,SaveFName,ext],'file'))
        SaveFName = [SaveFName,'_'];
    end
    SavePath = [SaveDir,filesep,SaveFName,ext];
end


%% write out clusters as NIFTI
[OutputPath] = LocMaxClusters2NIFTI(ClusterNr_vox,Coords_vox,TemplateVol,SavePath);

%% display
[H,colors,bg] = DisplayClusters(OutputPath,Inf); %display the colors indefinitely

%% cleanup
if(strcmp('Yes',questdlg('Clean up files produced, i.e. delete NIFTI, now?','Clean up','Yes','No','How dare you!','Yes')))
    delete(OutputPath);
end

end
    