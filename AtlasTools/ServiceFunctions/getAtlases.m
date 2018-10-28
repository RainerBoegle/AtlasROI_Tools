function [AtlasesFSL]=getAtlases(varargin)
% This function collects all Atlases that are available for "atlasquery"
% and return them as a cellstr.
%
% If the option 'select' is added as input, then the user is presented with
% the list of atlases and has to choose which ones to output.
%
%Usage:
%       AtlasesFSL         = getAtlases(varargin);
%       AllAtlasesFSL      = getAtlases();
%       SelectedAtlasesFSL = getAtlases('select');
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(08.December.2014): initial implementation based on test script.

%% atlasquery which atlases are available?
OutFileName = [pwd,filesep,'AvailableAtlesesFSL.txt']; %need a txt file to store the answer of atlasquery such that loading the answer is easy.
CommandFSL  = ['atlasquery --dumpatlases',' >> ',OutFileName]; %command as it should be typed on the command line to use atlasquery
%run atlasquery
[status, result] = system(CommandFSL); %execute the string in "CommandFSL" on the commandline of the system in the current directory
if(status)
    disp(['Warning: ',result]);
end
AvailableAtlasesFSL = importdata(OutFileName); %use importdata to get the answer of atlasquery back as a cell which makes handling easy
delete(OutFileName); %remove this file, such that we don't produce a mess when we use this over and over

%% ask user to choose one or more atlase(s)
if(nargin>0)%if(Nr of inputs)
    switch(varargin{1})%switch(control string)
        case {'select','Select','SELECT'}
            [SelAtlases,ok] = listdlg('ListString',AvailableAtlasesFSL,'ListSize',[500 300],'Name','Atlas Selection','PromptString','Select Atlases for location-query: ','OKString','UseTheseAtlases','CancelString','Quit');
            if(~ok)
                AtlasesFSL = AvailableAtlasesFSL; %take all
            else
                AtlasesFSL = AvailableAtlasesFSL(SelAtlases);
            end
        otherwise
            disp(['UNKNOWN INPUT OPTION: "',varargin{1},'".']);
            disp( 'Will output ALL ATLASES available.');
            AtlasesFSL = AvailableAtlasesFSL; %take all
    end
else
    AtlasesFSL = AvailableAtlasesFSL; %take all
end

end%of getAtlases-function
