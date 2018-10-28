function Defaults = IBM_WordCloud_defaults(format_type,varargin)
% This function contains the defaults for the IBM WordCloud generator
%
%
%Usage:
%       Defaults = IBM_WordCloud_defaults(format_type,varargin);
%       Defaults = IBM_WordCloud_defaults(format_type,CommandStrings,AdditionalInputs);
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(30.January.2015): initial implementation based on test script.

%% assign according to format type if dependent on it

%# Configuration files must be encoded as UTF-8 (therefore, ASCII is fine).

%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
%# The following properties are MANDATORY %#
%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#

%# Path to a TrueType font:
switch(computer)
    case {'PCWIN64','PCWIN32','PCWIN'}
        %# e.g. windows:
        Defaults.font = 'c:/windows/fonts/georgiab.ttf';
    case {'MACI64','MAC'}
        %# e.g. mac:
        %# font= /Library/Fonts/Times New Roman.ttf
        %# font= /Library/Fonts/Georgia.ttf
        Defaults.font = '/Library/Fonts/Times New Roman.ttf';
    case {'GLNXA64','GLNXA32','GLNXA'}
        %# for linux, download any TrueType font and point to it
        %# font= /opt/fonts/ttf/quelquechose.ttf
        Defaults.font = '/opt/fonts/ttf/quelquechose.ttf';
        if(~exist(Defaults.font))
            Defaults.font = '/usr/share/fonts/truetype/DejaVuSerif-Bold.ttf';
        end
end
if(~exist(Defaults.font))
   Defaults.font = spm_select(1,'.ttf','Select true type font...');
end
     
%# The structure of the input text.
%#
%# Possible values are:
%#
%#	text
%#	tab
%#
%# "text" means unstructured text. The program will count words and
%#		size the words in proportion to their frequencies.
%# "tab" means tab-separated values, and requires further configuration
%#		settings, below.
%#
try
    Defaults.format= format_type;
catch
    Defaults.format= questdlg({'Please select the format-type.'; 'Either "text" or "tab".'; ' '; '"text" means unstructured text. The program will count words and size the words in proportion to their frequencies.'; '"tab" means tab-separated values, allowing the user to determine which words to display and how large. This requires further configuration settings, which will be filled in.'},'Which format type?','tab','text','Quit','tab');
    if(~isempty(Defaults.format))
        if(strcmp(Defaults.format,'Quit'))
            Defaults = [];
            return; %Quit
        else
            format_type = Defaults.format;
        end
    else
        Defaults = [];
        return; %Quit
    end
end

%# The encoding of the input text.
%#
%# Possible values are:
%#
%#	US-ASCII
%#	ISO-8859-1
%#	UTF-8
%#	UTF-16BE
%#	UTF-16LE
%#	UTF-16
%#
Defaults.inputencoding= 'UTF-8';

%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
%# The following properties are MANDATORY for tab files          %#
%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#

%# How to treat the first line of structured data.
%#
%# Possible values:
%#	data
%#	skip
%#	headings
%#
%# "data" means that the first line in the file is data. This
%#		setting cause the "column" configuration options to
%#		be understood as numeric indices, starting at 1.
%# "skip" means throw away the first line, and look for numeric
%#		indices in the "column" config options, as with "data".
%# "headings" means that the first line contains column headings.
%#		The "column" config options will be interpreted as the
%#		text of the data headings.
%#
%# Ignored for input type "text".

%# example
Defaults.firstline= 'data';

%# How to interpret the structured data.

%# Which column contains the "word"?
%#
%# For firstline values of "data" and "skip", this should be a
%# column number, where the first column is column 1. For
%# "heading", this should be the value of the heading for
%# column containing the word or phrase to be rendered in the cloud.

%# example numeric index
Defaults.wordcolumn= '1';

%# examples with headings:
%# wordcolumn: firstname
%# wordcolumn: Heading With Spaces

