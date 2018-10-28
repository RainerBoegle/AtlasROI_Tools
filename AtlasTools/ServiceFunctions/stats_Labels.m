function [UniqueLabels,OccurrenceUniqueLabels,AdditionalStats] = stats_Labels(AllLabels,AtlasName)
% This function does statistics over the separated labels.
% The Labels get separated from the XX% numbers (if present) and the unique ones are determined. 
% The occurrence of the unique ones is a first statisic and if possible
% we will also calculate the quartiles of the percentages as well.
%
%Usage:
%       [UniqueLabels,OccurrenceUniqueLabels,AdditionalStats] = stats_Labels(AllLabels,AtlasName); %evaluate labels (a cellstring-vector of labels) with the scheme for atlas stored in "AtlasName" either as cell or string
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(29.January.2015): initial implementation based on test script.

%% init
UniqueLabels = [];
OccurrenceUniqueLabels = [];
AdditionalStats = [];

%% check inputs
if(~iscellstr(AllLabels))
    error('"AllLabels" has to be a cellstring!');
else
    if(~isvector(AllLabels))
        error('"AllLabels" has to be a cellstring-vector!');
    end
end

if(iscell(AtlasName))
    AtlasName_tmp = AtlasName; clear AtlasName
    AtlasName = AtlasName_tmp{1};
else
    if(~ischar(AtlasName))
        error('"AtlasName" has to be a cell or char/string!');
    end
end

%% split off the percentages if possible
[NewLabels,DataForAdditionalStats] = split_Percentages(AllLabels,AtlasName);

%% determine unique labels and their occurrence
[UniqueLabels,IndsUnique2NewLabels,IndsNew2UniqueLabels] = unique(NewLabels);
OccurrenceUniqueLabels = zeros(length(UniqueLabels),1);
for IndUniqueLabels = 1:length(UniqueLabels)
    OccurrenceUniqueLabels(IndUniqueLabels) = length(find(IndsNew2UniqueLabels==IndUniqueLabels));
end

%% have a look at the data for additional stats
if(~isempty(DataForAdditionalStats))
    AdditionalStats = zeros(length(UniqueLabels),3); %1stQuartile, Median, 3rdQuartile
    for IndUniqueLabels = 1:length(UniqueLabels)
        CurrData = DataForAdditionalStats(IndsNew2UniqueLabels==IndUniqueLabels);
        CurrData(isnan(CurrData)) = [];
        if(~isempty(CurrData))
            AdditionalStats(IndUniqueLabels,:) = quantile(CurrData(:),[.25, .5, .75]); %1stQuantile, Median, 3rdQuantile
        else
            AdditionalStats(IndUniqueLabels,:) = NaN(3,1); 
        end
    end
end

end

%% subfunctions
%% AtlasDefaults = GetAtlasDefaults(AtlasName);
function AtlasDefaults = GetAtlasDefaults(AtlasName)
% Determine the defaults from the atlas name

%% which atlas?
switch(AtlasName)
    case {'Cerebellar Atlas in MNI152 space after normalization with FNIRT','Harvard-Oxford Cortical Structural Atlas','Harvard-Oxford Subcortical Structural Atlas','Juelich Histological Atlas','MNI Structural Atlas'}
        AtlasDefaults.Separator   = '%';
    case {'Talairach Daemon Labels'}
        AtlasDefaults = [];
    otherwise
        AtlasDefaults = [];
end

end

%%
function [NewLabels,DataForAdditionalStats] = split_Percentages(AllLabels,AtlasName)
%% Get Atlas defaults
AtlasDefaults = GetAtlasDefaults(AtlasName);

if(~isempty(AtlasDefaults))
    %% do the splitting according to atlas name
    NewLabels = strtrim(regexprep(AllLabels,['(\d+)',AtlasDefaults.Separator],''));

    %% try to get additional Data for additional statistics
    DataForAdditionalStats = zeros(length(AllLabels),1);
    TmpTokens = regexp(AllLabels,['(\d+)',AtlasDefaults.Separator],'tokens'); 
    for IndData = 1:length(DataForAdditionalStats)
        CurrTok = checkToken(TmpTokens{IndData});
        if(isempty(CurrTok))
            DataForAdditionalStats(IndData) = NaN;
        else
            try
                DataForAdditionalStats(IndData) = eval(CurrTok);
            catch
                disp(['WARNING! Could not evaluate "',CurrTok,'"!']);
            end
        end
    end
else
    %% NO splitting or additional data for additional stats
    NewLabels = AllLabels;
    DataForAdditionalStats = [];
end

end

%% checkToken
function CurrTok = checkToken(CurrTok)
if(iscell(CurrTok))
    if(length(CurrTok)>1) %too long!
        disp('"CurrTok" has length>1! Will only take first entry!');
        CurrTok_tmp = CurrTok{1}; clear CurrTok
        if(ischar(CurrTok_tmp))
            CurrTok = CurrTok_tmp; clear CurrTok_tmp
        else
            if(iscell(CurrTok_tmp))
                if(~isempty(CurrTok_tmp))
                    disp('"CurrTok_tmp" is still a cell!!!??? Only take first one.');
                    CurrTok = CurrTok_tmp{1}; clear CurrTok_tmp
                else
                    CurrTok = [];
                end
            end
        end
    else %maybe empty or just right
        if(isempty(CurrTok))
            CurrTok = [];
        else %just right
            CurrTok_tmp = CurrTok{1}; clear CurrTok
            if(ischar(CurrTok_tmp))
                CurrTok = CurrTok_tmp; clear CurrTok_tmp
                if(isempty(CurrTok)) %unnecessary but save
                    CurrTok = [];
                end
            else
                if(isempty(CurrTok_tmp)) %unnecessary but save
                    CurrTok = [];
                end
            end
        end
    end
else %not a cell should be a char or empty
    if(~ischar(CurrTok))
        if(~isempty(CurrTok))
            disp(['WARNING: unexpected token for IndData: ',num2str(IndData)]);
            CurrTok
        else
            CurrTok = []; %unnecessary but save
        end
    else %could still be empty char
        if(isempty(CurrTok)) %unnecessary but save
            CurrTok = [];
        end
    end
end

end