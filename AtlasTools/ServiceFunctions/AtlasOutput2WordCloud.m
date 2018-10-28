function [WordCloudStruct] = AtlasOutput2WordCloud(AtlasQueryOutput,ClusterIDNums,MainDataCols,OutputDir,varargin)
% This function can create a word cloud (using IBM Word Cloud Generator tools)
% from the AtlasOutput cell-matrix.
%
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(02.February.2015 Papa's Birthday! ;)): initial implementation based on test script.

%% init
WordCloudStruct = []; %init empty

%% check inputs
if(~isempty(ClusterIDNums))
    if(length(ClusterIDNums)~=(size(AtlasQueryOutput,1)-1))
        error('AtlasQueryOutput entries are not the same length as ClusterIDNums!');
    else
        IndicateClusterNumsColumn = 0; %probably the right input, don't need to inicate
    end
else
    IndicateClusterNumsColumn = 1;
end
if((min(MainDataCols(:))<1)||(max(MainDataCols(:))>size(AtlasQueryOutput,2)))
    error(['MainDataCols is not a collection of appropriate indices. Must be between 1 and size(AtlasQueryOutput,2)=',num2str(size(AtlasQueryOutput,2)),'for this input. The best selection is usually MainDataCols = 2:(size(AtlasQueryOutput,2)-AdditionalColums); (where AdditionalColums might be zero).']);
end

%% split AtlasQueryOutput
if(IndicateClusterNumsColumn)
    [MainData,AtlasNames,Coords_mm,StatsVals,ClusterIDNums] = split_AtlasOutputs(AtlasQueryOutput,IndicateClusterNumsColumn,'MainDataCols',MainDataCols);
else
    [MainData,AtlasNames,Coords_mm,StatsVals] = split_AtlasOutputs(AtlasQueryOutput,IndicateClusterNumsColumn,'MainDataCols',MainDataCols);
end

%% use Statistics Values as weights or Ranking(Statistics-Values)
ChoiceWeights = questdlg({'Use the statistics values for weighting the atlas entries in the WordCloud, i.e. determine size by statistics values?'; 'OR'; 'Use the ranking of the statistics values to indicate the size? (This will increase the differences even if statistics values are very similar.)'; 'OR'; 'Use the logarithm of the absolute values of the statistics values plus 1? (This will dampen the differences in statistical values.)'; },'Weights?','StatsVals','Ranking(StatsVals)','log(abs(StatsVals)+1)','StatsVals');
switch(ChoiceWeights)
    case 'StatsVals'
        Weights = StatsVals;
    case 'log(abs(StatsVals)+1)'
        Weights = log(abs(StatsVals)+1);
    case 'Ranking(StatsVals)'
        Weights = RankValues(StatsVals,3);
end

%% use colors or create colors?
if(nargin==5)
    ColorsRGBperId = varargin{1};
    if((size(ColorsRGBperId,2)~=3)&&(size(ColorsRGBperId,1)==3))
        ColorsRGBperId = ColorsRGBperId'; %ColorsRGBperId has to be (NColors-x-3)
    elseif((size(ColorsRGBperId,2)~=3)&&(size(ColorsRGBperId,1)~=3))
        error('ColorsRGBperId has the wrong format! Needs to be (NColors-x-3) [r,g,b].');
    end
    if(size(ColorsRGBperId,1)~=max(ClusterIDNums(:)))
        error(['Number of availabe colors (',num2str(size(ColorsRGBperId,1)),') does not fit the number of clusters(',num2str(max(ClusterIDNums(:))),')!']);
    end
else
    %try to make colors as DisplayCluster.m would
    bg = [1 1 1; 0 0 0; .05 .05 .05; .1 .1 .1; .15 .15 .15; .25 .25 .25; .35 .35 .35; .45 .45 .45; .5 .5 .5; .65 .65 .65; .75 .75 .75; .85 .85 .85; .9 .9 .9]; %white black gray(s)
    ColorsRGBperId = distinguishable_colors(max(ClusterIDNums(:)),bg);
end

%% Output directory?
try
    if(isempty(OutputDir))
        OutputDir = [pwd,filesep,'Clusters_',date];
    end
catch
    OutputDir = [pwd,filesep,'Clusters_',date];
end
if(~exist(OutputDir))
    mkdir(OutputDir);
    disp(['Directory "',OutputDir,'" has been created.']);
end

%% split Raw Labels for each Atlas and copy parameters
WordsPerAtlasInquiry        = cell(length(AtlasNames),1);
IndsPerWordsPerAtlasInquiry = cell(length(AtlasNames),1);
ClusterIDNumsPerAtlasInquiry= cell(length(AtlasNames),1);
WeightsPerAtlasInquiry      = cell(length(AtlasNames),1);
for IndAtlas = 1:length(AtlasNames)
    [AllLabels,RawLabelsInds]=split_RawLabels(MainData(:,IndAtlas),AtlasNames{IndAtlas});
    WordsPerAtlasInquiry{IndAtlas}       = AllLabels;
    IndsPerWordsPerAtlasInquiry{IndAtlas}= RawLabelsInds;
    NewWeights      = zeros(length(RawLabelsInds),1);
    NewClusterIDNums= zeros(length(RawLabelsInds),1);
    for IndSubInd = 1:length(RawLabelsInds)
        NewWeights(IndSubInd)      =Weights(RawLabelsInds(IndSubInd));
        NewClusterIDNums(IndSubInd)=ClusterIDNums(RawLabelsInds(IndSubInd));
    end
    ClusterIDNumsPerAtlasInquiry{IndAtlas}= NewClusterIDNums;
    WeightsPerAtlasInquiry{IndAtlas}      = NewWeights;
end

%% create Word Cloud per Atlas
I   = cell(length(AtlasNames),1);
map = cell(length(AtlasNames),1);
H   = cell(length(AtlasNames),1);
OutputPNG_path    = cell(length(AtlasNames),1);
SavePath_InputTXT = cell(length(AtlasNames),1);
SavePath_ConfigTXT= cell(length(AtlasNames),1);
for IndAtlas = 1:length(AtlasNames)
    try
        [InputFileCStr,ConfigFileCStr,Defaults] = Create_IBMwordcloud_InputNConfig('tab',[WordsPerAtlasInquiry{IndAtlas},MyM2C(WeightsPerAtlasInquiry{IndAtlas}),CopyClusterColors(ClusterIDNumsPerAtlasInquiry{IndAtlas},ColorsRGBperId,'rgb2hex')]);
        [SavePath_InputTXT{IndAtlas},SavePath_ConfigTXT{IndAtlas}] = Write_IBMwordcloudTXT(InputFileCStr,ConfigFileCStr,[OutputDir,filesep,'WordCloudInput_',regexprep(regexprep(AtlasNames{IndAtlas},' |-','_'),'&','_'),'.txt'],[OutputDir,filesep,'WordCloudConfig_',regexprep(regexprep(AtlasNames{IndAtlas},' |-','_'),'&','_'),'.txt']);
        [OutputPNG_path{IndAtlas},SavePath_InputTXT{IndAtlas},SavePath_ConfigTXT{IndAtlas},ResStr,status_wordcloud,returnstr] = RunIBMwordcloudGen([OutputDir,filesep,'WordCloudOutput_',regexprep(regexprep(AtlasNames{IndAtlas},' |-','_'),'&','_'),'.png'],SavePath_InputTXT{IndAtlas},SavePath_ConfigTXT{IndAtlas});
        disp(['Status ',num2str(status_wordcloud),': ',returnstr]);
        [I{IndAtlas},map{IndAtlas},H{IndAtlas}] = DisplayWordCloudPNG(OutputPNG_path{IndAtlas},'title',AtlasNames{IndAtlas}); %display
    catch CATCH_wordcloud
        disp_catch(CATCH_wordcloud,'AtlasOutput2WordCloud',['CATCH_wordcloud_',num2str(IndAtlas)])
    end
end

%% collect created data & save
WordCloudStruct.OutputPNG_path     = OutputPNG_path;
WordCloudStruct.SavePath_InputTXT  = SavePath_InputTXT;
WordCloudStruct.SavePath_ConfigTXT = SavePath_ConfigTXT;
WordCloudStruct.ResStr             = ResStr;

WordCloudStruct.PNGs.I   = I;
WordCloudStruct.PNGs.map = map;
WordCloudStruct.PNGs.H   = H;
WordCloudStruct.Titles   = AtlasNames;

WordCloudStruct.AtlasQueryOutput.AtlasQueryOutput     = AtlasQueryOutput;
WordCloudStruct.AtlasQueryOutput.Split.MainData       = MainData;
WordCloudStruct.AtlasQueryOutput.Split.AtlasNames     = AtlasNames;
WordCloudStruct.AtlasQueryOutput.Split.Coords_mm      = Coords_mm;
WordCloudStruct.AtlasQueryOutput.Split.StatsVals      = StatsVals;
WordCloudStruct.AtlasQueryOutput.Split.ClusterIDNums  = ClusterIDNums;
WordCloudStruct.AtlasQueryOutput.Split.ColorsRGBperId = ColorsRGBperId;

save([OutputDir,filesep,'WordCloudStruct.mat'],'WordCloudStruct');

%% Done.
disp(' ');
disp('Done with AtlasOutput2WordCloud');

end

%% subfunction
%% disp_catch
function [] = disp_catch(CATCHobj,varargin)
if(nargin==2)
    disp(['Error occurred in function "',mfilename,'>',varargin{1},'"...']);
else
    disp(['Error occurred in function "',mfilename,'"...']);
end
disp([CATCHobj.identifier,': ',CATCHobj.message]);

if(nargin==3)
    if(ischar(varargin{2}))
        assignin('base',varargin{2},CATCHobj);
    else
        assignin('base',['CATCHobj_',regexprep(datestr(now),' |-|:','_')],CATCHobj);
    end
end

end