%# Which column contains the weight?
%#
%# For firstline values of "data" and "skip", this should be a
%# column number, where the first column is column 1. For
%# "heading", this should be the value of the heading for
%# column containing the weight of the given word or phrase.
%# The weight determines the word's relative size.

%# example
Defaults.weightcolumn= '2';

%# Which column contains the color? (OPTIONAL)
%#
%# You can provide your own color per word.
%# Colors should be in the format
%#    RRGGBB
%# or
%#    #RRGGBB
%# or
%#    0xRRGGBB
%# where RR, GG, and BB are hexadecimal numbers
%# between 00 and FF.
%#
%# For firstline values of "data" and "skip", this should be a
%# column number, where the first column is column 1. For
%# "heading", this should be the value of the heading for
%# column containing the color of the given word or phrase.
%#
%# If this configuration is given, then palette settings (below)
%# will be ignored.

%# example
Defaults.colorcolumn= '3';


%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
%# The following properties are OPTIONAL  %#
%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#

%# Case folding -- send everything to upper or lower case
%#
%# Possible values: Upper, Lower
%#
%# Default: no case folding
%#
%# Example:
%#
Defaults.casefold= ''; %'Lower';


%# Background color
%#
%# Colors should be specified as in the colorcolumn setting, above.
%# 
%# Default:
Defaults.background= '#FFFFFF'; %white

%# Palette
%#
%# Colors should be specified as in the colorcolumn setting, above.
%#
%# Colors are assigned to words by randomly choosing from
%# the provided palette. You can list any number of colors, and
%# you can make a given color more likely
%# than another by listing it more than once.
%#
%# Default:
Defaults.palette= ['#880099, #339922, #993333, #2266CC, #FF0000, #00FF00, #0000FF'];

%# Maximum number of words to show
%#
%# Default:
%# maxwords: 150
%# More fun:
Defaults.maxwords= '800';

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
%# Default:
Defaults.placement= 'HorizontalCenterLine';

%# The perimeter shape, either BLOBBY or SQUARISH
%#
%# Default:
Defaults.shape= 'SQUARISH';

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
%# Default:
Defaults.orientation= 'MOSTLY_HORIZONTAL'; %'HALF_AND_HALF';
			
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
Defaults.stopwords= 'English';

%# Path to a file containing custom stopwords. 
%# Stopwords should be given one per line in a text file.
%#
%# No stopwords file used by default.
%# For the hamlet example, we might wish to remove the names that
%# indicate the speaker
Defaults.stopwordsfile= ''; %better set it empty

%# If you use both the "stopwords" and "stopwordsfile" options
%# the the program will load the given stopwords and append
%# your custom list.

%# Encoding of stopwords file, when using custom stopwords.
%#
%# Default:
Defaults.stopwordsencoding= 'UTF-8';

%# Whether or not to treat numbers as stopwords
%#
%# true/false
%#
%# Default:
Defaults.stripnumbers= 'false'; %don't remove numbers!

%% check additional inputs
if(nargin>1)
    if(nargin==3)
        if(iscellstr(varargin{1}))
            CommandStrings   = varargin{1};
            AdditionalInputs = varargin{2};
        else
            [CommandStrings,AdditionalInputs] = SplitAdditionalInputs(varargin(:));
        end
    else
        [CommandStrings,AdditionalInputs] = SplitAdditionalInputs(varargin(:));
    end
    for Ind = 1:length(CommandStrings)
        Defaults = CheckAddInputs(Defaults,CommandStrings{Ind},AdditionalInputs{Ind});
    end
end

%% reset those parts that are forbidden by format_type to empty (if necessary or not) as a safety.
switch(format_type)
    case 'tab'
        Defaults.palette           = ''; %unused in 'tab'-mode
        Defaults.stopwords         = ''; %unused in 'tab'-mode
        Defaults.stopwordsfile     = ''; %unused in 'tab'-mode  
        Defaults.stopwordsencoding = ''; %unused in 'tab'-mode
        Defaults.stripnumbers      = ''; %unused in 'tab'-mode
