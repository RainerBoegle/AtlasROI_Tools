function [AllLabels,RawLabelsInds] = split_RawLabels(RawLabels,varargin)
% This is a specialized function that can evaluate the raw labels as they
% come from the atlas and split these into separate labels given the Atlas
% name for choosing the strategy.
%
%Usage:
%       [AllLabels,RawLabelsInds] = split_RawLabels(RawLabels,AtlasName); %evaluate raw labels (a cellstring-vector of labels) with the scheme for atlas stored in "AtlasName" either as cell or string
%       [AllLabels,RawLabelsInds] = split_RawLabels(RawLabels); %User will be asked if the first entry in RawLabels is the atlas name or quit.
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(29.January.2015): initial implementation based on test script.

%% init
AllLabels     = [];
RawLabelsInds = [];

%% check inputs
if(~iscellstr(RawLabels))
    error('"RawLabels" has to be a cellstring!');
else
    if(~isvector(RawLabels))
        error('"RawLabels" has to be a cellstring-vector!');
    end
end

%% check additional inputs
if(nargin==1)
    if(strcmp('Yes',questdlg({'You did not input the Atlas name!'; 'This is necessary to determine the strategy for splitting the labels.'; ' '; 'Is the Atlas name contained in the first entry of "RawLabels"?'; '(i.e. "AtlasName=RawLabels{1};")'},'Atlas name?','Yes','Quit','Yes')))
        AtlasName=RawLabels{1};
        RawLabels_org = RawLabels; clear RawLabels
        RawLabels = RawLabels_org(2:end); %remove atlas label
    else
        return;
    end
else
    if(nargin==2)
        AtlasName = varargin{1};
        if(iscell(AtlasName))
            AtlasName_tmp = AtlasName; clear AtlasName
            AtlasName = AtlasName_tmp{1};
        else
            if(~ischar(AtlasName))
                error('"AtlasName" has to be a cell or char/string!');
            end
        end
    else
        error('wrong number of inputs');
    end
end

%% do the splitting according to atlas name
AtlasDefaults = GetAtlasDefaults(AtlasName);

%% apply atlas defaults to do splitting
[AllLabels,RawLabelsInds] = split_Labels(RawLabels,AtlasDefaults);

%% done
disp(' ');
disp('Done.');

end

%% subfunctions
%% AtlasDefaults = GetAtlasDefaults(AtlasName);
function AtlasDefaults = GetAtlasDefaults(AtlasName)
% Determine the defaults from the atlas name

%% which atlas?
switch(AtlasName)
    case {'Cerebellar Atlas in MNI152 space after normalization with FNIRT','Harvard-Oxford Cortical Structural Atlas','Harvard-Oxford Subcortical Structural Atlas','Juelich Histological Atlas','MNI Structural Atlas'}
        AtlasDefaults.Separator   = ',';
        AtlasDefaults.ReplaceOnly = 0;
    case {'Talairach Daemon Labels'}
        AtlasDefaults.Separator   = [];
        AtlasDefaults.ReplaceOnly = 1; %don't separate; only replace
        AtlasDefaults.RepPat{1}   = '*';
        AtlasDefaults.RepStr{1}   = []; %empty
        AtlasDefaults.RepPat{2}   = '.';
        AtlasDefaults.RepStr{2}   = ' '; %white space
    otherwise
        AtlasDefaults = [];
end

end

%% apply atlas defaults to do splitting
%% AllLabels = split_Labels(RawLabels,AtlasDefaults);
function [AllLabels,RawLabelsInd] = split_Labels(RawLabels,AtlasDefaults)
% use defaults for splitting & then replace ' ' by '~'

%% initial check
if(isempty(AtlasDefaults))
    warning('AtlasDefaults was empty! --> Atlas unknown??? Will use standard separator ",".');
    clear AtlasDefaults
    AtlasDefaults.Separator  = ',';
    AtlasDefaults.ReplaceOnly= 0;
end

%% use defaults for splitting
AllLabels   = {}; %init empty
RawLabelsInd= []; %init empty
for Ind = 1:length(RawLabels)
    N = length(AllLabels); %init
    CurrLabel = RawLabels{Ind}; %current
    
    %% apply AtlasDefautls
    if(AtlasDefaults.ReplaceOnly)
        for IndRep = 1:length(AtlasDefaults.RepPat)
            if(~isempty(CurrLabel))
                try
                    if(~isempty(AtlasDefaults.RepStr{IndRep}))
                        CurrLabel(CurrLabel==AtlasDefaults.RepPat{IndRep}) = AtlasDefaults.RepStr{IndRep};
                    else
                        CurrLabel(CurrLabel==AtlasDefaults.RepPat{IndRep}) = []; %this is really different from an assignment! It is the deletion of memory! THEREFORE we can not "assign" the empty contents here to get the same effect!!! This leads to a different compilation or interpretation at runtime!
                    end
                catch 
                    keyboard;
                end
            end
        end
        CurrLabel = strtrim(CurrLabel);
        if(~isempty(CurrLabel))
            AllLabels{N+1,1} = CurrLabel;
            RawLabelsInd     = [RawLabelsInd; Ind];
        else
            AllLabels{N+1,1} = 'No label found!';
            RawLabelsInd     = [RawLabelsInd; Ind];
        end
    else
        %separate
        StartIndex = 1; %init
        IndexSep = strfind(CurrLabel,AtlasDefaults.Separator);
        if(~isempty(IndexSep))
            for IndSep = 1:length(IndexSep)
                StopIndex = IndexSep(IndSep)-1;
                AllLabels{N+IndSep,1}= strtrim(CurrLabel(StartIndex:StopIndex));
                RawLabelsInd         = [RawLabelsInd; Ind];
                StartIndex = IndexSep(IndSep)+1; %further that current stopindex for the next one
                if(IndSep==length(IndexSep)) %one more left that we should not forget
                    AllLabels{N+IndSep+1,1}= strtrim(CurrLabel(StartIndex:end)); %NSeparators --> N+1 strings.
                    RawLabelsInd           = [RawLabelsInd; Ind];
                end
            end
        else
            %probably one entry only
            AllLabels{N+1,1} = strtrim(CurrLabel);
            RawLabelsInd     = [RawLabelsInd; Ind];
        end
    end
end

%% replace ' ' by '~'
AllLabels = regexprep(AllLabels,' ','~');

end
