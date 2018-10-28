function [I,map,H] = DisplayWordCloudPNG(OutputPNG_path,varargin)
% This function can display or get the PNGs created by IBM WordCloud Gen.
%
%Usage
%       [I,map]   = DisplayWordCloudPNG(OutputPNG_path);       %Display png & return data in matlab format
%       [I,map]   = DisplayWordCloudPNG(OutputPNG_path,'get'); %DO NOT Display png AND ONLY return data in matlab format
%       [I,map]   = DisplayWordCloudPNG(OutputPNG_path,'title','Title of display'); %Display png & use the 'Title of display' as title + return data in matlab format
%       [I,map,H] = DisplayWordCloudPNG(OutputPNG_path);       %Display png AND return the handle of the figure that is opened & return data in matlab format
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(01.February.2015): initial implementation based on test script.

%% check inputs
if(nargin==1)
    ShowFig = 1;
    [OutputPNG_dir,OutputPNG_fname,ext] = fileparts(OutputPNG_path);
    Title   = {[OutputPNG_fname,ext]; ['at "',OutputPNG_path,'"']};
else
    if((nargin<=3)&&(nargin~=0))
        switch(lower(varargin{1}))
            case 'get'
                ShowFig = 0;
                Title   = [];
            case 'title' %enable easy suppression
                ShowFig = 1;
                Title   = [];
                if(nargin==3)
                   Title= varargin{2};
                end
            otherwise
                disp(['Unknown input command "',varargin{1},'"? Using DEFAULTS!']); 
                ShowFig = 1;
                [OutputPNG_dir,OutputPNG_fname,ext] = fileparts(OutputPNG_path);
                Title   = {[OutputPNG_fname,ext]; ['at "',OutputPNG_path,'"']};
        end
    else
        error('wrong number of inputs');
    end
end
            
%% get & display if wanted                
[I,map] = imread(OutputPNG_path,'png');
if(ShowFig)
    H = figure(); imshow(I,map); title(Title);
else
    H = [];
end

end
