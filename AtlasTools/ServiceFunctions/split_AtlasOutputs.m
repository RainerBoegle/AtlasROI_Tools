function [MainData,AtlasNames,Coords_mm,StatsVals,ClusterNums] = split_AtlasOutputs(AtlasOutput,varargin)
%This function can split the cell-Matrix AtlasOutput in its subparts.
%
%The main data, i.e. the entries from the atlases.
%The atlas names, i.e. the atlases that were used.
%The coordinates in XYZmm-space as (NVoxelsx3) double-vector
%The statistics values as (NVoxelx1) double-vector
%AND
%The cluster numbers (if present) as (NVoxelsx1) double-vector 
%(although integer would be sufficient, but let's make conversion easy by using standard.)
%
%Usage:
%       [MainData,AtlasNames,Coords_mm,StatsVals,ClusterNums] = split_AtlasOutputs(AtlasOutput,IndicateClusterNums); %IndicateClusterNums is either "0" or "1", if Cluster number or not present or if they are, respectively.
%       [MainData,AtlasNames,Coords_mm,StatsVals,ClusterNums] = split_AtlasOutputs(AtlasOutput,IndicateClusterNums,'MainDataCols',ColNums); %automatically select the data %IndicateClusterNums is either "0" or "1", if Cluster number or not present or if they are, respectively.
%       [MainData,AtlasNames,Coords_mm,StatsVals,ClusterNums] = split_AtlasOutputs(AtlasOutput); %like IndicateClusterNums=0; --> cluster nums are not in "AtlasOutput" --> ClusterNums will be empty!
%
%
%V1.5
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(31.January.2015): get stats vals as well; initial implementation based on test script.

%% init
MainData   = [];
AtlasNames = [];
Coords_mm  = [];
StatsVals  = [];
ClusterNums= [];

%% check additional inputs
if(nargin==2)
    IndicateClusterNums = varargin{1};
    MainDataCols = [];
else
    if(nargin==1)
        IndicateClusterNums = 0;
        MainDataCols = [];
    else
        if(nargin==4)
            IndicateClusterNums = varargin{1};
            CommandStr          = varargin{2};
            switch(CommandStr)
                case 'MainDataCols'
                    CommandValues       = varargin{3}; %MainDataCols = CommandValues;
                    MainDataCols        = CommandValues;
                otherwise
                    error(['Unknown command string "',CommandStr,'".']);
            end
        else
            error('Wrong number of inputs!');
        end
    end
end

%% check inputs
if(~isempty(strfind(lower(AtlasOutput{1,1}),'coord'))&&strcmp(class(eval(['[',AtlasOutput{2,1},']',])),'double'))
    if(~isempty(strfind(lower(AtlasOutput{1,2}),'statsvals'))&&strcmp(class(eval(['[',AtlasOutput{2,2},']',])),'double'))
        IndicateStats    = 0;
        IndicateHeadings = 0;
        IndicateCoords   = 0;
        if(isempty(MainDataCols))
            IndicateMainData = [0,1]; %rows,columns
            InfoTxt = {'Please indicate which columns contain the outputs from the atlases,'; 'i.e. the main data.'};
        else
            IndicateMainData = [0,0]; %rows,columns
            InfoTxt = {}; %empty --> will be suppressed later.
        end
    else
        IndicateStats    = 1;
        IndicateHeadings = 0;
        IndicateCoords   = 0;
        IndicateMainData = [0,1]; %rows,columns
        
        InfoTxt = {'Please indicate which columns contain the outputs from the atlases,'; 'i.e. the main data.'; ' '; 'And indicate which column contains the statistics values.'};
    end
    
else
    IndicateStats       = 1;
    IndicateHeadings    = 1;
    IndicateCoords      = 1;
    IndicateMainData    = [1,1]; %rows,columns
    
    InfoTxt = {'Please indicate which row contains the headings'; 'and'; 'which rows and columns contain the outputs from the atlases,'; 'i.e. the main data.'; 'also indicate which column (if present) contains the xyzmm-coordinates and the statistics values.'};
end
if(IndicateClusterNums)
    InfoTxt{end+1} = ' ';
    InfoTxt{end+1} = 'ALSO: Indicate the column containing the cluster numbers.';
end

%% inform user and ask for rows and columns as necessary
if(~isempty(InfoTxt))
    h = helpdlg(InfoTxt,'Indicate data in atlasoutput');
    uiwait(h);
end

prompt = {};
defAns = {};
if(IndicateHeadings)
    prompt{end+1} = 'Row containing HEADINGS: ';
    defAns{end+1} = '1';
    IndicateHeadings = length(prompt);
else
    HeadingsRow = 1;
end
if(IndicateCoords)
    prompt{end+1} = 'Column containing XYZmm-COORDINATES: ';
    defAns{end+1} = '1';
    IndicateCoords = length(prompt);
else
    CoordsCol   = 1;
    try
        NVoxels     = size(AtlasOutput,1)-HeadingsRow;
    catch
        NVoxels     = size(AtlasOutput,1)-1;
    end
end
if(IndicateStats)
    prompt{end+1} = 'Column containing STATISTICS-VALUES: ';
    defAns{end+1} = '2';
    IndicateStats = length(prompt);
else
    StatsCol   = 2;
end
    
if(all(IndicateMainData==1))
    prompt{end+1} = 'Start & End of ROWS containing MAIN-DATA, i.e. atlas entries: ';
    defAns{end+1} = '2:end';
    IndicateMainData(1) = length(prompt);
    
    if(IndicateClusterNums)
        prompt{end+1} = 'Start & End of COLUMNS containing MAIN-DATA, i.e. atlas entries: ';
        defAns{end+1} = '3:(end-1)';
        IndicateMainData(2) = length(prompt);
    else
        prompt{end+1} = 'Start & End of COLUMNS containing MAIN-DATA, i.e. atlas entries: ';
        defAns{end+1} = '3:end';
        IndicateMainData(2) = length(prompt);
    end
elseif(IndicateMainData(2)==1)
    IndicateMainData(1) = 0; %redundancy for safety
    MainDataRows = 2:size(AtlasOutput,1);
    
    if(IndicateClusterNums)
        prompt{end+1} = 'Start & End of COLUMNS containing MAIN-DATA, i.e. atlas entries: ';
        defAns{end+1} = '3:(end-1)';
        IndicateMainData(2) = length(prompt);
    else
        prompt{end+1} = 'Start & End of COLUMNS containing MAIN-DATA, i.e. atlas entries: ';
        defAns{end+1} = '3:end';
        IndicateMainData(2) = length(prompt);
    end
end
if(IndicateClusterNums)
    prompt{end+1} = 'Column containing CLUSTER-NUMBERS: ';
    defAns{end+1} = 'end';
    IndicateClusterNums = length(prompt);
end

%% ask user
if(~isempty(prompt))
    answer = inputdlg(prompt,'Indicate Data parts',1,defAns);
end

%% evaluate the answer
if(IndicateHeadings~=0)
    try
        HeadingsRow = eval(answer{IndicateHeadings});
    catch
        disp('error HeadingsRow = eval(answer)!!! -catch-> HeadingsRow = 1;');
        HeadingsRow = 1;
    end
end
if(IndicateCoords~=0)
    try
        CoordsCol = eval(answer{IndicateCoords});
    catch
        disp('error CoordsCol = eval(answer)!!! -catch-> CoordsCol = 1;');
        CoordsCol = 1;
    end
    NVoxels   = size(AtlasOutput,1)-HeadingsRow;
end
if(IndicateStats~=0)
    try
        StatsCol = eval(answer{IndicateStats});
    catch
        disp('error StatsCol = eval(answer)!!! -catch-> StatsCol = 2;');
        StatsCol = 2;
    end
    NVoxels   = size(AtlasOutput,1)-HeadingsRow;
end
if(all(IndicateMainData~=0))
    try
        MainDataRows = eval(regexprep(answer{IndicateMainData(1)},'end',num2str(size(AtlasOutput,1))));
    catch
        disp(['error MainDataRows = eval(answer)!!! -catch-> MainDataRows = ',num2str(HeadingsRow+1),':',num2str(size(AtlasOutput,1)),';']);
        MainDataRows = (HeadingsRow+1):size(AtlasOutput,1);
    end
    try
        MainDataCols = eval(regexprep(answer{IndicateMainData(2)},'end',num2str(size(AtlasOutput,2))));
    catch
        disp(['error MainDataCols = eval(answer)!!! -catch-> MainDataCols = ',num2str(StatsCol+1),':',num2str(size(AtlasOutput,2)),';']);
        MainDataCols = (StatsCol+1):size(AtlasOutput,2);
    end
elseif(IndicateMainData(2)~=0)    
    MainDataRows = (HeadingsRow+1):size(AtlasOutput,1);
    try
        MainDataCols = eval(regexprep(answer{IndicateMainData(2)},'end',num2str(size(AtlasOutput,2))));
    catch
        disp(['errorb MainDataCols = eval(answer)!!! -catch-> MainDataCols = ',num2str(StatsCol+1),':',num2str(size(AtlasOutput,2)),';']);
        MainDataCols = (StatsCol+1):size(AtlasOutput,2);
    end
elseif(all(IndicateMainData==0))
    MainDataRows = (HeadingsRow+1):size(AtlasOutput,1);
    MainDataCols = CommandValues; %redundancy
else
    disp(['error MainDataRows = eval(answer)!!! -catch-> MainDataRows = ',num2str(HeadingsRow+1),':',num2str(size(AtlasOutput,1)),';']);
    MainDataRows = (HeadingsRow+1):size(AtlasOutput,1);
    
    disp(['error MainDataCols = eval(answer)!!! -catch-> MainDataCols = ',num2str(StatsCol+1),':',num2str(size(AtlasOutput,2)),';']);
    MainDataCols = (StatsCol+1):size(AtlasOutput,2);
end
if(IndicateClusterNums~=0)
    ClusterNumsCol = eval(regexprep(answer{IndicateClusterNums},'end',num2str(size(AtlasOutput,2))));
    if(~isempty(ClusterNumsCol))
        MainDataCols(MainDataCols==ClusterNumsCol) = []; %remove the one that corresponds to the cluster numbers
    end
else
    ClusterNumsCol = []; %assign empty
end


%% get splits
if(NVoxels>0)
    %MAIN DATA, i.e. atlas entries
    MainData   = AtlasOutput(MainDataRows,MainDataCols);
    
    %ATLAS NAMES
    AtlasNames = AtlasOutput(HeadingsRow, MainDataCols);
    
    %XYZmm-space COORDINATES
    Coords_mm = zeros(NVoxels,3);
    for Ind = 1:NVoxels
        Coords_mm(Ind,:) = eval(['[',AtlasOutput{HeadingsRow+Ind,CoordsCol},']',]);
    end
    
    %STATISTICS-values
    StatsVals = zeros(NVoxels,1);
    for Ind = 1:NVoxels
        StatsVals(Ind) = eval(['[',AtlasOutput{HeadingsRow+Ind,StatsCol},']',]);
    end    
    
    %CLUSTER NUMBERS (if present)
    if(~isempty(ClusterNumsCol))
        ClusterNums = zeros(NVoxels,1);
        for Ind = 1:NVoxels
            try
                Tmp = eval(['[',AtlasOutput{HeadingsRow+Ind,ClusterNumsCol},']',]);
                if(length(Tmp)~=1)
                    ClusterNums(Ind) = Tmp(1);
                    disp(['length(ClusterNums{',num2str(Ind),'})= ',num2str(length(Tmp)),'=!=1. Assigning first entry.']);
                else
                    ClusterNums(Ind) = Tmp;
                end
                if((rem(ClusterNums(Ind),1)~=0)&&(ClusterNums(Ind)~=0))
                    disp(['ClusterNums(',num2str(Ind),')= ',num2str(ClusterNums(Ind)),', NOT INTEGER --> ClusterNums(',num2str(Ind),')= round(ClusterNums(',num2str(Ind),'))= ',num2str(round(ClusterNums(Ind)))]);
                    ClusterNums(Ind) = round(ClusterNums(Ind));
                end
            catch
                ClusterNums(Ind) = NaN; %error unknown
                disp(['eval error ClusterNums(',num2str(Ind),') -catch-> assigning "NaN".']);
            end
        end
    else
        ClusterNums = [];
    end
else
    error(['no voxels in AtlasOutput? (size(AtlasOutput)=',num2str(size(AtlasOutput)),')']);
end

%% do some checks
if(size(MainData,1)~=NVoxels)
    error(['size(MainData,1)=',num2str(size(MainData,1)),'=!=',num2str(NVoxels),'=NVoxels']);
else
    %% NB: in case when we update the Atlas Inquiry to include other information, we have to acknowledge this, so in preparation, I will only output warnings here.
    if(~isempty(ClusterNums))
        if(size(AtlasOutput,2)~=(size(MainData,2)+2)) %size(MainData,1)+the coordinates column should be the whole in this case where we don't have the Cluster Numbers
            warning(['AtlasOutput2ClusterLabels>split_AtlasOutputs  size(AtlasOutput,2)=',num2str(size(AtlasOutput,2)),'=!=',num2str(size(MainData,2)+2),'=size(MainData,2)+2(ie the CoordsCol & StatsCol) [NO ClusterNums Column]']);
        end
    else
        if(size(AtlasOutput,2)~=(size(MainData,2)+3)) %size(MainData,1)+the coordinates column + the Cluster Numbers column
            warning(['AtlasOutput2ClusterLabels>split_AtlasOutputs  size(AtlasOutput,2)=',num2str(size(AtlasOutput,2)),'=!=',num2str(size(MainData,2)+3),'=size(MainData,2)+3(ie the CoordsCol, StatsCol & ClusterNums-Column)']);
        end
    end
end

%% DONE.
disp(' ');
disp('Done splitting AtlasOutput.');

end