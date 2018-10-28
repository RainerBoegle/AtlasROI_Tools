function [InputFileCStr,ConfigFileCStr,Defaults] = Create_IBMwordcloud_InputNConfig(format_type,InputCStr,varargin)
% This function creates the configuration.txt and input.txt file to run the
% IBM WordCloud JAVA Application (jar) such that the desired output is created.
%
% The only mandatory inputs are "format_type" AND "InputCStr".
%
%Mandatory Inputs:
%"InputCStr": <cell-string> {NLinesOfText-x-1} or {NWords-x-3} (with columns 1:Words 2:Weights 3:HexColors)
%    FOR BOTH 'tab'-mode AND 'text'-mode the input words or text should be
%    a cellstring. Either as columnvector or matrix (see below),
%    giving each word or line of text as a row in the cellstring.
%
%"format_type":
% 'text' means that the inputs (for IBM WordCloud) are just raw text and 
% the IBM WordCloudGen does the counting and statistics by itself,
% then arranges the words and displays them.
%
% 'tab' means that the inputs (for IBM WordCloud) are columns separated by
% tabs containing EACH word to display, the weighting for each and the color
% for each word as [r,g,b].
% NB:
%    If words have spaces then they will be regarded as separate words in
%    'text'-mode, e.g. 'Visual Cortex' --> 'Visual' & 'Cortex', but the two
%    words can be kept together if the whitespace is replaced by "~",
%    i.e. 'Visual~Cortex'. In the case of 'tab'-mode, word even with white
%    spaces will always stay together as long as they are in one line, i.e.
%    in a row.
%
%    Weighting is analog to size of words, BUT final size will be determined
%    by IBM WordCloud given the resolution of the graphics and statistics of
%    the weightings.
%    The input to this function for the weighting can be any real number 
%    that Matlab can handle, however the numbers will be shorted to two places 
%    after the decimal point.
%
%    IBM WordCloud need the colors specified in Hex from #000000 to #FFFFFF [RRGGBB from rgb].
%    The input to this function for the colors MUST be Hex-STRINGS! If you
%    have rgb numberic values only then use the CopyClusterColors or rgb2hex functions.
%    Example: CopyClusterColors(repmat([1:3]',1455/3,1),[1 0 0; 0 1 0; 0 0 1],'rgb2hex')];
%
% Example for putting everything together for 'tab'-mode:
%    InputCStr = [WordsCStr,MyM2C(Weights),CopyClusterColors(CluserNumbersPerWord,ColorsRGBperCluster,'rgb2hex')];
%    NB: WordsCStr is a cell-string {NWords-x-1}
%        Weights is a column-vecotr (NWords-x-1) --> MyM2C will make this into a {NWords-x-1} cell
%        CluserNumbersPerWord is also a column-vector (NWords-x-1) containing Indices for ColorsRGBperCluster
%        ColorsRGBperCluster is a (NClusters-x-3) matrix with the colors to be assigned for each cluster by CopyClusterColors-function all in rgb format and will be transformed to a hex-string using rgb2hex function.
%        
%        The resulting InputCStr will be {NWords-x-3} as needed for this function in 'tab'-mode.
%
%
%ADDITIONAL INPUTS:
% Additional Inputs are not needed because IBM_WordCloud_defaults.m function will 
% set them if not given, but can be given in the format "'CommandString',Input".
%
% e.g.
% Create_IBMwordcloud_InputNConfig(format_type,InputCStr,'background','#000000'); %specify background color as black
% Create_IBMwordcloud_InputNConfig(format_type,InputCStr,'background',rgb2hex([0 0 0])); %specify background color as black in [r g b] numeric values and transform using rgb2hex-function.
% 
%
%# Path to a TrueType font: NB: default-paths can be set in the IBM_WordCloud_defaults.m file
%# e.g. windows:
%           'font','c:/windows/fonts/georgiab.ttf'
%
%# e.g. mac:
%           'font','/Library/Fonts/Times New Roman.ttf'
%           'font','/Library/Fonts/Georgia.ttf'
% 
%# for linux, download any TrueType font and point to it
%           'font','/opt/fonts/ttf/quelquechose.ttf'
% 
%# Background color
%# Same result as Default: (Defaults can be set in the IBM_WordCloud_defaults.m file)
%           'background','FFFFFF'
% 
%# Palette ONLY in 'text'-mode!!!
%# Colors are assigned to words by randomly choosing from
%# the provided palette. You can list any number of colors, and
%# you can make a given color more likely
%# than another by listing it more than once.
%#
%# Same result as Default: (Defaults can be set in the IBM_WordCloud_defaults.m file)
%           'palette',['#880099';'#339922';'#993333';'#2266CC']
% 
%# Maximum number of words to show
%#
%# Same result as Default: (Defaults can be set in the IBM_WordCloud_defaults.m file)
%           'maxwords','150'
%# More fun:
%           'maxwords','800'
% 
%# The "placement strategy" to use
%# Possible values:
%#
%#   HorizontalCenterLine
%#   VerticalCenterLine
%#   Alphabetical
%#   AlphabeticalVertical
%#   Center
%#
%# Capitalization and spelling are significant.
%#
%# Same result as Default: (Defaults can be set in the IBM_WordCloud_defaults.m file)
%           'placement','HorizontalCenterLine'
% 
%# The perimeter shape, either BLOBBY or SQUARISH
%#
%# Same result as Default: (Defaults can be set in the IBM_WordCloud_defaults.m file)
%           'shape','SQUARISH'
% 
%# The "orientation strategy" to use.
%# Possible values:
%#
%#	HORIZONTAL
%#	MOSTLY_HORIZONTAL
%#	HALF_AND_HALF
%#	MOSTLY_VERTICAL
%#	VERTICAL
%#	ANY_WHICH_WAY
%#
%# Same result as Default: (Defaults can be set in the IBM_WordCloud_defaults.m file)
%           'orientation','MOSTLY_HORIZONTAL'
% 			
%# Which collection of stopwords (ignored words) to use.
%# One of:
%#
%#	Arabic, Catalan, Czech, Dutch, Danish, English, Esperanto,
%#	Farsi, Finnish, French, German, Greek, Hebrew, Hindi, Hungarian,
%#	Italian, Norwegian, Polish, Portuguese, Romanian, Russian,
%#	Slovenian, Spanish, Swedish, Turkish
%#
%#	See stopwordsfile setting for custom stop words lists.
%#
%# No stopwords used by default.
%#
%# Example: 
%           'stopwords','English'
% 
%# Path to a file containing custom stopwords. 
%# Stopwords should be given one per line in a text file.
%#
%# No stopwords file used by default.
%           'stopwordsfile','examples/hamlet-stopwords.txt'
% 
%# If you use both the "stopwords" and "stopwordsfile" options
%# the the program will load the given stopwords and append
%# your custom list.
% 
%# Whether or not to treat numbers as stopwords
%#
%# true/false
%#
%# Same result as Default: (Defaults can be set in the IBM_WordCloud_defaults.m file)
%           'stripnumbers','false'
%
%
%
%Usage:
%       [InputFileCStr,ConfigFileCStr] = Create_IBMwordcloud_InputNConfig(format_type,InputCStr,varargin);
%       [InputFileCStr,ConfigFileCStr] = Create_IBMwordcloud_InputNConfig(format_type,InputCStr);
%       [InputFileCStr,ConfigFileCStr] = Create_IBMwordcloud_InputNConfig(format_type,InputCStr,'CommandString','AdditionalInput');
%
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(30.January.2015): initial implementation based on test script.

%% init & check inputs
if(nargin<2)
    error('wrong number of inputs!');
else
    if(rem(nargin,2)~=0)
        error('wrong number of inputs!');
    end
end

switch(lower(format_type))
    case {'text','tab'}
        if(nargin==2)
            Defaults = IBM_WordCloud_defaults(lower(format_type));
        else
            [CommandStrings,AdditionalInputs] = SplitAdditionalInputs(varargin(:));
            Defaults = IBM_WordCloud_defaults(lower(format_type),CommandStrings,AdditionalInputs);
        end
    otherwise
        error(['Unknown format_type: "',format_type,'"']);
end

%% make strings for config file
ConfigFileCStr = MakeConfigCStr(Defaults);

%% make strings for input file
InputFileCStr = MakeInputCStr(format_type,InputCStr);

%% Done
disp(' ');
disp('Cellstrings for creation of input.txt & config.txt files have been made.');

end

%% subfunctions
%% [CommandStrings,AdditionalInputs] = SplitAdditionalInputs(varargin(3:end));
function [CommandStrings,AdditionalInputs] = SplitAdditionalInputs(AddInputs)
if(rem(length(AddInputs),2)~=0)
    error('wrong number of ADDITIONAL inputs!'); %should not happen after above check but is here for savety
end

CommandStrings   = cell(length(AddInputs)/2,1);
AdditionalInputs = cell(length(AddInputs)/2,1);

CommandStrings   = AddInputs(1:2:end);
AdditionalInputs = AddInputs(2:2:end);
end

%% ConfigFileCStr = MakeConfigCStr(Defaults)
function ConfigFileCStr = MakeConfigCStr(Defaults)
SNames = fieldnames(Defaults); 
ConfigFileCStr = {};
N = 0;
for loopIndex = 1:length(SNames) 
    ToWrite = Defaults.(SNames{loopIndex});
    if(~isempty(ToWrite))
        ConfigFileCStr{N+1,1} = SNames{loopIndex};
        ConfigFileCStr{N+1,2} = ToWrite;
        N = size(ConfigFileCStr,1);
    end
end

end

%% InputFileCStr = MakeInputCStr(format_type,InputCStr)
function InputFileCStr = MakeInputCStr(format_type,InputCStr)
switch(lower(format_type))
    case 'text'
        if(size(InputCStr,2)~=1&&size(InputCStr,1)==1)
            InputCStr = InputCStr';
        else
            if(size(InputCStr,2)~=1)
                error('For format-type ''text'' "InputCStr" has to be {NWords/Lines-x-1} cellstring!');
            end
        end
        if(iscellstr(InputCStr))
            InputFileCStr = InputCStr;
        else
            error('"InputCStr" has to be a cellstring!');
        end
    case 'tab'
        if(size(InputCStr,2)~=3&&size(InputCStr,1)==3)
            InputCStr = InputCStr';
        else
            if(size(InputCStr,2)~=3)
                error('For format-type ''text'' "InputCStr" has to be {NWords/Lines-x-1} cellstring!');
            end
        end
        if(iscellstr(InputCStr))
            InputFileCStr = InputCStr;
        else
            if(iscellstr(InputCStr(:,1))&&iscellstr(InputCStr(:,3)))
                %change the second one
                Data = cell2mat(InputCStr(:,2));
                if(length(Data(:))~=size(InputCStr,1))
                    error('Conversion error! "InputCStr" probably wrong.');
                end
                if(min(Data(:))<=0)
                    Data = Data(:)-repmat(min(Data(:))-1,length(Data(:)),1);
                end
                OrdMagnMax = log10(max(Data(:)));
                if(OrdMagnMax<0)
                    Data = Data.*10^ceil(abs(OrdMagnMax));
                    OrdMagnMax = ceil(log10(max(Data(:))));
                else
                    OrdMagnMax = ceil(log10(max(Data(:))));
                    if(OrdMagnMax==0)
                        OrdMagnMax = 1;
                    end
                end
                InputFileCStr = cell(size(InputCStr,1),3);
                InputFileCStr(:,1) = InputCStr(:,1);
                InputFileCStr(:,3) = InputCStr(:,3);
                for Ind = 1:length(Data(:))
                    InputFileCStr{Ind,2} = num2str(Data(Ind),['%',num2str(OrdMagnMax),'.2f']);
                end
            else
                error('At least "InputCStr(:,1)" & "InputCStr(:,3)" have to be a cellstrings!');
            end
        end
    otherwise
        error(['Unknown format_type: "',format_type,'"']);
end
end