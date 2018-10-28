%% make words, weights & colors
if(0)
    Weights      = [     21.4;      13.7;        18;         10;             pi;         3.1416; exp(10^randn(1))];
else
    Weights      = [     21.4;      13.7;        18;         10;             pi;         3.1416; exp(10^randn(1))];
    Weights      = RankValues(Weights);
end
if(0)
    WordsCStr    = {    'Red';   'Green';    'Blue'; 'Magenta?'; 'Yellow?~Gelb'; 'Gelb? Yellow';          'Cyan?'};
else
    WordsCStr    = {    ['Red(',num2str(Weights(1)),')'];   ['Green(',num2str(Weights(2)),')'];    ['Blue(',num2str(Weights(3)),')']; ['Magenta?(',num2str(Weights(4)),')']; ['Yellow?~Gelb(',num2str(Weights(5)),')']; ['Gelb? Yellow(',num2str(Weights(6)),')'];          ['Cyan?(',num2str(Weights(7)),')']};
end
IdNumbersPerWord = [        1;         2;         3;          4;              5;              5;                6];
%ColorHexStr     = {'#FF0000'; '#00FF00'; '#0000FF';  '#FF00FF';      '#FFFF00';      '#FFFF00';    '#00FFFF'};  %instead of using CopyClusterColors colors can be given directly for each word.
ColorsRGBperId   = [1 0 0; 0 1 0; 0 0 1; 1 0 1; 1 1 0; 0 1 1]; %This is just to show that CopyClusterColors can assign M colors given by ColorsRGBperId to the (N-many==no of words) M numbers given by IdNumbersPerWord and transform them to hex-strings . Also possible would be to just give one color per word in hex-string directly, then we would have to name yellow "#FFFF00" twice to get the last two words/lines in yellow.

InputCStr = [WordsCStr,MyM2C(Weights),CopyClusterColors(IdNumbersPerWord,ColorsRGBperId,'rgb2hex')]; %This is just to show how to process data and a color palette for multiple inputs %for tab-mode we need {N-x-3} entries, the words, the weights and colors for the words.

%% create input cellstrings %% In case you are interested in the deeper functions get defaults for tab-mode Defaults = IBM_WordCloud_defaults('tab'); %NB: check out the fields, e.g. Defaults = IBM_WordCloud_defaults('tab','background',rgb2hex([0 0 0])); %will set the background to black (also '#000000' would be a correct input instead of rgb2hex([0 0 0])) instead of default white.
% [InputFileCStr,ConfigFileCStr] = Create_IBMwordcloud_InputNConfig(format_type,InputCStr,'CommandString','AdditionalInput');
if(0)
    [InputFileCStr,ConfigFileCStr,Defaults] = Create_IBMwordcloud_InputNConfig('tab',InputCStr); %NB: [InputFileCStr,ConfigFileCStr] = Create_IBMwordcloud_InputNConfig('tab',InputCStr,'background',rgb2hex([0 0 0])); %will set the background to black (also '#000000' would be a correct input instead of rgb2hex([0 0 0])) instead of default white.
else
    [InputFileCStr,ConfigFileCStr] = Create_IBMwordcloud_InputNConfig('tab',InputCStr,'background',rgb2hex([0 0 0])); 
end

%% write out to txt-file 
ExampleDir = [pwd,filesep,'WordCloudExample'];
[SavePath_InputTXT,SavePath_ConfigTXT] = Write_IBMwordcloudTXT(InputFileCStr,ConfigFileCStr,[ExampleDir,filesep,'ExampleInput.txt'],[ExampleDir,filesep,'ExampleConfig.txt']);

%% run the java -jar 
% [OutputPNG_path,SavePath_InputTXT,SavePath_ConfigTXT,ResolutionString] = RunIBMwordcloudGen(OutputPNG_path,SavePath_InputTXT,SavePath_ConfigTXT,varargin)
[OutputPNG_path,SavePath_InputTXT,SavePath_ConfigTXT,ResStr,status,returnstr] = RunIBMwordcloudGen([ExampleDir,filesep,'ExampleOutputPNG.png'],SavePath_InputTXT,SavePath_ConfigTXT); %NB: [OutputPNG_path,SavePath_InputTXT,SavePath_ConfigTXT,ResolutionString] = RunIBMwordcloudGen(OutputPNG_path,SavePath_InputTXT,SavePath_ConfigTXT,'-w 1600 -h 1200'); %change resolution of png to 1600x1200 pixels instead of default 800x600

%% get the output png for display
[I,map,H] = DisplayWordCloudPNG(OutputPNG_path); %display

%% clean up?
if(exist(OutputPNG_path)) %first make sure it worked.
    if(strcmp('Yes',questdlg('Cleanup all files & directories created in example?','Cleanup?','Yes','No','How dare you!','Yes')))
        delete(SavePath_ConfigTXT);
        delete(SavePath_InputTXT);
        delete(OutputPNG_path);
        rmdir(ExampleDir);
    end
    if(strcmp('Yes',questdlg('Close figure showing the results?','Close figure?','Yes','No','No')))
        close(H);
    end
end
