function [forwardRank,reverseRank,precision,x] = RankValues(x,varargin)
% This function outputs the ranks of the input vector x
%
%Usage:
%       [forwardRank,reverseRank] = RankOfVals(x,varargin);
%       [forwardRank,reverseRank] = RankOfVals(x);           %rank values
%       [forwardRank,reverseRank] = RankOfVals(x,precision); %rank values but first round them to precision-many decimal places
%
%Example:
%           x = [21.4; 13.7;  18;  10;  pi;  3.1416;  0];
%           [forwardRank, reverseRank]  = RankOfVals(x);
%           [forwardRank2,reverseRank2] = RankOfVals(x,5);
%
%Results in:
% forwardRank = [  7;     5;   6;   4;   2;       3;  1]; %each one is different
% forwardRank2= [  6;     4;   5;   3;   2;       2;  1]; %because of the rounding at the precision of 5 digits we get rank 2 twice.
% reverseRank = [  1;     3;   2;   4;   6;       5;  7];
% reverseRank2= [  1;     3;   2;   4;   5;       5;  6];
%
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(01.February.2015): initial implementation based on test script.

%% check inputs
if(nargin==2)
    precision = round(varargin{1});
    for IndCol = 1:size(x,2)
        x(:,IndCol) = str2num(num2str(x(:,IndCol),precision));
    end
else
    precision = Inf;
end

forwardRank = zeros(size(x));
reverseRank = zeros(size(x));
for IndCol = 1:size(x,2)
    [tmp1, tmp2, forwardRank(:,IndCol)] = unique(x(:,IndCol)); clear tmp1 tmp2 %allow older versions of matlab to run without error
    reverseRank(:,IndCol) = max(forwardRank(:,IndCol)) - forwardRank(:,IndCol)  + 1;
end

end