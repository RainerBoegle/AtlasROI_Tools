function [] = init_Results2ROI()

%% get base dir
BaseDir = fileparts(mfilename('fullpath'));

%% add directories
addpath(BaseDir);
addpath([BaseDir,filesep,'ServiceFunctions']);

%% test tools.
disp(' ');
if(strcmp(which('GetParamsFromMap'),[BaseDir,filesep,'ServiceFunctions',filesep,'GetParamsFromMap.m']) && strcmp(which('IterateFindLocMax'),[BaseDir,filesep,'ServiceFunctions',filesep,'IterateFindLocMax.m']))
    disp('Clustering/ROIcreation tools have been added to path and seem available for use.');
else
    disp('Tried to add Clustering/ROIcreation tools but test of availability has failed. Try if it works yourself. :/');
end
disp(' ');

end
