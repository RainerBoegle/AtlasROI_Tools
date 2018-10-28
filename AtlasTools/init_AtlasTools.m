function [] = init_AtlasTools()
%% get base dir
BaseDir = fileparts(mfilename('fullpath'));

%% add directories
addpath(BaseDir);
addpath([BaseDir,filesep,'ServiceFunctions']);
addpath([BaseDir,filesep,'xlwrite_MyVer']);
addpath([BaseDir,filesep,'xlwrite_MyVer',filesep,'poi_library']);

%% test tools.
disp(' ');
if(strcmp(which('InquireAtlases'),[BaseDir,filesep,'ServiceFunctions',filesep,'InquireAtlases.m']) && strcmp(which('xlwrite'),[BaseDir,filesep,'xlwrite_MyVer',filesep,'xlwrite.m']))
    disp('Atlas tools have been added to path and seem available for use.');
else
    disp('Tried to add Atlas tools but test of availability has failed. Try if it works yourself. :/');
end
disp(' ');

%% special test JAVA for XLSx output
ErrorOccurred = 0; %init
try
    disp('Trying to test xlwrite...');
    Test_xlWrite;
catch
    ErrorOccurred = 1;
end
if(ErrorOccurred)
    try
        disp('Trying (again) to test xlwrite...');
        Test_xlWrite;
    catch
        disp(' ');
        disp('WARNING!!!');
        disp('Type "Test_xlWrite;" on the commandline to check if XLS-file writing will not work at all.');
        disp('Sorry for that.');
    end
end

end