function [] = Test_xlWrite(varargin)
%% check input
if(nargin==1)
    deleteOutput = varargin{1};
else
    deleteOutput = 1;
end

%% Small demonstration on how to use XLWRITE
BaseDir = fileparts(mfilename('fullpath'));

%% Initialisation of POI Libs
% Add Java POI Libs to matlab javapath
if((exist('org.apache.poi.ss.usermodel.WorkbookFactory', 'class') ~= 8) || (exist('org.apache.poi.hssf.usermodel.HSSFWorkbook', 'class') ~= 8) || (exist('org.apache.poi.xssf.usermodel.XSSFWorkbook', 'class') ~= 8))
    javaaddpath([BaseDir,filesep,'poi_library/poi-3.8-20120326.jar']);
    javaaddpath([BaseDir,filesep,'poi_library/poi-ooxml-3.8-20120326.jar']);
    javaaddpath([BaseDir,filesep,'poi_library/poi-ooxml-schemas-3.8-20120326.jar']);
    javaaddpath([BaseDir,filesep,'poi_library/xmlbeans-2.3.0.jar']);
    javaaddpath([BaseDir,filesep,'poi_library/dom4j-1.6.1.jar']);
    javaaddpath([BaseDir,filesep,'poi_library/stax-api-1.0.1.jar']);
end

%% Data Generation for XLSX
% Define an xls name
fileName = 'test_xlwrite.xlsx';
sheetName = 'this_is_sheetname';
startRange = 'B3';

% Generate some data
xlsData = {'A Number' 'Boolean Data' 'Empty Cells' 'Strings';...
    1 true [] 'String Text';...
    5 false [] 'Another very descriptive text';...
    -6.26 false 'This should have been an empty cell but I made an error' 'This is text';...
    1e8 true [] 'Last cell with text';...
    1e3 false NaN NaN;...
    1e2 true [] 'test'};

%% Generate XLSX file
try
    disp('Trying to write out XLS-file...');
    [status, message] = xlwrite([BaseDir,filesep,fileName], xlsData, sheetName, startRange);
    disp(['Status ',num2str(status),': ',message]);
catch
    disp('xlwrite failed. Trying again...');
    [status, message] = xlwrite([BaseDir,filesep,fileName], xlsData, sheetName, startRange);
    disp(['Status ',num2str(status),': ',message]);
end
if(exist([BaseDir,filesep,fileName],'file'))
    disp('writing seems successful...');
    if(deleteOutput)
        delete([BaseDir,filesep,fileName]);
    end
else
    disp('xlwrite terminated without error but file can not be found. Strange!!!???');
end

end
