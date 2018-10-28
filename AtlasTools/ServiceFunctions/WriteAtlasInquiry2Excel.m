function [status,message,FileName,PathName,AtlasQueryOutput]=WriteAtlasInquiry2Excel(AtlasQueryOutput,varargin)
% This function uses xlswrite(Windows) or xlwrite(Linux/Mac) to write out the 
% results from atlas inquiry to an Excel-File. 
% 
%Usage:
%       [status,message,FileName,PathName] = WriteAtlasInquiry2Excel(AtlasQueryOutput);
%       [status,message,FileName,PathName] = WriteAtlasInquiry2Excel(InquireAtlases(AvailableAtlasesFSL,VoxCell));
%       [status,message,FileName,PathName] = WriteAtlasInquiry2Excel(InquireAtlases(getAtlases('select'),VoxCell));  %select atlases to inquire about voxel locations in VoxCell
%       [status,message,FileName,PathName] = WriteAtlasInquiry2Excel(InquireAtlases(getAtlases(),VoxCell));  %use all available atlases to inquire about voxel locations in VoxCell
%       [status,message,FileName,PathName] = WriteAtlasInquiry2Excel(AtlasQueryOutput,SavePath);
%
%V1.2
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(01.February.2015): add save path specification as an extra input. uiputfile sometimes does not open at first try (known issue at mathworks) therefore now we have a retry option.

%% check inputs
if(nargin==2)
    [PathName,FileName,Ext] = fileparts(varargin{1});
    if(~exist(PathName))
        mkdir(PathName);
    end
    FileName = [FileName,Ext];
    PathSelected = 1;
    UseUIputfile = 0;
else
    UseUIputfile = 1;
    [FileName,PathName,PathSelected] = uiputfile('*.xls','Save Atlas-results to XLS-file?',['AtlasInquiryResults_',regexprep(date,'-',''),'.xls']);
    drawnow;
end

%% select folder and filename for saving
if(PathSelected)
    switch(computer)
        case {'PCWIN','PCWIN64'}
            [status,message] = xlswrite([PathName,filesep,FileName], AtlasQueryOutput);
        otherwise
            [status,message] = xlwrite( [PathName,filesep,FileName], AtlasQueryOutput);
    end
    if(status)
        disp(['Writing out query in file "',FileName,'" to "',PathName,'".']);
    else
        disp(['error: "',message,'".']);
    end
else
    if(UseUIputfile) %only do this if uiputfile has been called before (presumably).
        status=0;
        message=['Canceled...'];
        assignin('base','AtlasQueryOutput',AtlasQueryOutput);
        if(strcmp('ReTry',questdlg({'Atlas results have not been saved.'; ' '; 'You can retrieve them from Matlab-Workspace in the variable "AtlasQueryOutput".'; 'You can write them out using the command: "WriteAtlasInquiry2Excel(AtlasQueryOutput);"'; ' '; 'OR you can just retry now.'},'Results NOT saved!','Continue','ReTry','ReTry')))
            WriteAtlasInquiry2Excel(AtlasQueryOutput); %recursive call, but should terminate, either on second try or user can stop it, so I guess it is fine.
        end
    else
        message=[];
        status =0;
    end
end

end