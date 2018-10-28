function [OutputPNG_path,SavePath_InputForWordCloud,SavePath_ConfigForWordCloud,ResolutionString,status,answer] = RunIBMwordcloudGen(OutputPNG_path,SavePath_InputForWordCloud,SavePath_ConfigForWordCloud,varargin)
% This function runs the IBM word cloud generator from matlab.
%
% NB: none of the paths or filenames can have white-spaces or "&" included,
%     otherwise matlab has problems executing the command.
%     If you do have these in the paths then the command will fail!
%
%Usage:
%       [OutputPNG_path,SavePath_InputForWordCloud,SavePath_ConfigForWordCloud,ResolutionString] = RunIBMwordcloudGen(OutputPNG_path,SavePath_InputForWordCloud,SavePath_ConfigForWordCloud,varargin);
%       [OutputPNG_path,SavePath_InputForWordCloud,SavePath_ConfigForWordCloud,ResolutionString] = RunIBMwordcloudGen(OutputPNG_path,SavePath_InputForWordCloud,SavePath_ConfigForWordCloud); %save with resolution '-w 800 -h 600'
%       [OutputPNG_path,SavePath_InputForWordCloud,SavePath_ConfigForWordCloud,ResolutionString] = RunIBMwordcloudGen(OutputPNG_path,SavePath_InputForWordCloud,SavePath_ConfigForWordCloud,'-w 1600 -h 1200'); %save with resolution '-w 1600 -h 1200'
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(29.January.2015): initial implementation based on test script.

%% check inputs
%% Output path
[OutputDir,OutputFName,OutputExt] = fileparts(regexprep(regexprep(OutputPNG_path,' ','_'),'&','_'));
if(~strcmpi(OutputExt,'.png'))
    OutputExt = '.png';
end
if(~isempty(OutputDir))
    if(~exist(OutputDir))
        mkdir(OutputDir);
    end
    OutputPNG_path = [OutputDir,filesep,OutputFName,OutputExt];
else
    OutputPNG_path = [OutputFName,OutputExt];
end
disp('OutputPNG_path: ');
disp(OutputPNG_path);

%% Input path
[InputForWordCloudDir, InputForWordCloudFName, InputForWordCloudExt]  = fileparts(regexprep(regexprep(SavePath_InputForWordCloud,' ','_'),'&','_'));
if(~strcmpi(InputForWordCloudExt,'.txt'))
    InputForWordCloudExt = '.txt';
end
CopyTheInputs=0; %init
if(~isempty(strfind(SavePath_InputForWordCloud,' ')))
    CopyTheInputs = 1;
else
    
end
if(~isempty(strfind(SavePath_InputForWordCloud,'&')))
    CopyTheInputs = 1;
end
if(CopyTheInputs)
    copyfile(SavePath_InputForWordCloud,[InputForWordCloudDir,filesep,InputForWordCloudFName,InputForWordCloudExt]);
    SavePath_InputForWordCloud = [InputForWordCloudDir,filesep,InputForWordCloudFName,InputForWordCloudExt]; %replace
end
disp('SavePath_InputForWordCloud: ');
disp(SavePath_InputForWordCloud);

%% Config path
[ConfigForWordCloudDir,ConfigForWordCloudFName,ConfigForWordCloudExt] = fileparts(regexprep(regexprep(SavePath_ConfigForWordCloud,' ','_'),'&','_'));
if(~strcmpi(ConfigForWordCloudExt,'.txt'))
    ConfigForWordCloudExt = '.txt';
end
CopyTheConfigs=0; %init
if(~isempty(strfind(SavePath_ConfigForWordCloud,' ')))
    CopyTheConfigs = 1;
end
if(~isempty(strfind(SavePath_ConfigForWordCloud,'&')))
    CopyTheConfigs = 1;
end
if(CopyTheConfigs)
    copyfile(SavePath_ConfigForWordCloud,[ConfigForWordCloudDir,filesep,ConfigForWordCloudFName,ConfigForWordCloudExt]);
    SavePath_ConfigForWordCloud = [ConfigForWordCloudDir,filesep,ConfigForWordCloudFName,ConfigForWordCloudExt]; %replace
end
disp('SavePath_ConfigForWordCloud: ');
disp(SavePath_ConfigForWordCloud);

%% check additional inputs
if(nargin==3)
    ResolutionString = '-w 800 -h 600';
else
    if(nargin==4)
        ResolutionString = varargin{1};
    else
        error('wrong number of inputs!');
    end
end
disp(['ResolutionString: ',ResolutionString]);

%% assemble command string
JarDir = [fileparts(mfilename('fullpath')),filesep,'IBMjar'];
[status,answer] = system(['java -jar ',JarDir,filesep,'ibm-word-cloud.jar -c ',SavePath_ConfigForWordCloud,' ',ResolutionString,' < ',SavePath_InputForWordCloud,' > ',OutputPNG_path]);

%% status & answer
disp(['Status ',num2str(status),': ',answer]);
% %% open graphic if successful
% if(~status) %return 0 is successful
%     [I,map] = imread(OutputPNG_path,'png');
%     figure(); imshow(I,map); title(OutputPNG_path);
% end

end