end

% Idea: use dynamic access to structure to read out the defaults!!!
end


%% subfunctions
%% [CommandStrings,AdditionalInputs] = SplitAdditionalInputs(varargin(:));
function [CommandStrings,AdditionalInputs] = SplitAdditionalInputs(AddInputs)
if(rem(length(AddInputs),2)~=0)
    error('wrong number of ADDITIONAL inputs!'); %should not happen after above check but is here for savety
end

CommandStrings   = cell(length(AddInputs)/2,1);
AdditionalInputs = cell(length(AddInputs)/2,1);

CommandStrings   = AddInputs(1:2:end);
AdditionalInputs = AddInputs(2:2:end);
end

%% Defaults = CheckAddInputs(Defaults,CommandStrings{Ind},AdditionalInputs{Ind});
function Defaults = CheckAddInputs(Defaults,CommandStrings,AdditionalInputs)
%% do the checks
if(~ischar(AdditionalInputs))
    error('"AdditionalInputs" has to be a char or string! i.e. ''CommandString'',''AdditionalInputs''');
end
switch(CommandStrings)
    case 'font'
        Defaults.font = AdditionalInputs;
    case 'inputencoding'
        switch(AdditionalInputs)
            case {'US-ASCII', 'ISO-8859-1', 'UTF-8', 'UTF-16BE', 'UTF-16LE', 'UTF-16'}
                Defaults.inputencoding = AdditionalInputs;%UTF-8
            otherwise
                disp(['inputencoding: "',AdditionalInputs,'" unkown! Spelling? Will default to "UTF-8".']);
                Defaults.inputencoding = 'UTF-8';
        end
    case 'firstline'
        switch(AdditionalInputs)
            case {'data', 'skip', 'headings'}
                Defaults.firstline = AdditionalInputs;%data
            otherwise
                disp(['firstline: "',AdditionalInputs,'" unkown! Spelling? Will default to "data".']);
                Defaults.inputencoding = 'data';
        end
    case 'wordcolumn'
        if(~strcmp(strtrim(AdditionalInputs),'1'))
            disp(['wordcolumn input "',AdditionalInputs,'" is not "1" as expected. But never mind, I trust that you know what you are doing. Do not blame me later! ;)']);
        end
        Defaults.wordcolumn = AdditionalInputs;%1
    case 'weightcolumn'
        if(~strcmp(strtrim(AdditionalInputs),'2'))
            disp(['weightcolumn input "',AdditionalInputs,'" is not "2" as expected. But never mind, I trust that you know what you are doing. Do not blame me later! ;)']);
        end
        Defaults.weightcolumn = AdditionalInputs;%2
    case 'colorcolumn'
        if(~strcmp(strtrim(AdditionalInputs),'3'))
            disp(['colorcolumn input "',AdditionalInputs,'" is not "3" as expected. But never mind, I trust that you know what you are doing. Do not blame me later! ;)']);
        end
        Defaults.colorcolumn = AdditionalInputs;%3
    case 'casefold'
        switch(AdditionalInputs)
            case {'Upper', 'Lower'}
                Defaults.casefold = AdditionalInputs;%Lower
            otherwise
                disp(['casefold: "',AdditionalInputs,'" unkown! Spelling? Will skip this.']);
                Defaults.casefold  = [];%don't use
        end
    case 'background'
        if(ischar(AdditionalInputs))
            Defaults.background  = AdditionalInputs;%#FFFFFF
        else
            Defaults.background  = rgb2hex(AdditionalInputs);%assume it is a [r,g,b] vector. Def:#FFFFFF
        end
    case 'palette'
        if((size(AdditionalInputs,2)==7||size(AdditionalInputs,2)==6)&&(size(AdditionalInputs,1)~=1)) %needs reshaping
            Input = [];
            for Ind = 1:size(AdditionalInputs,1)
                Input = [Input,AdditionalInputs(Ind,:)];
                if(Ind<size(AdditionalInputs,1))
                    Input = [Input,', '];
                end
            end
            Defaults.palette = Input;
        else
            if((size(AdditionalInputs,1)==1)&&(size(AdditionalInputs,2)~=1)) %probably a one line collection
                if(~isempty(strfind(AdditionalInputs,',')))
                    Defaults.palette  = AdditionalInputs;%['#880099, #339922, #993333, #2266CC'] or so
                else
                    if(length(strfind(AdditionalInputs,'#'))>1) %should be separated
                        Defaults.palette  = regexprep(AdditionalInputs,'#',', #');
                        if(strcmp(Defaults.palette(1),','))
                           Defaults.palette = strtrim(Defaults.palette(2:end));
                        end
                    end
                end
            end
        end                        
    case 'maxwords'
        Defaults.maxwords  = AdditionalInputs;%800
    case 'placement'
        switch(AdditionalInputs)
            case {'HorizontalCenterLine','VerticalCenterLine','Alphabetical','AlphabeticalVertical','Center'}
                Defaults.placement  = AdditionalInputs;%HorizontalCenterLine
            otherwise
                error(['placement-type "',AdditionalInputs,'" unkown! (Capitalization and spelling are significant.)']);
        end
    case 'shape'
        switch(AdditionalInputs)
            case {'BLOBBY','SQUARISH'}
                Defaults.shape  = AdditionalInputs;%SQUARISH
            otherwise
                error(['shape-type "',AdditionalInputs,'" unkown! (Capitalization and spelling are significant.)']);
        end
    case 'orientation'
        switch(AdditionalInputs)
            case {'HORIZONTAL','MOSTLY_HORIZONTAL','HALF_AND_HALF','MOSTLY_VERTICAL','VERTICAL','ANY_WHICH_WAY'}
                Defaults.orientation  = AdditionalInputs;%MOSTLY_HORIZONTAL
            otherwise
                error(['orientation-type "',AdditionalInputs,'" unkown! (Capitalization and spelling are significant.)']);
        end
    case 'stopwords'
        switch(AdditionalInputs)
            case {'Arabic', 'Catalan', 'Czech', 'Dutch', 'Danish', 'English', 'Esperanto','Farsi', 'Finnish', 'French', 'German', 'Greek', 'Hebrew', 'Hindi', 'Hungarian', 'Italian', 'Norwegian', 'Polish', 'Portuguese', 'Romanian', 'Russian', 'Slovenian', 'Spanish', 'Swedish', 'Turkish'}
                Defaults.stopwords  = AdditionalInputs;%English
            otherwise
                error(['stopwords-type "',AdditionalInputs,'" unkown! (Capitalization and spelling are significant.)']);
        end    
    case 'stopwordsfile'
        if(~exist(AdditionalInputs))
            disp('Can NOT find "stopwordsfile"! Will skip this.');
            Defaults.stopwordsfile  = '';
        else
            Defaults.stopwordsfile  = AdditionalInputs;%examples/hamlet-stopwords.txt
        end
    case 'stopwordsencoding'
        switch(AdditionalInputs)
            case {'US-ASCII', 'ISO-8859-1', 'UTF-8', 'UTF-16BE', 'UTF-16LE', 'UTF-16'}
                Defaults.stopwordsencoding = AdditionalInputs;%UTF-8
            otherwise
                disp(['stopwordsencoding: "',AdditionalInputs,'" unkown! Spelling? Will default to "UTF-8".']);
                Defaults.stopwordsencoding = 'UTF-8';
        end
    case 'stripnumbers'
        switch(AdditionalInputs)
            case {'true','false'}
                Defaults.stripnumbers  = AdditionalInputs;%true
            otherwise
                disp(['stripnumbers-type "',AdditionalInputs,'" unkown! Spelling? Will default to "false".']);
                Defaults.stripnumbers  = 'false';
        end
    otherwise
        error(['Unknown CommandStrings: "',CommandStrings,'"']);
end
end