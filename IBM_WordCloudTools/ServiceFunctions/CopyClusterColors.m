function CellOut = CopyClusterColors(ClusterNumbers,PossibleColors,varargin)
% This function copies the colors in "PossibleColors" (NClusterx3) [r,g,b]
% to each corresponding cluster number that is listed as a column-vector in
% "ClusterNumbers" (Mx1).
%
%Usage:
%       CellOutput = CopyClusterColors(repmat([1:3]',12,1),[1 0 0; 0 1 0; 0 0 1]);
%       CellOutput = CopyClusterColors(ClusterNumbers,PossibleColors,'rgb2hex'); %change rgb values to hexadecimal strings e.g. #FF00FF is magenta generated from [1 0 1].
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(30.January.2015): initial implementation based on test script.

%% init & check inputs
if((size(ClusterNumbers,2)~=1) && (size(ClusterNumbers,1)==1))
    ClusterNumbers = ClusterNumbers';
elseif((size(ClusterNumbers,2)~=1) && (size(ClusterNumbers,1)~=1))
    error('"ClusterNumbers" must be a (column-)vector!');
end 
CellOut = cell(length(ClusterNumbers),1);

if(size(PossibleColors,2)~=3)
    error('"PossibleColors" must be a Nx3 matrix!');
end
if(min(ClusterNumbers(:))<=0)
    error('"ClusterNumbers" must be greater zero! i.e. indices!');
elseif(max(ClusterNumbers(:))>size(PossibleColors,1))
    error('Indices listed in "ClusterNumbers" can not be greater than "size(PossibleColors,1)"! i.e. must fit the first dimension of possible colors which should be (NClustersx3) [r,g,b]');
end

%% additional inputs?
if(nargin==2)
    SpecialTreatment = 'No';
elseif(nargin==3)
    SpecialTreatment = varargin{1};
    if(iscell(SpecialTreatment))
        SpecialTreatment_tmp = SpecialTreatment{1}; clear SpecialTreatment
        SpecialTreatment = SpecialTreatment_tmp; clear SpecialTreatment_tmp
    end
    if(~ischar(SpecialTreatment))
        error('Additional input for special treatment should be a char or string!');    
    end
else
    error('Wrong number of inputs!');
end
switch(lower(SpecialTreatment))
    case 'rgb2hex'
        Use_rgb2hex = 1;
    otherwise
        Use_rgb2hex = 0;
end

%% copy
if(Use_rgb2hex)
    disp('Changing colors to hex format');
    for Ind = 1:length(CellOut)
        CellOut{Ind} = rgb2hex(PossibleColors(ClusterNumbers(Ind),:));
    end
else
    for Ind = 1:length(CellOut)
        CellOut{Ind} = PossibleColors(ClusterNumbers(Ind),:);
    end
end


