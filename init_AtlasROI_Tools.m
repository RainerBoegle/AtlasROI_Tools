function [] = init_AtlasROI_Tools()
%% establish the base dir 
BaseDir = fileparts(mfilename('fullpath'));

%% add the tools
addpath( BaseDir);
addpath([BaseDir,filesep,'AtlasTools']);
addpath([BaseDir,filesep,'Results2ROI']);
addpath([BaseDir,filesep,'IBM_WordCloudTools']);

%% add all functions of Results2ROI
init_Results2ROI;

%% add all functions of AtlasTools
init_AtlasTools;

%% add all functions of IBM WordCloud Tools
try
    disp(' ');
    init_WordCloudTools
    disp('WordCloudTools are available now...');
catch CATCH_WordCloudTools
    disp_catch(CATCH_WordCloudTools,'init_WordCloudTools')
    disp('WordCloudTools are not available!');
end

%% Done.
disp(' ');
disp('-----------------------------------------------------------------------------------------------------------------------------------------------');
disp('Use "SPMTable2Atlas" from the command line to inquire the available atlases given a SPM-Results table.');
disp('OR ');
disp('Use "ClusterStatsMap2Atlas" from the command line to cluster and then inquire the available atlases given a statistics map (z-,t- or F-Vals).');
disp(' ');

end

%% subfunction
%% disp_catch
function [] = disp_catch(CATCHobj,varargin)
if(nargin==2)
    disp(['Error occurred in function "',mfilename,'>',varargin{1},'"...']);
else
    disp(['Error occurred in function "',mfilename,'"...']);
end
disp([CATCHobj.identifier,': ',CATCHobj.message]);

end


