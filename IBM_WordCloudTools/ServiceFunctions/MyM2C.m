function CellOut = MyM2C(MatrixIn,varargin)
% This function takes all entries in a matrix (or vector) and puts it into 
% a cell of the same size.
%
% NB: 
%    Test = {zeros(100,2)}; %will create a 1x1 Cell containing a 100x2 matrix of zeros
%
%    Test = MyM2C(zeros(100,2)); %will create a 200x2 Cell containing a ONE zero for each entry.
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(30.January.2015): initial implementation based on test script.

%% init & check inputs
CopyOnly = 0; %don't copy it like repmat but assign
if(nargin==2)
    SizeToBe = varargin{1};
    if(length(MatrixIn)==1)
        MatrixIn = MatrixIn.*ones(SizeToBe);
    else
        CopyOnly = 1;
    end
else
    if(nargin==1)
        SizeToBe = size(MatrixIn);
    else
        error('wrong number of inputs');
    end
end

%% create output empty
CellOut = cell(SizeToBe);

%% use linear indexing on prepared cell to save the reshape step
if(CopyOnly)
    %disp(['Copying inputs to cell of size [',num2str(SizeToBe),']']);
    for Ind = 1:length(CellOut(:))
        CellOut{Ind} = MatrixIn;
    end
else
    for Ind = 1:length(MatrixIn(:))
        CellOut{Ind} = MatrixIn(Ind);
    end
end

end