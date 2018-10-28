function [] = init_WordCloudTools()
%setup paths but first check if they will allow the system command to
%finish correctly.

TestIndices = []; %init empty
TestIndices = [TestIndices; strfind([fileparts(mfilename('fullpath')),filesep,'ServiceFunctions',filesep,'IBMjar'],' ')];
TestIndices = [TestIndices; strfind([fileparts(mfilename('fullpath')),filesep,'ServiceFunctions',filesep,'IBMjar'],'&')];
if(isempty(TestIndices)) %no instance of whitespace or "&" --> probalby gonna work 
    addpath( fileparts(mfilename('fullpath')));
    addpath([fileparts(mfilename('fullpath')),filesep,'ServiceFunctions']);
    addpath([fileparts(mfilename('fullpath')),filesep,'ServiceFunctions',filesep,'IBMjar']);
else
    error(['The path: "',fileparts(mfilename('fullpath')),filesep,'ServiceFunctions',filesep,'IBMjar" will not work! Try to remove any whitespaces and "&" from the path (if present) and try again.']);
end

end